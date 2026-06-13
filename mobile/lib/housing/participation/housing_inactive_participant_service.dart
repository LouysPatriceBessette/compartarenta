import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';
import 'housing_participation_membership_service.dart';

/// Ledger-only ghost participant created when someone leaves (#2/#3).
class HousingInactiveParticipantService {
  HousingInactiveParticipantService(this._db);

  final AppDatabase _db;

  Future<String> createInactiveParticipant({
    required String planId,
    required String sourceParticipantId,
  }) async {
    final existing =
        await (_db.select(_db.housingInactiveParticipants)
              ..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.sourceParticipantId.equals(sourceParticipantId) &
                    t.clearedAt.isNull(),
              ))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final roster = await participantsForPlan(_db, planId);
    final name = displayNameForParticipant(sourceParticipantId, roster);
    final id =
        'inactive:$planId:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    await _db.into(_db.housingInactiveParticipants).insert(
      HousingInactiveParticipantsCompanion.insert(
        id: id,
        planId: planId,
        sourceParticipantId: sourceParticipantId,
        displayNameSnapshot: name,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return id;
  }

  Future<List<HousingInactiveParticipant>> listUncleared(String planId) async {
    final rows = await (_db.select(_db.housingInactiveParticipants)
          ..where(
            (t) => t.planId.equals(planId) & t.clearedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final bySource = <String, HousingInactiveParticipant>{};
    for (final row in rows) {
      final existing = bySource[row.sourceParticipantId];
      if (existing == null || row.createdAt.isBefore(existing.createdAt)) {
        bySource[row.sourceParticipantId] = row;
      }
    }
    final distinct = bySource.values.toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return distinct;
  }

  Future<HousingInactiveParticipant?> getById(String inactiveParticipantId) {
    return (_db.select(_db.housingInactiveParticipants)
          ..where((t) => t.id.equals(inactiveParticipantId)))
        .getSingleOrNull();
  }

  /// Ensures a ledger ghost exists for every departed roster member on this device.
  Future<void> ensureInactiveForDepartedMembers(String planId) async {
    final membership = HousingParticipationMembershipService(_db);
    await membership.ensureMembershipsForPlan(planId);
    final departed =
        await (_db.select(_db.housingPlanMemberships)..where(
          (t) =>
              t.planId.equals(planId) &
              t.status.equals(HousingPlanMembershipStatus.departed.wireValue),
        )).get();
    for (final row in departed) {
      await createInactiveParticipant(
        planId: planId,
        sourceParticipantId: row.participantId,
      );
    }
  }

  Future<void> markCleared(String inactiveParticipantId) async {
    await (_db.update(_db.housingInactiveParticipants)
          ..where((t) => t.id.equals(inactiveParticipantId)))
        .write(
      HousingInactiveParticipantsCompanion(
        clearedAt: drift.Value(DateTime.now().toUtc()),
      ),
    );
  }
}
