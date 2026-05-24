import 'dart:io';

import '../prefs/app_preferences.dart';
import 'db_paths.dart';

/// Deletes on-disk SQLite files (Android, iOS, desktop).
Future<void> deleteLocalDbFiles({AppPreferences? prefs}) async {
  if (prefs != null) {
    await prefs.clearHousingPlanDraftBackupMirrors();
  }

  final dir = await DbPaths.dbDirectory();
  if (!await dir.exists()) return;

  try {
    await dir.delete(recursive: true);
  } catch (_) {
    final dbFile = await DbPaths.dbFile();
    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');
    await _safeDelete(shmFile);
    await _safeDelete(walFile);
    await _safeDelete(dbFile);
    try {
      if (await dir.exists()) {
        final entries = await dir.list().toList();
        if (entries.isEmpty) {
          await dir.delete();
        }
      }
    } catch (_) {
      // ignore
    }
  }
}

Future<void> _safeDelete(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // ignore
  }
}
