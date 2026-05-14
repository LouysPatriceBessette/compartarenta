import 'dart:io';

import 'db_paths.dart';

class DbReset {
  const DbReset._();

  /// Deletes the local SQLite database directory (including WAL/SHM and any
  /// extra files Drift or migrations may leave under [DbPaths.dbDirName]).
  ///
  /// This removes all relational data on device, including the Contacts
  /// module tables (`contacts`, `contact_invitations`, `pending_handshakes`,
  /// and participant `contact_id` links).
  ///
  /// This is intended for development/test workflows only.
  static Future<void> deleteLocalDbFiles() async {
    final dir = await DbPaths.dbDirectory();
    if (!await dir.exists()) return;

    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Fallback: some platforms may keep handles open on unrelated files;
      // remove the primary database files explicitly.
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

