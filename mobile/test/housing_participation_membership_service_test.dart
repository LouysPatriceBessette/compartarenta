import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ensureMembershipsForPlan does not reset departed membership', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:membership';
    const departedId = '$planId:p1';

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Monica',
        avatarId: 'a',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: departedId,
        displayName: 'Roberr',
        avatarId: 'b',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);
    await svc.markDeparted(
      planId: planId,
      participantId: departedId,
      departureKind: HousingParticipationChangeKind.ejection,
      changeId: 'pc:1',
    );

    await svc.ensureMembershipsForPlan(planId);

    expect(await svc.isActiveMember(planId, departedId), isFalse);
    expect(await svc.isActiveMember(planId, '$planId:self'), isTrue);
    final active = await svc.activeParticipantsForPlan(planId);
    expect(active.map((p) => p.id), ['$planId:self']);
  });
}
