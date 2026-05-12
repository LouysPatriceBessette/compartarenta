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
  /// When false: [amountMinor] is the fixed amount (per month if recurring, total if one-off).
  /// When true: [minAmountMinor] / [maxAmountMinor] define an approximate band (both types).
  BoolColumn get amountUsesRange =>
      boolean().withDefault(const Constant(false))();

  IntColumn get amountMinor => integer().nullable()();
  IntColumn get minAmountMinor => integer().nullable()();
  IntColumn get maxAmountMinor => integer().nullable()();

  /// Optional longer description for the expense.
  TextColumn get description => text().withDefault(const Constant(''))();

  // Cadence for recurring items (initially monthly only).
  TextColumn get cadence => text().withDefault(const Constant('monthly'))();

  /// Day of month (1–31) when a monthly recurring charge applies.
  IntColumn get recurrenceDayOfMonth => integer().nullable()();

  /// Display order within the plan (lower first).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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

  /// Optional guidance for what expenses belong in this category.
  TextColumn get description => text().withDefault(const Constant(''))();

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

@DataClassName('Agreement')
class Agreements extends Table {
  @override
  String get tableName => 'agreement_contracts';

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

  /// When false: JSON map per participant id -> { minNoticeDays, penaltyMinor }.
  TextColumn get withdrawalSameForAll =>
      text().withDefault(const Constant('true'))();

  TextColumn get withdrawalPerParticipantJson =>
      text().withDefault(const Constant('{}'))();

  /// Structured agreement rules (curfew, toggles, custom rules, dismissed suggestions).
  TextColumn get agreementRulesJson =>
      text().withDefault(const Constant('{}'))();

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

  /// Reference to the authoritative identity in [Contacts]. Nullable for
  /// legacy rows that existed before the Contacts module shipped. The
  /// `displayName` and `avatarId` columns on this row act as the historical
  /// display snapshot if the referenced Contact is later deleted.
  TextColumn get contactId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Identity record for a person the local user knows.
///
/// A Contact is either `local-only` (no relay routing material; cannot
/// receive module proposals) or `connected` (has the routing identifier
/// and public key material populated and may receive proposals).
class Contacts extends Table {
  TextColumn get id => text()();

  /// `local-only` | `connected` | `archived`.
  TextColumn get kind => text()();

  TextColumn get displayName => text()();
  TextColumn get avatarId => text()();

  /// Free-text notes the local user keeps about this contact.
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Local-only flag. When true, inbound envelopes from this contact are
  /// dropped on receipt regardless of their kind.
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();

  /// Opaque relay routing identifier exchanged during the handshake.
  /// Populated only when kind = connected.
  TextColumn get relayRoutingId => text().nullable()();

  /// Peer public key material (base64 or similar) exchanged during the
  /// handshake. Populated only when kind = connected.
  TextColumn get peerPublicMaterial => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// When the Contact was logically deleted by the local user.
  /// Module participant rows that referenced this contact continue to render
  /// from their stored snapshot (`Participants.displayName` / `avatarId`).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per outstanding outgoing invitation code.
class ContactInvitations extends Table {
  /// Stable identifier; not the human-readable code.
  TextColumn get id => text()();

  /// Opaque local copy of the nonce embedded in the invitation code.
  /// Consumed when a matching `hello` envelope is validated locally.
  TextColumn get nonce => text()();

  /// `pending` | `used` | `expired` | `revoked`.
  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  /// Set when the invitation has been consumed (used/revoked/expired).
  DateTimeColumn get consumedAt => dateTime().nullable()();

  /// When the handshake completes, points to the Contact stub on this
  /// device that should be promoted to `connected`.
  TextColumn get contactStubId => text().nullable()();

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
  Agreements,
  ProposalPackages,
  ProposalRevisions,
  ProposalResponses,
  Contacts,
  ContactInvitations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

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
            await m.createTable(agreements);
          }
          if (from < 4) {
            await m.createTable(proposalPackages);
            await m.createTable(proposalRevisions);
            await m.createTable(proposalResponses);
          }
          if (from < 5) {
            await m.addColumn(planLines, planLines.recurrenceDayOfMonth);
            await m.addColumn(planLines, planLines.sortOrder);
            await m.addColumn(agreements, agreements.withdrawalSameForAll);
            await m.addColumn(agreements, agreements.withdrawalPerParticipantJson);
          }
          if (from < 6) {
            await m.addColumn(planLines, planLines.amountUsesRange);
            await m.addColumn(planLines, planLines.description);
            await customStatement(
              '''
              UPDATE plan_lines
              SET amount_uses_range = CASE
                WHEN is_recurring = 0
                    AND IFNULL(min_amount_minor, -1) != IFNULL(max_amount_minor, -2)
                THEN 1
                ELSE 0
              END
              ''',
            );
            await customStatement(
              '''
              UPDATE plan_lines
              SET amount_minor = min_amount_minor
              WHERE is_recurring = 0
                AND amount_uses_range = 0
                AND amount_minor IS NULL
                AND min_amount_minor IS NOT NULL
              ''',
            );
          }
          if (from < 7) {
            await m.addColumn(planGroups, planGroups.description);
          }
          if (from < 8) {
            await m.addColumn(agreements, agreements.agreementRulesJson);
          }
          if (from < 9) {
            await m.createTable(contacts);
            await m.createTable(contactInvitations);
            await m.addColumn(participants, participants.contactId);
            await _mirrorParticipantsIntoContacts();
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

  Future<void> upsertAgreement(AgreementsCompanion row) =>
      into(agreements).insertOnConflictUpdate(row);

  /// True when a proposal package for [planId] has an active (accepted) revision.
  /// Used to lock removal of agreement rules that were part of a binding package.
  Future<bool> planHasActiveAcceptedProposal(String planId) async {
    final row = await (select(proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .getSingleOrNull();
    return row?.activeRevisionId != null;
  }

  Future<Agreement?> getAgreementForPlan(String planId) async {
    final rows = await (select(agreements)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.version),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first;

    // `getSingleOrNull` throws when more than one row matches. Duplicates can
    // appear if older inserts used a different primary key than upserts.
    final canonicalId = 'agreement:$planId';
    Agreement? canonicalRow;
    for (final r in rows) {
      if (r.id == canonicalId) {
        canonicalRow = r;
        break;
      }
    }
    final keep = canonicalRow ?? rows.first;

    await batch((b) {
      for (final r in rows) {
        if (r.id != keep.id) {
          b.deleteWhere(agreements, (t) => t.id.equals(r.id));
        }
      }
    });
    return keep;
  }

  Future<void> upsertPlanLine(PlanLinesCompanion line) =>
      into(planLines).insertOnConflictUpdate(line);

  Future<List<PlanLine>> listPlanLines(String planId) => (select(planLines)
        ..where((t) => t.planId.equals(planId))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .get();

  Future<List<PlanGroup>> listPlanGroups(String planId) => (select(planGroups)
        ..where((t) => t.planId.equals(planId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<void> upsertPlanGroup(PlanGroupsCompanion row) =>
      into(planGroups).insertOnConflictUpdate(row);

  Future<void> upsertPlanRatio(PlanRatiosCompanion row) =>
      into(planRatios).insertOnConflictUpdate(row);

  Future<List<PlanRatio>> listPlanRatios(String planId) =>
      (select(planRatios)..where((t) => t.planId.equals(planId))).get();

  /// Deletes plan lines, ratios, agreement, groups, proposal state, and
  /// participants whose ids start with `planId:p` (housing draft roster).
  Future<void> deletePlanRelatedData(String planId) async {
    await transaction(() async {
      final pkgs = await (select(proposalPackages)
            ..where((t) => t.planId.equals(planId)))
          .get();
      for (final pkg in pkgs) {
        final revs = await (select(proposalRevisions)
              ..where((t) => t.packageId.equals(pkg.id)))
            .get();
        for (final r in revs) {
          await (delete(proposalResponses)
                ..where((t) => t.revisionId.equals(r.id)))
              .go();
        }
        await (delete(proposalRevisions)
              ..where((t) => t.packageId.equals(pkg.id)))
            .go();
        await (delete(proposalPackages)..where((t) => t.id.equals(pkg.id))).go();
      }
      await (delete(planRatios)..where((t) => t.planId.equals(planId))).go();
      await (delete(planLines)..where((t) => t.planId.equals(planId))).go();
      await (delete(agreements)..where((t) => t.planId.equals(planId))).go();
      await (delete(planGroups)..where((t) => t.planId.equals(planId))).go();

      final all = await listParticipants();
      for (final p in all) {
        if (p.id.startsWith('$planId:p') || p.id == '$planId:self') {
          await (delete(participants)..where((t) => t.id.equals(p.id))).go();
        }
      }
    });
  }

  Future<void> upsertParticipant(ParticipantsCompanion participant) =>
      into(participants).insertOnConflictUpdate(participant);

  Future<List<Participant>> listParticipants() => (select(participants)
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();

  Future<void> upsertContact(ContactsCompanion row) =>
      into(contacts).insertOnConflictUpdate(row);

  Future<Contact?> getContact(String id) =>
      (select(contacts)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns visible contacts (not deleted). Deleted contacts remain in the
  /// database so historical module ledger snapshots stay readable.
  Future<List<Contact>> listContacts({bool includeDeleted = false}) {
    final q = select(contacts);
    if (!includeDeleted) {
      q.where((t) => t.deletedAt.isNull());
    }
    q.orderBy([
      (t) => OrderingTerm.asc(t.displayName),
      (t) => OrderingTerm.asc(t.id),
    ]);
    return q.get();
  }

  Future<void> upsertContactInvitation(ContactInvitationsCompanion row) =>
      into(contactInvitations).insertOnConflictUpdate(row);

  Future<List<ContactInvitation>> listContactInvitations() =>
      (select(contactInvitations)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Mirrors every existing `participants` row into a `contacts` row and
  /// re-points the participant's `contact_id` foreign key. Identical
  /// `(displayName, avatarId)` pairs are unified into a single Contact;
  /// otherwise distinct Contacts are created. Runs only when invoked from
  /// the v9 migration and is idempotent against repeated invocations.
  Future<void> _mirrorParticipantsIntoContacts() async {
    final now = DateTime.now().toUtc();
    final partRows = await select(participants).get();
    if (partRows.isEmpty) return;

    final indexByKey = <String, String>{};
    for (final p in partRows) {
      if (p.contactId != null) continue;
      final key = '${p.displayName}\u0000${p.avatarId}';
      var contactId = indexByKey[key];
      if (contactId == null) {
        contactId = 'contact:p:${p.id}';
        indexByKey[key] = contactId;
        await into(contacts).insertOnConflictUpdate(
          ContactsCompanion.insert(
            id: contactId,
            kind: 'local-only',
            displayName: p.displayName,
            avatarId: p.avatarId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      await (update(participants)..where((t) => t.id.equals(p.id))).write(
        ParticipantsCompanion(contactId: Value(contactId)),
      );
    }
  }
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

