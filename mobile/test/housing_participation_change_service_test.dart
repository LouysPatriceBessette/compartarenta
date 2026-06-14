import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _threeParticipantPlanAfterEjection() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  const planId = 'housing:post-eject';
  const ejectedId = '$planId:p2';

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  for (final entry in [
    ('$planId:self', 'Monica'),
    ('$planId:p1', 'Louys'),
    (ejectedId, 'Roberr'),
  ]) {
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: entry.$1,
        displayName: entry.$2,
        avatarId: 'a',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }
  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$planId',
      planId: planId,
      activeRevisionId: const drift.Value('rev:1'),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );

  final membership = HousingParticipationMembershipService(db);
  await membership.ensureMembershipsForPlan(planId);
  await membership.markDeparted(
    planId: planId,
    participantId: ejectedId,
    departureKind: HousingParticipationChangeKind.ejection,
    changeId: 'pc:eject',
  );
  return db;
}

void main() {
  test(
    'deciderParticipantsFor immediate termination excludes departed members',
    () async {
      final db = await _threeParticipantPlanAfterEjection();
      addTearDown(db.close);

      const planId = 'housing:post-eject';
      await db.into(db.housingParticipationChanges).insert(
        HousingParticipationChangesCompanion.insert(
          id: 'pc:term',
          planId: planId,
          packageId: 'pkg:$planId',
          kind: HousingParticipationChangeKind.immediateTermination.wireValue,
          initiatorParticipantId: '$planId:p1',
          status: HousingParticipationChangeStatus.pending.wireValue,
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );

      final change =
          await HousingParticipationChangeService(db).getById('pc:term');
      expect(change, isNotNull);

      final deciders =
          await HousingParticipationChangeService(db).deciderParticipantsFor(
        change!,
      );
      expect(
        deciders.map((p) => p.displayName),
        containsAll(['Louys', 'Monica']),
      );
      expect(deciders.length, 2);
    },
  );

  test('recordDecision ignores departed participant on termination vote', () async {
    final db = await _threeParticipantPlanAfterEjection();
    addTearDown(db.close);

    const planId = 'housing:post-eject';
    const ejectedId = '$planId:p2';
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: 'pc:term2',
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.immediateTermination.wireValue,
        initiatorParticipantId: '$planId:p1',
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );
    await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
      HousingParticipationDecisionsCompanion.insert(
        changeId: 'pc:term2',
        participantId: '$planId:p1',
        status: HousingParticipationDecisionStatus.accepted.wireValue,
        decidedAt: drift.Value(DateTime.utc(2026, 6, 13)),
      ),
    );

    final svc = HousingParticipationChangeService(db);
    await svc.recordDecision(
      changeId: 'pc:term2',
      participantId: ejectedId,
      accepted: true,
    );

    final decisions = await svc.decisionsFor('pc:term2');
    expect(decisions.map((d) => d.participantId), ['$planId:p1']);
    final row = await svc.getById('pc:term2');
    expect(row?.status, HousingParticipationChangeStatus.pending.wireValue);
  });

  test('allDecidersHaveAccepted is true when every active decider accepted', () async {
    final db = await _threeParticipantPlanAfterEjection();
    addTearDown(db.close);

    const planId = 'housing:post-eject';
    const changeId = 'pc:term-all';
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.immediateTermination.wireValue,
        initiatorParticipantId: '$planId:p1',
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );
    for (final entry in [
      ('$planId:p1', HousingParticipationDecisionStatus.accepted),
      ('$planId:self', HousingParticipationDecisionStatus.accepted),
    ]) {
      await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
        HousingParticipationDecisionsCompanion.insert(
          changeId: changeId,
          participantId: entry.$1,
          status: entry.$2.wireValue,
          decidedAt: drift.Value(DateTime.utc(2026, 6, 13)),
        ),
      );
    }

    final svc = HousingParticipationChangeService(db);
    expect(await svc.allDecidersHaveAccepted(changeId), isTrue);
    expect(
      (await svc.getById(changeId))?.status,
      HousingParticipationChangeStatus.pending.wireValue,
    );
  });

  test('cancelVoluntaryWithdrawal aborts pending request for initiator only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-cancel';
    const louysId = '$planId:louys';
    const monicaId = '$planId:monica';
    const changeId = 'pc:withdraw-cancel';

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );
    for (final entry in [
      (monicaId, 'Monica'),
      (louysId, 'Louys'),
    ]) {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: entry.$1,
          displayName: entry.$2,
          avatarId: 'a',
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );
    }
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: 'pkg:$planId',
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );
    await HousingParticipationMembershipService(db).ensureMembershipsForPlan(
      planId,
    );
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.voluntaryWithdrawal.wireValue,
        initiatorParticipantId: louysId,
        targetParticipantId: drift.Value(louysId),
        departureDate: drift.Value(DateTime.utc(2026, 7, 13)),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );

    final svc = HousingParticipationChangeService(db);
    expect(
      await svc.cancelVoluntaryWithdrawal(
        changeId: changeId,
        participantId: monicaId,
      ),
      isFalse,
    );
    expect(
      await svc.cancelVoluntaryWithdrawal(
        changeId: changeId,
        participantId: louysId,
      ),
      isTrue,
    );
    expect(
      (await svc.getById(changeId))?.status,
      HousingParticipationChangeStatus.aborted.wireValue,
    );
    expect(await svc.pendingForPlan(planId), isNull);
  });
}
