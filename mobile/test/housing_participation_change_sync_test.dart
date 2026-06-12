import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_sync_service.dart';
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
}
