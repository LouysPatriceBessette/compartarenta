import 'dart:io';

import 'package:compartarenta/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates from v1 to v2 and preserves data', () async {
    final dir = await Directory.systemTemp.createTemp('compartarenta_db_');
    final file = File('${dir.path}/test.sqlite');

    // Seed v1 schema with sqlite3 (avoids NativeDatabase.runCustom before open).
    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 1;');
    raw.execute('''
      CREATE TABLE plans (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE participants (
        id TEXT NOT NULL PRIMARY KEY,
        display_name TEXT NOT NULL,
        avatar_id TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      INSERT INTO plans (id, type, title, created_at)
      VALUES ('p1', 'housing', 'Test', 0);
    ''');
    raw.dispose();

    final executor = NativeDatabase(file);
    final db = AppDatabaseForTesting(executor);
    final plans = await db.listPlans();

    expect(plans, hasLength(1));
    expect(plans.single.id, 'p1');
    expect(plans.single.type, 'housing');
    expect(plans.single.title, 'Test');
    expect(plans.single.notes, null);

    await db.close();
    await executor.close();
  });
}

/// Test helper to inject an executor.
class AppDatabaseForTesting extends AppDatabase {
  // ignore: use_super_parameters
  AppDatabaseForTesting(super.e) : super.forTesting();
}
