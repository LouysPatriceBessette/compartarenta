import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_journal.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadHousingParticipationChangeJournal emits one entry per change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:journal';
    const pkgId = 'pkg:journal';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Self',
        avatarId: 'a',
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Peer',
        avatarId: 'b',
        createdAt: DateTime.utc(2026),
      ),
    );

    const changeId = 'pc:journal:1';
    final createdAt = DateTime.utc(2026, 3, 1);
    final settledAt = DateTime.utc(2026, 3, 5);

    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: pkgId,
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: '$planId:self',
        targetParticipantId: const drift.Value('$planId:p0'),
        status: HousingParticipationChangeStatus.effective.wireValue,
        createdAt: createdAt,
        settledAt: drift.Value(settledAt),
      ),
    );
    await db.into(db.housingParticipationDecisions).insert(
      HousingParticipationDecisionsCompanion.insert(
        changeId: changeId,
        participantId: '$planId:p0',
        status: HousingParticipationDecisionStatus.accepted.wireValue,
        decidedAt: drift.Value(DateTime.utc(2026, 3, 2)),
      ),
    );

    final entries = await loadHousingParticipationChangeJournal(
      db: db,
      planId: planId,
    );

    expect(entries, hasLength(1));
    expect(entries.single.changeId, changeId);
    expect(
      entries.single.eventKind,
      HousingParticipationJournalEventKind.effective,
    );
  });
}
