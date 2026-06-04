import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_participants.dart';

/// Ledger-only ghost participant created when someone leaves (#2/#3).
class HousingInactiveParticipantService {
  HousingInactiveParticipantService(this._db);

  final AppDatabase _db;

  Future<String> createInactiveParticipant({
    required String planId,
    required String sourceParticipantId,
  }) async {
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
    return (_db.select(_db.housingInactiveParticipants)
          ..where(
            (t) => t.planId.equals(planId) & t.clearedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<HousingInactiveParticipant?> getById(String inactiveParticipantId) {
    return (_db.select(_db.housingInactiveParticipants)
          ..where((t) => t.id.equals(inactiveParticipantId)))
        .getSingleOrNull();
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
