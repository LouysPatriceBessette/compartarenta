import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';
import '../relay/identity_keystore.dart';
import 'web_dev_db_snapshot.dart';

/// Must match the Flutter web origin host (localhost vs 127.0.0.1) or the
/// browser blocks cross-origin fetches to the dev session server.
const _sessionUrlDefine = String.fromEnvironment(
  'WEB_DEV_SESSION_URL',
  defaultValue: 'http://localhost:18765',
);

Timer? _saveDebounce;
bool _saveInFlight = false;

/// Restores prefs, identity, and Drift tables from the host dev session file.
Future<void> restoreDevSessionFromHostIfNeeded(AppDatabase db) async {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;

  final raw = await _fetchHostSession();
  if (raw == null) return;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    if (decoded['version'] != kWebDevHostSessionVersion) {
      debugPrint(
        'web_dev_host_session: unsupported version ${decoded['version']}',
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

    await importDriftTablesSnapshot(db, tables);

    final prefs = await AppPreferences.load();
    await prefs.importDevHostSnapshot(prefsMap);

    final identityB64 = decoded['identityPrivateKeyB64'];
    if (identityB64 is String && identityB64.isNotEmpty) {
      await IdentityKeystore.secureStorage().restorePrivateKeyB64ForDev(
        identityB64,
      );
    }

    await db.syncWebStorageToDisk();

    final contacts = await db.select(db.contacts).get();
    debugPrint(
      'web_dev_host_session: restored from host '
      'contacts=${contacts.length} onboardingComplete=${prefs.onboardingComplete}',
    );
  } catch (error, stack) {
    debugPrint('web_dev_host_session: restore failed: $error\n$stack');
  }
}

/// Immediate push (e.g. right after onboarding completes).
Future<void> saveDevHostSessionNow(AppDatabase db) async {
  if (!kDebugMode) return;
  await _pushHostSessionSnapshot(db);
}

/// Debounced push to the host session server (survives Ctrl+C on Flutter web).
void scheduleDevHostSessionSave(AppDatabase db) {
  if (!kDebugMode) return;
  if (_sessionUrlDefine.isEmpty) return;

  _saveDebounce?.cancel();
  _saveDebounce = Timer(const Duration(milliseconds: 350), () {
    unawaited(_pushHostSessionSnapshot(db));
  });
}

Future<void> _pushHostSessionSnapshot(AppDatabase db) async {
  if (_saveInFlight) return;
  _saveInFlight = true;
  try {
    final prefs = await AppPreferences.load();
    if (!prefs.onboardingComplete) return;

    final payload = await _buildHostSnapshot(db, prefs);
    final response = await http
        .put(
          Uri.parse(_sessionUrlDefine).resolve('/session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final contacts =
          (payload['tables'] as Map<String, dynamic>?)?['contacts'];
      final count = contacts is List ? contacts.length : 0;
      debugPrint(
        'web_dev_host_session: saved to host contacts=$count',
      );
    } else {
      debugPrint(
        'web_dev_host_session: PUT failed status=${response.statusCode} '
        'body=${response.body}',
      );
    }
  } catch (error, stack) {
    debugPrint('web_dev_host_session: save failed: $error\n$stack');
  } finally {
    _saveInFlight = false;
  }
}

Future<Map<String, dynamic>> _buildHostSnapshot(
  AppDatabase db,
  AppPreferences prefs,
) async {
  final identityB64 =
      await IdentityKeystore.secureStorage().exportPrivateKeyB64ForDev();
  return {
    'version': kWebDevHostSessionVersion,
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'prefs': prefs.exportDevHostSnapshot(),
    'identityPrivateKeyB64': identityB64,
    'tables': await exportDriftTablesSnapshot(db),
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
