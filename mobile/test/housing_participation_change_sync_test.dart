import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_inactive_participant_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_sync_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('importProposeFromPeer remaps initiator and target participant ids', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'plan-h1';
    const selfId = '$planId:self';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Roberr',
        avatarId: 'av-r',
        contactId: const drift.Value('contact:roberr'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Louys',
        avatarId: 'av-l',
        contactId: const drift.Value('contact:louys'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p2',
        displayName: 'Monica',
        avatarId: 'av-m',
        contactId: const drift.Value('contact:monica'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    const changeId = 'change-eject-1';
    final json = '''
{
  "change_id": "$changeId",
  "package_id": "pkg-1",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$planId:self",
  "target_participant_id": "$planId:p2",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "contact:louys"},
    {"id": "$planId:p2", "displayName": "Roberr", "contactId": "contact:roberr"}
  ]
}
''';

    final svc = HousingParticipationChangeSyncService(db);
    final imported = await svc.importProposeFromPeer(
      changeJson: json,
      senderContactId: 'contact:louys',
    );
    expect(imported, isTrue);

    final row = await (db.select(db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingle();
    expect(row.initiatorParticipantId, '$planId:p1');
    expect(row.targetParticipantId, selfId);
    expect(row.kind, HousingParticipationChangeKind.ejection.wireValue);
  });

  test('importProposeFromPeer does not map sender :self to local :self', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'plan-h1b';
    const selfId = '$planId:self';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Roberr',
        avatarId: 'av-r',
        contactId: const drift.Value('contact:roberr'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p2',
        displayName: 'Louys',
        avatarId: 'av-l',
        contactId: const drift.Value('contact:louys'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    const changeId = 'change-eject-self-fallback';
    final json = '''
{
  "change_id": "$changeId",
  "package_id": "pkg-1",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$planId:self",
  "target_participant_id": "$planId:p2",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:p2", "displayName": "Roberr", "contactId": "contact:roberr"}
  ]
}
''';

    final svc = HousingParticipationChangeSyncService(db);
    expect(
      await svc.importProposeFromPeer(
        changeJson: json,
        senderContactId: 'contact:louys',
      ),
      isTrue,
    );

    final row = await (db.select(db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingle();
    expect(row.initiatorParticipantId, '$planId:p2');
    expect(row.initiatorParticipantId, isNot(selfId));
    expect(row.targetParticipantId, selfId);
  });

  test('importProposeFromPeer updates remapped ids on duplicate delivery', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'plan-h2';
    const selfId = '$planId:self';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Roberr',
        avatarId: 'av-r',
        contactId: const drift.Value('contact:roberr'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Louys',
        avatarId: 'av-l',
        contactId: const drift.Value('contact:louys'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    const changeId = 'change-eject-2';
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: 'pkg-1',
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: selfId,
        targetParticipantId: drift.Value('$planId:p2'),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026, 6, 4),
      ),
    );

    final json = '''
{
  "change_id": "$changeId",
  "package_id": "pkg-1",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$planId:self",
  "target_participant_id": "$planId:p3",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "contact:louys"},
    {"id": "$planId:p3", "displayName": "Roberr", "contactId": "contact:roberr"}
  ]
}
''';

    final svc = HousingParticipationChangeSyncService(db);
    expect(
      await svc.importProposeFromPeer(
        changeJson: json,
        senderContactId: 'contact:louys',
      ),
      isTrue,
    );

    final row = await (db.select(db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingle();
    expect(row.initiatorParticipantId, '$planId:p1');
    expect(row.targetParticipantId, selfId);
  });

  test(
    'importProposeFromPeer maps ejection on decider device when target lacks contactId',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'plan-h3';
      const selfId = '$planId:self';
      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: selfId,
          displayName: 'Monica',
          avatarId: 'av-m',
          contactId: const drift.Value('contact:monica'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$planId:p1',
          displayName: 'Louys',
          avatarId: 'av-l',
          contactId: const drift.Value('contact:louys'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$planId:p2',
          displayName: 'Roberr',
          avatarId: 'av-r',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      const changeId = 'change-eject-monica';
      final json = '''
{
  "change_id": "$changeId",
  "package_id": "pkg-1",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$planId:self",
  "target_participant_id": "$planId:p2",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "contact:louys", "avatarId": "av-l"},
    {"id": "$planId:p1", "displayName": "Monica", "avatarId": "av-m"},
    {"id": "$planId:p2", "displayName": "Roberr", "avatarId": "av-r"}
  ]
}
''';

      final svc = HousingParticipationChangeSyncService(db);
      expect(
        await svc.importProposeFromPeer(
          changeJson: json,
          senderContactId: 'contact:louys',
        ),
        isTrue,
      );

      final row = await (db.select(db.housingParticipationChanges)
            ..where((t) => t.id.equals(changeId)))
          .getSingle();
      expect(row.initiatorParticipantId, '$planId:p1');
      expect(row.targetParticipantId, '$planId:p2');
      expect(row.kind, HousingParticipationChangeKind.ejection.wireValue);
    },
  );

  test(
    'importProposeFromPeer resolves received plan id on author device',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const localPlanId = 'housing:default';
      const localPackageId = 'pkg:housing:default';
      const remotePlanId = 'received:abc';
      const remotePackageId = 'pkg:received:abc';
      const louysContact = 'contact:handshake:louys';

      await db.upsertPlan(
        PlansCompanion.insert(
          id: localPlanId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$localPlanId:self',
          displayName: 'Monica',
          avatarId: 'av-m',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$localPlanId:p0',
          displayName: 'Louys',
          avatarId: 'av-l',
          contactId: const drift.Value(louysContact),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$localPlanId:p1',
          displayName: 'Roberr',
          avatarId: 'av-r',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: localPackageId,
          planId: localPlanId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      const changeId = 'change-eject-author';
      final json = '''
{
  "change_id": "$changeId",
  "package_id": "$remotePackageId",
  "plan_id": "$remotePlanId",
  "kind": "ejection",
  "initiator_participant_id": "$remotePlanId:self",
  "target_participant_id": "$remotePlanId:p1",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$remotePlanId:self", "displayName": "Louys", "contactId": "$louysContact", "avatarId": "av-l"},
    {"id": "$remotePlanId:p0", "displayName": "Monica", "avatarId": "av-m"},
    {"id": "$remotePlanId:p1", "displayName": "Roberr", "avatarId": "av-r"}
  ]
}
''';

      final svc = HousingParticipationChangeSyncService(db);
      expect(
        await svc.importProposeFromPeer(
          changeJson: json,
          senderContactId: louysContact,
        ),
        isTrue,
      );

      final row = await (db.select(db.housingParticipationChanges)
            ..where((t) => t.id.equals(changeId)))
          .getSingle();
      expect(row.planId, localPlanId);
      expect(row.packageId, localPackageId);
      expect(row.initiatorParticipantId, '$localPlanId:p0');
      expect(row.targetParticipantId, '$localPlanId:p1');
      expect(row.kind, HousingParticipationChangeKind.ejection.wireValue);
    },
  );

  test(
    'importProposeFromPeer applies effective side effects on notify replay',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'received:roberr';
      const packageId = 'pkg:received:roberr';
      const roberrSelf = '$planId:self';
      const louysId = '$planId:p0';
      const monicaId = '$planId:p1';

      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      for (final entry in [
        (monicaId, 'Monica'),
        (louysId, 'Louys'),
        (roberrSelf, 'Roberr'),
      ]) {
        await db.upsertParticipant(
          ParticipantsCompanion.insert(
            id: entry.$1,
            displayName: entry.$2,
            avatarId: 'av',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
      }
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: packageId,
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      const changeId = 'change-eject-notify';
      const pendingJson = '''
{
  "change_id": "$changeId",
  "package_id": "$packageId",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$louysId",
  "target_participant_id": "$roberrSelf",
  "status": "pending",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$monicaId", "displayName": "Monica"},
    {"id": "$louysId", "displayName": "Louys"},
    {"id": "$roberrSelf", "displayName": "Roberr"}
  ]
}
''';
      const effectiveJson = '''
{
  "change_id": "$changeId",
  "package_id": "$packageId",
  "plan_id": "$planId",
  "kind": "ejection",
  "initiator_participant_id": "$louysId",
  "target_participant_id": "$roberrSelf",
  "status": "effective",
  "created_at": "2026-06-04T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$monicaId", "displayName": "Monica"},
    {"id": "$louysId", "displayName": "Louys"},
    {"id": "$roberrSelf", "displayName": "Roberr"}
  ]
}
''';

      final svc = HousingParticipationChangeSyncService(db);
      expect(
        await svc.importProposeFromPeer(
          changeJson: pendingJson,
          senderContactId: 'contact:louys',
        ),
        isTrue,
      );
      expect(
        await svc.importNotifyFromPeer(
          notifyJson: effectiveJson,
          senderContactId: 'contact:louys',
        ),
        isTrue,
      );

      final row = await (db.select(db.housingParticipationChanges)
            ..where((t) => t.id.equals(changeId)))
          .getSingle();
      expect(row.status, HousingParticipationChangeStatus.effective.wireValue);

      final membership = await (db.select(db.housingPlanMemberships)
            ..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.participantId.equals(roberrSelf),
            ))
          .getSingle();
      expect(membership.status, HousingPlanMembershipStatus.departed.wireValue);

      final inactive = await HousingInactiveParticipantService(db).listUncleared(
        planId,
      );
      expect(inactive, hasLength(1));
      expect(inactive.single.sourceParticipantId, roberrSelf);
    },
  );

  test(
    'applyEffectiveFromPeerNotify applies side effects when row is already effective',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'housing:author';
      const ejectedId = '$planId:p2';
      const changeId = 'pc:effective-only';

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
            avatarId: 'av',
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

      await HousingParticipationMembershipService(db).ensureMembershipsForPlan(
        planId,
      );
      await db.into(db.housingParticipationChanges).insert(
        HousingParticipationChangesCompanion.insert(
          id: changeId,
          planId: planId,
          packageId: 'pkg:$planId',
          kind: HousingParticipationChangeKind.ejection.wireValue,
          initiatorParticipantId: '$planId:p1',
          targetParticipantId: drift.Value(ejectedId),
          status: HousingParticipationChangeStatus.effective.wireValue,
          createdAt: DateTime.utc(2026, 6, 4),
        ),
      );

      final membership = HousingParticipationMembershipService(db);
      expect(await membership.isActiveMember(planId, ejectedId), isTrue);

      await HousingParticipationChangeService(db).applyEffectiveFromPeerNotify(
        changeId,
      );

      expect(await membership.isActiveMember(planId, ejectedId), isFalse);
      expect(await membership.activeParticipantCount(planId), 2);
    },
  );

  test(
    'importDecisionFromPeer maps sender :self and settles pending termination',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'plan:term-decision';
      const louysId = '$planId:self';
      const monicaId = '$planId:p1';
      const changeId = 'pc:term-decision';

      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: louysId,
          displayName: 'Louys',
          avatarId: 'av-l',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: monicaId,
          displayName: 'Monica',
          avatarId: 'av-m',
          contactId: const drift.Value('contact:monica'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:$planId',
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026, 1, 1),
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
          kind: HousingParticipationChangeKind.immediateTermination.wireValue,
          initiatorParticipantId: louysId,
          status: HousingParticipationChangeStatus.pending.wireValue,
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );
      await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
        HousingParticipationDecisionsCompanion.insert(
          changeId: changeId,
          participantId: louysId,
          status: HousingParticipationDecisionStatus.accepted.wireValue,
          decidedAt: drift.Value(DateTime.utc(2026, 6, 13)),
        ),
      );

      final decisionJson = '''
{
  "change_id": "$changeId",
  "participant_id": "$planId:self",
  "status": "accepted",
  "decided_at": "2026-06-13T12:00:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Monica", "contactId": "contact:monica"}
  ]
}
''';

      final imported = await HousingParticipationChangeSyncService(
        db,
      ).importDecisionFromPeer(
        decisionJson: decisionJson,
        senderContactId: 'contact:monica',
      );
      expect(imported, isTrue);

      final decisions =
          await HousingParticipationChangeService(db).decisionsFor(changeId);
      expect(
        decisions.map((d) => d.participantId).toSet(),
        {louysId, monicaId},
      );
      final row = await HousingParticipationChangeService(db).getById(changeId);
      expect(row?.status, HousingParticipationChangeStatus.effective.wireValue);
    },
  );

  test(
    'importDecisionFromPeer records vote after effective notify won the race',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'plan:term-race';
      const louysId = '$planId:self';
      const monicaId = '$planId:p1';
      const changeId = 'pc:term-race';

      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: louysId,
          displayName: 'Louys',
          avatarId: 'av-l',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: monicaId,
          displayName: 'Monica',
          avatarId: 'av-m',
          contactId: const drift.Value('contact:monica'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:$planId',
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026, 1, 1),
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
          kind: HousingParticipationChangeKind.immediateTermination.wireValue,
          initiatorParticipantId: louysId,
          status: HousingParticipationChangeStatus.effective.wireValue,
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );
      await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
        HousingParticipationDecisionsCompanion.insert(
          changeId: changeId,
          participantId: louysId,
          status: HousingParticipationDecisionStatus.accepted.wireValue,
          decidedAt: drift.Value(DateTime.utc(2026, 6, 13)),
        ),
      );

      final decisionJson = '''
{
  "change_id": "$changeId",
  "participant_id": "$planId:self",
  "status": "accepted",
  "decided_at": "2026-06-13T12:01:00.000Z",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Monica", "contactId": "contact:monica"}
  ]
}
''';

      expect(
        await HousingParticipationChangeSyncService(db).importDecisionFromPeer(
          decisionJson: decisionJson,
          senderContactId: 'contact:monica',
        ),
        isTrue,
      );

      final decisions =
          await HousingParticipationChangeService(db).decisionsFor(changeId);
      expect(decisions.any((d) => d.participantId == monicaId), isTrue);
    },
  );
}
