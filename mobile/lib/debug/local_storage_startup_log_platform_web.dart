// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<void> logWebLocalStorageKeyCount({required String reason}) async {
  var localStorageKeys = 0;
  var appLikeKeys = 0;
  for (var i = 0; i < web.window.localStorage.length; i++) {
    final key = web.window.localStorage.key(i);
    if (key == null) continue;
    localStorageKeys++;
    if (key.startsWith('flutter.') ||
        key.startsWith('compartarenta.') ||
        key.contains('onboarding')) {
      appLikeKeys++;
    }
  }
  debugPrint(
    'local_storage_startup: reason=$reason '
    'localStorageKeys=$localStorageKeys appLikeKeys=$appLikeKeys',
  );
}

Future<void> logExtraWebPersistenceHints() async {
  var localStorageKeys = 0;
  var housingMirrorKeys = 0;
  for (var i = 0; i < web.window.localStorage.length; i++) {
    final key = web.window.localStorage.key(i);
    if (key == null) continue;
    localStorageKeys++;
    if (key.startsWith('compartarenta.') ||
        key.startsWith('flutter.') ||
        key.contains('onboarding')) {
      housingMirrorKeys++;
    }
  }

  var wasmDbCount = -1;
  try {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    wasmDbCount = probe.existingDatabases.length;
    if (wasmDbCount > 0) {
      debugPrint(
        'local_storage_startup: wasmExistingDatabases=$wasmDbCount '
        'entries=${probe.existingDatabases.map((e) => '${e.$1.name}:${e.$2}').join(', ')}',
      );
    } else {
      debugPrint('local_storage_startup: wasmExistingDatabases=0');
    }
  } catch (error, stack) {
    debugPrint(
      'local_storage_startup: wasmProbeFailed error=$error\n$stack',
    );
  }

  debugPrint(
    'local_storage_startup: localStorageKeys=$localStorageKeys '
    'appLikeKeys=$housingMirrorKeys',
  );
}
