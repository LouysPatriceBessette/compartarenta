import 'dart:io';

import 'db_paths.dart';

class DbReset {
  const DbReset._();

  /// Deletes the local SQLite database files.
  ///
  /// This is intended for development/test workflows only.
  static Future<void> deleteLocalDbFiles() async {
    final dir = await DbPaths.dbDirectory();
    final dbFile = await DbPaths.dbFile();

    // Also remove WAL/SHM if present.
    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');

    await _safeDelete(shmFile);
    await _safeDelete(walFile);
    await _safeDelete(dbFile);

    // Best effort cleanup of directory.
    if (await dir.exists()) {
      try {
        final entries = await dir.list().toList();
        if (entries.isEmpty) {
          await dir.delete();
        }
      } catch (_) {
        // ignore
      }
    }
  }

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore
    }
  }
}

