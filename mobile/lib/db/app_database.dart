import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'db_paths.dart';

part 'app_database.g.dart';

class Plans extends Table {
  TextColumn get id => text()(); // stable id (UUID/ULID later)
  TextColumn get type => text()(); // e.g. housing | car
  TextColumn get title => text().withDefault(const Constant(''))();

  // Added in schema v2 to demonstrate a forward-only migration.
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Participants extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Plans, Participants])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Forward-only migrations. Always handle ranges.
          if (from < 2) {
            await m.addColumn(plans, plans.notes);
          }
        },
        beforeOpen: (details) async {
          // Drift will run onCreate/onUpgrade automatically.
          // This is a hook for sanity checks if needed later.
        },
      );

  Future<void> upsertPlan(PlansCompanion plan) =>
      into(plans).insertOnConflictUpdate(plan);

  Future<List<Plan>> listPlans() =>
      (select(plans)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<void> upsertParticipant(ParticipantsCompanion participant) =>
      into(participants).insertOnConflictUpdate(participant);

  Future<List<Participant>> listParticipants() => (select(participants)
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'compartarenta.sqlite',
    native: DriftNativeOptions(
      databaseDirectory: () async {
        final dir = await DbPaths.dbDirectory();
        return Directory(p.join(dir.path));
      },
    ),
  );
}

