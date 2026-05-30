// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../debug/web_dev_host_session.dart';
import '../prefs/app_preferences.dart';

const _legacyMirrorKey = 'housing.default.planDraftBackupJson';
const _mirrorKeyPrefix = 'compartarenta.housing.planDraftBackup.';

/// Deletes Drift WASM storage (OPFS / IndexedDB) and housing draft mirrors on web.
Future<void> deleteLocalDbFiles({AppPreferences? prefs}) async {
  _clearHousingMirrorsInLocalStorage();
  if (prefs != null) {
    await prefs.clearHousingPlanDraftBackupMirrors();
  }

  try {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    final listed = probe.existingDatabases;
    for (final existing in listed) {
      await probe.deleteDatabase(existing);
    }
    if (listed.isNotEmpty) {
      debugPrint('DbReset web: deleted ${listed.length} Wasm database(s)');
    } else {
      debugPrint('DbReset web: no Wasm databases listed under OPFS');
    }
  } catch (e, st) {
    debugPrint('DbReset web Wasm probe/delete failed: $e\n$st');
  }

  await clearDevHostSessionAfterWipe();
}

void _clearHousingMirrorsInLocalStorage() {
  final keysToRemove = <String>[];
  for (var i = 0; i < web.window.localStorage.length; i++) {
    final key = web.window.localStorage.key(i);
    if (key == null) continue;
    if (key == _legacyMirrorKey || key.startsWith(_mirrorKeyPrefix)) {
      keysToRemove.add(key);
    }
  }
  for (final key in keysToRemove) {
    web.window.localStorage.removeItem(key);
  }
  if (keysToRemove.isNotEmpty) {
    debugPrint(
      'DbReset web: cleared ${keysToRemove.length} housing mirror key(s) '
      'from localStorage',
    );
  }
}
