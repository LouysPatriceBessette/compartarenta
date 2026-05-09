import 'dart:io';

import 'package:compartarenta/db/app_database.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrates from v1 to v2 and preserves data', () async {
    // Create a temporary sqlite file with schema v1 for Plans (without notes column).
    final dir = await Directory.systemTemp.createTemp('compartarenta_db_');
    final file = File('${dir.path}/test.sqlite');
    final executor = NativeDatabase(file);

    // Create v1 schema and seed one plan row.
    await executor.runCustom('''
      CREATE TABLE plans (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    await executor.runCustom('''
      INSERT INTO plans (id, type, title, created_at)
      VALUES ('p1', 'housing', 'Test', 0);
    ''');

    // Open with current AppDatabase migration logic (schemaVersion=2 adds notes).
    final db = AppDatabaseForTesting(executor);
    // Trigger open & migration by running a query.
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
  AppDatabaseForTesting(QueryExecutor e) : super.forTesting(e);
}

