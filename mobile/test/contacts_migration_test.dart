import 'dart:io';

import 'package:compartarenta/db/app_database.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v8 -> v9 mirrors participants into contacts and unifies duplicates',
      () async {
    final dir = await Directory.systemTemp.createTemp('compartarenta_v9_');
    final file = File('${dir.path}/test.sqlite');

    // Seed a v8-shaped database directly with the sqlite3 dart binding.
    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 8;');
    raw.execute('''
      CREATE TABLE participants (
        id TEXT NOT NULL PRIMARY KEY,
        display_name TEXT NOT NULL,
        avatar_id TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      INSERT INTO participants (id, display_name, avatar_id, created_at)
      VALUES
        ('housing:p0', 'Alice', 'mdi:0', 0),
        ('housing:p1', 'Bob',   'mdi:1', 0),
        ('vehicle:p0', 'Alice', 'mdi:0', 0);
    ''');
    raw.dispose();

    // Now open through drift; the migration from v8 to v9 should run on
    // first access (e.g., the first query).
    final executor = NativeDatabase(file);
    final db = AppDatabaseForTesting(executor);

    final contacts = await db.listContacts();
    expect(contacts, hasLength(2),
        reason:
            'Identical (name, avatar) pairs across modules should be unified.');

    final participants = await db.listParticipants();
    expect(participants, hasLength(3));
    for (final p in participants) {
      expect(p.contactId, isNotNull,
          reason:
              'Every legacy participant row should be re-pointed to a Contact.');
    }

    final aliceRows =
        participants.where((p) => p.displayName == 'Alice').toList();
    final bobRows = participants.where((p) => p.displayName == 'Bob').toList();
    expect(aliceRows, hasLength(2));
    expect(bobRows, hasLength(1));
    expect(aliceRows.first.contactId, aliceRows.last.contactId);
    expect(aliceRows.first.contactId, isNot(equals(bobRows.first.contactId)));

    for (final c in contacts) {
      expect(c.kind, 'local-only');
      expect(c.deletedAt, isNull);
    }

    await db.close();
  });
}

class AppDatabaseForTesting extends AppDatabase {
  // ignore: use_super_parameters
  AppDatabaseForTesting(QueryExecutor e) : super.forTesting(e);
}
