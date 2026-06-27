import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' as drift;
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

  test('activeParticipantCount excludes uncleared inactive ghost without departed row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:inactive-ghost';
    const ghostId = '$planId:p2';

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
      (ghostId, 'Roberr'),
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

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);

    await db.into(db.housingInactiveParticipants).insert(
      HousingInactiveParticipantsCompanion.insert(
        id: 'inactive:$planId:1',
        planId: planId,
        sourceParticipantId: ghostId,
        displayNameSnapshot: 'Roberr',
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );

    expect(await svc.isActiveMember(planId, ghostId), isFalse);
    expect(await svc.activeParticipantCount(planId), 2);
    final active = await svc.activeParticipantsForPlan(planId);
    expect(active.map((p) => p.displayName), ['Monica', 'Louys']);
  });

  test('activeParticipantCount is two after ejection from three', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:three-to-two';
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

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);
    await svc.markDeparted(
      planId: planId,
      participantId: ejectedId,
      departureKind: HousingParticipationChangeKind.ejection,
      changeId: 'pc:eject',
    );

    expect(await svc.activeParticipantCount(planId), 2);
  });

  test('hubTitleParts uses past title when agreement period has ended', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:hub-title-period-end';
    const selfId = '$planId:self';
    const activeTitle = 'Entente active';
    const pastTitle = 'Entente passée';
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2027, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Monica',
        avatarId: 'a',
        createdAt: DateTime.utc(2027, 1, 1),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agr:$planId',
        planId: planId,
        periodStart: DateTime.utc(2027, 1, 1, 12),
        periodEnd: DateTime.utc(2027, 8, 10, 12),
        minNoticeDays: const drift.Value(0),
        penaltyMinor: const drift.Value(0),
        clauses: const drift.Value(''),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        agreementRulesJson: const drift.Value('{}'),
        version: const drift.Value(1),
        createdAt: DateTime.utc(2027, 1, 1, 12),
      ),
    );

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);

    final afterEnd = await svc.hubTitleParts(
      planId: planId,
      selfParticipantId: selfId,
      activeHubTitleL10n: activeTitle,
      pastHubTitleL10n: pastTitle,
      formatDate: fmt,
      now: DateTime.utc(2027, 8, 11, 12),
    );
    expect(afterEnd.titlePrefix, pastTitle);
    expect(afterEnd.periodRange, '2027-01-01 - 2027-08-10');

    final duringPeriod = await svc.hubTitleParts(
      planId: planId,
      selfParticipantId: selfId,
      activeHubTitleL10n: activeTitle,
      pastHubTitleL10n: pastTitle,
      formatDate: fmt,
      now: DateTime.utc(2027, 6, 1, 12),
    );
    expect(duringPeriod.titlePrefix, activeTitle);
    expect(duringPeriod.periodRange, '2027-01-01 - 2027-08-10');
  });

  test('hubTitleParts uses past title with departure date for departed member', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:hub-title-departed';
    const selfId = '$planId:self';
    const activeTitle = 'Entente active';
    const pastTitle = 'Entente passée';
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2027, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Monica',
        avatarId: 'a',
        createdAt: DateTime.utc(2027, 1, 1),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agr:$planId',
        planId: planId,
        periodStart: DateTime.utc(2027, 1, 1, 12),
        periodEnd: DateTime.utc(2027, 12, 31, 12),
        minNoticeDays: const drift.Value(0),
        penaltyMinor: const drift.Value(0),
        clauses: const drift.Value(''),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        agreementRulesJson: const drift.Value('{}'),
        version: const drift.Value(1),
        createdAt: DateTime.utc(2027, 1, 1, 12),
      ),
    );

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);
    await svc.markDeparted(
      planId: planId,
      participantId: selfId,
      departureKind: HousingParticipationChangeKind.voluntaryWithdrawal,
      changeId: 'pc:1',
      departedAt: DateTime.utc(2027, 6, 15, 12),
    );

    final parts = await svc.hubTitleParts(
      planId: planId,
      selfParticipantId: selfId,
      activeHubTitleL10n: activeTitle,
      pastHubTitleL10n: pastTitle,
      formatDate: fmt,
      now: DateTime.utc(2027, 7, 1, 12),
    );
    expect(parts.titlePrefix, pastTitle);
    expect(parts.periodRange, '2027-01-01 - 2027-06-15');
  });

  test('reconcileEffectiveDepartures repairs effective ejection without departed row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:reconcile';
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

    final svc = HousingParticipationMembershipService(db);
    await svc.ensureMembershipsForPlan(planId);

    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: 'pc:effective-gap',
        planId: planId,
        packageId: 'pkg:$planId',
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: '$planId:p1',
        targetParticipantId: drift.Value(ejectedId),
        status: HousingParticipationChangeStatus.effective.wireValue,
        createdAt: DateTime.utc(2026, 6, 4),
      ),
    );

    expect(await svc.isActiveMember(planId, ejectedId), isTrue);
    await svc.reconcileEffectiveDepartures(planId);
    expect(await svc.isActiveMember(planId, ejectedId), isFalse);
    expect(await svc.activeParticipantCount(planId), 2);
  });
}
