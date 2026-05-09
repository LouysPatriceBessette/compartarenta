import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'db_paths.dart';

part 'app_database.g.dart';

class PlanLines extends Table {
  TextColumn get id => text()(); // stable id
  TextColumn get planId => text()();

  // For housing: recurring fixed vs one-off estimate.
  BoolColumn get isRecurring => boolean()();

  // Free-text label, e.g. Rent / Electricity / Internet.
  TextColumn get title => text()();

  // Currency code (ISO 4217), should match plan currency.
  TextColumn get currency => text()();

  // Amounts stored as integer minor units (e.g., cents).
  IntColumn get amountMinor => integer().nullable()(); // for recurring fixed
  IntColumn get minAmountMinor => integer().nullable()(); // for one-off range
  IntColumn get maxAmountMinor => integer().nullable()(); // for one-off range

  // Cadence for recurring items (initially monthly only).
  TextColumn get cadence => text().withDefault(const Constant('monthly'))();

  // Optional group bucket.
  TextColumn get groupId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlanGroups extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlanRatios extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get participantId => text()();

  // Either applies to a line or a group. Exactly one should be set.
  TextColumn get lineId => text().nullable()();
  TextColumn get groupId => text().nullable()();

  // Weight, e.g. out of 10000 (basis points), or arbitrary weights.
  IntColumn get weight => integer()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AgreementContracts extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();

  // Period bounds for the arrangement.
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();

  // Early withdrawal minimum floor.
  IntColumn get minNoticeDays => integer().withDefault(const Constant(0))();
  IntColumn get penaltyMinor => integer().withDefault(const Constant(0))();

  // Optional flexible clauses (bounded length in UI).
  TextColumn get clauses => text().withDefault(const Constant(''))();

  // Versioning for renegotiation later.
  IntColumn get version => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Plans extends Table {
  TextColumn get id => text()(); // stable id (UUID/ULID later)
  TextColumn get type => text()(); // e.g. housing | car
  TextColumn get title => text().withDefault(const Constant(''))();

  // Added in schema v2 to demonstrate a forward-only migration.
  TextColumn get notes => text().nullable()();

  // Default currency for the plan context.
  TextColumn get currency => text().withDefault(const Constant(''))();

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

class ProposalPackages extends Table {
  TextColumn get id => text()(); // stable id
  TextColumn get planId => text()();

  // Active revision becomes binding only after unanimous acceptance.
  TextColumn get activeRevisionId => text().nullable()();

  // Current pending revision (if any).
  TextColumn get pendingRevisionId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProposalRevisions extends Table {
  TextColumn get id => text()(); // unique per revision
  TextColumn get packageId => text()();
  TextColumn get contentHash => text()(); // normalized content hash string
  TextColumn get proposerParticipantId => text()();

  // Self-contained proposal payload (JSON string for now).
  TextColumn get payloadJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProposalResponses extends Table {
  TextColumn get id => text()();
  TextColumn get revisionId => text()();
  TextColumn get participantId => text()();

  // 'pending' | 'accepted' | 'rejected'
  TextColumn get status => text()();

  DateTimeColumn get respondedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Plans,
  Participants,
  PlanLines,
  PlanGroups,
  PlanRatios,
  AgreementContracts,
  ProposalPackages,
  ProposalRevisions,
  ProposalResponses,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

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
          if (from < 3) {
            await m.addColumn(plans, plans.currency);
            await m.createTable(planGroups);
            await m.createTable(planLines);
            await m.createTable(planRatios);
            await m.createTable(agreementContracts);
          }
          if (from < 4) {
            await m.createTable(proposalPackages);
            await m.createTable(proposalRevisions);
            await m.createTable(proposalResponses);
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

  Future<void> upsertContract(AgreementContractsCompanion contract) =>
      into(agreementContracts).insertOnConflictUpdate(contract);

  Future<AgreementContract?> getContractForPlan(String planId) =>
      (select(agreementContracts)..where((t) => t.planId.equals(planId)))
          .getSingleOrNull();

  Future<void> upsertPlanLine(PlanLinesCompanion line) =>
      into(planLines).insertOnConflictUpdate(line);

  Future<List<PlanLine>> listPlanLines(String planId) =>
      (select(planLines)..where((t) => t.planId.equals(planId))).get();

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

