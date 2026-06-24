import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:compartarenta/housing/participation/housing_voluntary_withdrawal_ack.dart';
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
    'deciderParticipantsFor ejection excludes target from deciders',
    () async {
      final db = await _threeParticipantPlanAfterEjection();
      addTearDown(db.close);

      const planId = 'housing:post-eject';
      await db.into(db.housingParticipationChanges).insert(
        HousingParticipationChangesCompanion.insert(
          id: 'pc:eject-deciders',
          planId: planId,
          packageId: 'pkg:$planId',
          kind: HousingParticipationChangeKind.ejection.wireValue,
          initiatorParticipantId: '$planId:p1',
          targetParticipantId: const drift.Value('$planId:p2'),
          status: HousingParticipationChangeStatus.pending.wireValue,
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );

      final change =
          await HousingParticipationChangeService(db).getById('pc:eject-deciders');
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

  test('recordDecision ignores ejection target vote', () async {
    final db = await _threeParticipantPlanAfterEjection();
    addTearDown(db.close);

    const planId = 'housing:post-eject';
    const ejectedId = '$planId:p2';
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: 'pc:eject-vote',
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: '$planId:p1',
        targetParticipantId: const drift.Value(ejectedId),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );
    await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
      HousingParticipationDecisionsCompanion.insert(
        changeId: 'pc:eject-vote',
        participantId: '$planId:p1',
        status: HousingParticipationDecisionStatus.accepted.wireValue,
        decidedAt: drift.Value(DateTime.utc(2026, 6, 13)),
      ),
    );

    final svc = HousingParticipationChangeService(db);
    await svc.recordDecision(
      changeId: 'pc:eject-vote',
      participantId: ejectedId,
      accepted: true,
    );

    final decisions = await svc.decisionsFor('pc:eject-vote');
    expect(decisions.map((d) => d.participantId), ['$planId:p1']);
    final row = await svc.getById('pc:eject-vote');
    expect(row?.status, HousingParticipationChangeStatus.pending.wireValue);
  });

  test('allDecidersHaveAccepted is true when every active decider accepted', () async {
    final db = await _threeParticipantPlanAfterEjection();
    addTearDown(db.close);

    const planId = 'housing:post-eject';
    const changeId = 'pc:eject-all';
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: '$planId:p1',
        targetParticipantId: const drift.Value('$planId:p2'),
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

  test('voluntary withdrawal deciders are active peers excluding initiator', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-deciders';
    const louysId = '$planId:p1';
    const monicaId = '$planId:self';
    const changeId = 'pc:withdraw-deciders';

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
        departureDate: drift.Value(DateTime.utc(2026, 6, 13)),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );

    final svc = HousingParticipationChangeService(db);
    final change = await svc.getById(changeId);
    final deciders = await svc.deciderParticipantsFor(change!);
    expect(deciders.map((p) => p.id), [monicaId]);
  });

  test('voluntary withdrawal does not apply before peer acknowledgements', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-wait-ack';
    const louysId = '$planId:p1';
    const monicaId = '$planId:self';
    const changeId = 'pc:withdraw-wait-ack';
    final today = DateTime.now().toUtc();
    final futureDeparture = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 30));

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: today,
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
          createdAt: today,
        ),
      );
    }
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: 'pkg:$planId',
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: today,
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
        departureDate: drift.Value(futureDeparture),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: today,
      ),
    );

    final svc = HousingParticipationChangeService(db);
    expect(await svc.applyDueVoluntaryWithdrawalsReturningId(planId), isNull);
    expect(
      (await svc.getById(changeId))?.status,
      HousingParticipationChangeStatus.pending.wireValue,
    );

    await svc.recordAcknowledgement(
      changeId: changeId,
      participantId: monicaId,
    );
    expect(await svc.applyDueVoluntaryWithdrawalsReturningId(planId), isNull);
    expect(
      (await svc.getById(changeId))?.status,
      HousingParticipationChangeStatus.pending.wireValue,
    );
  });

  test('voluntary withdrawal applies on departure date after all acks', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-apply';
    const louysId = '$planId:p1';
    const monicaId = '$planId:self';
    const changeId = 'pc:withdraw-apply';
    final departure = DateTime.utc(2026, 6, 1);

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: departure,
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
          createdAt: departure,
        ),
      );
    }
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: 'pkg:$planId',
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: departure,
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
        departureDate: drift.Value(departure),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: departure,
      ),
    );

    final svc = HousingParticipationChangeService(db);
    await svc.recordAcknowledgement(
      changeId: changeId,
      participantId: monicaId,
    );
    expect(
      (await svc.getById(changeId))?.status,
      HousingParticipationChangeStatus.effective.wireValue,
    );
    expect(await svc.membershipService.isActiveMember(planId, louysId), isFalse);
    expect(await svc.applyDueVoluntaryWithdrawalsReturningId(planId), isNull);
  });

  test('voluntary withdrawal defaults missing acks after five calendar days', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-default-ack';
    const louysId = '$planId:p1';
    const monicaId = '$planId:self';
    const changeId = 'pc:withdraw-default-ack';
    final notice = DateTime.utc(2026, 6, 1, 12);

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: notice,
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
          createdAt: notice,
        ),
      );
    }
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: 'pkg:$planId',
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: notice,
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
        departureDate: drift.Value(DateTime.utc(2026, 6, 1)),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: notice,
      ),
    );

    final svc = HousingParticipationChangeService(db);
    final change = await svc.getById(changeId);
    expect(change, isNotNull);
    expect(
      voluntaryWithdrawalAckExpiryApplies(
        noticeLocal: voluntaryWithdrawalNoticeDateLocal(notice),
        now: DateTime(2026, 6, 7),
      ),
      isTrue,
    );

    expect(await svc.applyDueVoluntaryWithdrawalsReturningId(planId), changeId);
    final decisions = await svc.decisionsFor(changeId);
    expect(
      decisions.where((d) => d.participantId == monicaId).single.status,
      HousingParticipationDecisionStatus.accepted.wireValue,
    );
  });

  test('voluntary withdrawal ignores reject decisions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:withdraw-no-reject';
    const louysId = '$planId:p1';
    const monicaId = '$planId:self';
    const changeId = 'pc:withdraw-no-reject';

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
        departureDate: drift.Value(DateTime.utc(2026, 6, 13)),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 13),
      ),
    );

    final svc = HousingParticipationChangeService(db);
    await svc.recordDecision(
      changeId: changeId,
      participantId: monicaId,
      accepted: false,
    );
    expect(await svc.decisionsFor(changeId), isEmpty);
  });
}
