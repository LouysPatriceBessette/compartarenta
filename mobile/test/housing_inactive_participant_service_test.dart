import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_inactive_participant_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createInactiveParticipant returns existing row for same source', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:inact';
    const sourceId = '$planId:p1';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: sourceId,
        displayName: 'Roberr',
        avatarId: 'a',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final svc = HousingInactiveParticipantService(db);
    final first = await svc.createInactiveParticipant(
      planId: planId,
      sourceParticipantId: sourceId,
    );
    final second = await svc.createInactiveParticipant(
      planId: planId,
      sourceParticipantId: sourceId,
    );
    expect(second, first);

    final rows = await svc.listUncleared(planId);
    expect(rows, hasLength(1));
    expect(rows.single.sourceParticipantId, sourceId);
  });

  test('listUncleared dedupes legacy duplicate rows by source', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:inact-dup';
    const sourceId = '$planId:p1';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: sourceId,
        displayName: 'Roberr',
        avatarId: 'a',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await db.into(db.housingInactiveParticipants).insert(
      HousingInactiveParticipantsCompanion.insert(
        id: 'inactive:$planId:1',
        planId: planId,
        sourceParticipantId: sourceId,
        displayNameSnapshot: 'Roberr',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await db.into(db.housingInactiveParticipants).insert(
      HousingInactiveParticipantsCompanion.insert(
        id: 'inactive:$planId:2',
        planId: planId,
        sourceParticipantId: sourceId,
        displayNameSnapshot: 'Roberr',
        createdAt: DateTime.utc(2026, 6, 2),
      ),
    );

    final rows = await HousingInactiveParticipantService(db).listUncleared(planId);
    expect(rows, hasLength(1));
    expect(rows.single.id, 'inactive:$planId:1');
  });

  test('ensureInactiveForDepartedMembers creates ghosts for departed roster', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:departed';
    const sourceId = '$planId:p1';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: sourceId,
        displayName: 'Roberr',
        avatarId: 'a',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.housingPlanMemberships).insert(
      HousingPlanMembershipsCompanion.insert(
        planId: planId,
        participantId: sourceId,
        status: 'departed',
      ),
    );

    final svc = HousingInactiveParticipantService(db);
    await svc.ensureInactiveForDepartedMembers(planId);

    final rows = await svc.listUncleared(planId);
    expect(rows, hasLength(1));
    expect(rows.single.sourceParticipantId, sourceId);
  });
}
