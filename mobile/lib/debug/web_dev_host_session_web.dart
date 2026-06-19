import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../db/app_database.dart';
import '../db/db_reset.dart';
import '../prefs/app_preferences.dart';
import '../relay/identity_keystore.dart';
import 'web_dev_db_snapshot.dart';
import 'web_dev_db_write_observer.dart' show
    devHostSessionSaveDeferDepth,
    suppressDevHostSessionWriteObserver,
    waitForDevHostDriftTransactionsIdle;
import 'web_dev_profile_recovery.dart';

/// Must match the Flutter web origin host (localhost vs 127.0.0.1) or the
/// browser blocks cross-origin fetches to the dev session server.
const _sessionUrlDefine = String.fromEnvironment(
  'WEB_DEV_SESSION_URL',
  defaultValue: 'http://localhost:18765',
);

Timer? _saveDebounce;
bool _saveInFlight = false;

/// Wipes browser OPFS, housing mirrors, prefs, and relay test identity once
/// when [delete:web-dev-session] scheduled a one-shot wipe on the dev server.
Future<void> wipeWebDevBrowserStorageOnLaunchIfRequested({
  required bool clearRelayIdentity,
}) async {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;
  if (!await _consumeBrowserWipePending()) return;

  debugPrint(
    'web_dev_wipe: clearing browser storage after delete:web-dev-session',
  );

  final prefs = await AppPreferences.load();
  await prefs.resetOnboardingAndPreferences();
  if (clearRelayIdentity) {
    await IdentityKeystore.secureStorage().deleteForTesting();
  }
  await DbReset.deleteLocalDbFiles(prefs: prefs);
}

/// Restores prefs, identity, and Drift tables from the host dev session file.
Future<void> restoreDevSessionFromHostIfNeeded(AppDatabase db) async {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;

  debugPrint('web_dev_host_session: restore check url=$_sessionUrlDefine');

  final raw = await _fetchHostSession();
  if (raw == null) {
    debugPrint('web_dev_host_session: no host backup to restore');
    return;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    if (decoded['version'] is! int ||
        (decoded['version'] as int) < 2 ||
        (decoded['version'] as int) > kWebDevHostSessionVersion) {
      debugPrint(
        'web_dev_host_session: unsupported version ${decoded['version']} '
        '(expected 2..$kWebDevHostSessionVersion)',
      );
      return;
    }

    final prefsMap = decoded['prefs'];
    if (prefsMap is! Map<String, dynamic>) return;
    if (prefsMap['onboarding.complete'] != true) {
      debugPrint('web_dev_host_session: host file has no completed onboarding');
      return;
    }

    final tables = decoded['tables'];
    if (tables is! Map<String, dynamic>) return;

    suppressDevHostSessionWriteObserver = true;
    try {
      final prefs = await AppPreferences.load();
      await prefs.importDevHostSnapshot(prefsMap);
      await importDriftTablesSnapshot(db, tables);

      final identityB64 = decoded['identityPrivateKeyB64'];
      if (identityB64 is String && identityB64.isNotEmpty) {
        await IdentityKeystore.secureStorage().restorePrivateKeyB64ForDev(
          identityB64,
        );
      }

      await reconcileDevProfileFromDriftIfNeeded(db, prefs);

      await db.syncWebStorageToDisk();

      final counts = await countDevHostDriftTables(db);
      debugPrint(
        'web_dev_host_session: restored from host '
        'onboardingComplete=${prefs.onboardingComplete} '
        'profile=${prefs.displayName.isEmpty ? '(empty)' : prefs.displayName} '
        'tables=$counts',
      );
    } finally {
      suppressDevHostSessionWriteObserver = false;
    }
  } catch (error, stack) {
    suppressDevHostSessionWriteObserver = false;
    debugPrint('web_dev_host_session: restore failed: $error\n$stack');
  }
}

/// Immediate push (e.g. right after onboarding completes).
Future<void> saveDevHostSessionNow(AppDatabase db) async {
  if (!kDebugMode) return;
  await _pushHostSessionSnapshot(db);
}

/// Runs [action] without debounced snapshot exports; flushes once at the end.
///
/// Used by housing proposal send flows so Drift web is idle before export.
Future<T> runWithDeferredDevHostSessionSave<T>(
  AppDatabase db,
  Future<T> Function() action,
) async {
  if (!kDebugMode || _sessionUrlDefine.isEmpty) {
    return action();
  }

  devHostSessionSaveDeferDepth++;
  _saveDebounce?.cancel();
  _saveDebounce = null;
  try {
    return await action();
  } finally {
    devHostSessionSaveDeferDepth--;
    if (devHostSessionSaveDeferDepth == 0) {
      await waitForDevHostDriftTransactionsIdle();
      // Drift's web remote executor needs a tick after commit before reads.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await db.syncWebStorageToDisk();
      await flushDevHostSessionSave(db);
    }
  }
}

/// Debounced push to the host session server (survives Ctrl+C on Flutter web).
void scheduleDevHostSessionSave(AppDatabase db) {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;
  if (devHostSessionSaveDeferDepth > 0) return;

  _saveDebounce?.cancel();
  _saveDebounce = Timer(const Duration(milliseconds: 500), () {
    unawaited(_pushHostSessionSnapshot(db));
  });
}

/// Immediate push — used on tab hide / before unload so Ctrl+C does not drop data.
Future<void> flushDevHostSessionSave(AppDatabase db) async {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;

  _saveDebounce?.cancel();
  _saveDebounce = null;

  while (_saveInFlight) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  await _pushHostSessionSnapshot(db);
}

Future<void> _pushHostSessionSnapshot(AppDatabase db) async {
  while (_saveInFlight) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  _saveInFlight = true;
  try {
    final prefs = await AppPreferences.load();
    if (!prefs.onboardingComplete) return;

    final payload = await _buildHostSnapshotWithRetry(db, prefs);
    final response = await http
        .put(
          Uri.parse(_sessionUrlDefine).resolve('/session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final counts = await countDevHostDriftTables(db);
      final profileLabel = prefs.displayName.isEmpty
          ? '(empty)'
          : prefs.displayName;
      if (prefs.onboardingComplete && !prefs.hasProfile) {
        debugPrint(
          'web_dev_host_session: saved to host tables=$counts '
          'profile=$profileLabel (warning: onboarding complete but profile empty)',
        );
      } else {
        debugPrint(
          'web_dev_host_session: saved to host tables=$counts profile=$profileLabel',
        );
      }
    } else {
      final body = response.body;
      debugPrint(
        'web_dev_host_session: PUT failed status=${response.statusCode} '
        'url=$_sessionUrlDefine body=$body',
      );
      if (body.contains('FormatException') && body.contains('version')) {
        debugPrint(
          'web_dev_host_session: stale session server? '
          'Run: dart run melos run stop:web-dev-session then run:dev:web',
        );
      }
    }
  } catch (error, stack) {
    debugPrint('web_dev_host_session: save failed: $error\n$stack');
  } finally {
    _saveInFlight = false;
  }
}

Future<Map<String, dynamic>> _buildHostSnapshotWithRetry(
  AppDatabase db,
  AppPreferences prefs,
) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var attempt = 0; attempt < 5; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 100 * (1 << (attempt - 1))));
    }
    try {
      return await _buildHostSnapshot(db, prefs);
    } catch (error, stack) {
      lastError = error;
      lastStack = stack;
      final message = error.toString();
      if (!message.contains('Transaction used after it was closed')) {
        rethrow;
      }
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack ?? StackTrace.current);
}

Future<Map<String, dynamic>> _buildHostSnapshot(
  AppDatabase db,
  AppPreferences prefs,
) async {
  await waitForDevHostDriftTransactionsIdle();
  final tables = await exportDriftTablesSnapshot(db);
  final identityB64 =
      await IdentityKeystore.secureStorage().exportPrivateKeyB64ForDev();
  return {
    'version': kWebDevHostSessionVersion,
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'prefs': prefs.exportDevHostSnapshot(),
    'identityPrivateKeyB64': identityB64,
    'tables': tables,
  };
}

/// Clears ~/.cache/compartarenta/web-dev-session.json via the dev server.
///
/// Must run after in-app dev wipe (OPFS/prefs); otherwise the next launch
/// restores onboarding and identity from the host file.
Future<void> clearDevHostSessionAfterWipe() async {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;

  try {
    final response = await http
        .delete(Uri.parse(_sessionUrlDefine).resolve('/session'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('web_dev_host_session: cleared host file after dev wipe');
    } else {
      debugPrint(
        'web_dev_host_session: DELETE failed status=${response.statusCode}',
      );
    }
  } catch (error) {
    debugPrint(
      'web_dev_host_session: could not clear host file ($error). '
      'Run: dart run melos run delete:web-dev-session',
    );
  }
}

Future<bool> _consumeBrowserWipePending() async {
  try {
    final response = await http
        .get(
          Uri.parse(_sessionUrlDefine).resolve('/session/wipe-pending'),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return false;
    return decoded['pending'] == true;
  } catch (error) {
    debugPrint(
      'web_dev_wipe: could not read wipe-pending from $_sessionUrlDefine ($error)',
    );
    return false;
  }
}

Future<String?> _fetchHostSession() async {
  try {
    final response = await http
        .get(
          Uri.parse(_sessionUrlDefine).resolve('/session'),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'web_dev_host_session: GET failed status=${response.statusCode}',
      );
      return null;
    }
    return response.body;
  } catch (error) {
    debugPrint(
      'web_dev_host_session: host unreachable at $_sessionUrlDefine ($error). '
      'After refresh.sh the backup file may still exist at '
      '~/.cache/compartarenta/web-dev-session.json but a wrong process on the '
      'port blocks the browser — run: dart run melos run stop:web-dev-session '
      'then run:dev:web (check terminal for the listening URL).',
    );
    return null;
  }
}
