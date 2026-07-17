import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_plan_peer_contacts.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedContact({
    required String id,
    required String displayName,
    String? peerPublicMaterial,
    String avatarId = 'a01',
  }) async {
    await db.upsertContact(
      ContactsCompanion.insert(
        id: id,
        kind: peerPublicMaterial == null ? 'local-only' : 'connected',
        displayName: displayName,
        avatarId: avatarId,
        peerPublicMaterial: peerPublicMaterial == null
            ? const drift.Value.absent()
            : drift.Value(peerPublicMaterial),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }

  test('listMissingPlanPeerContacts excludes self and connected peers', () async {
    const planId = 'plan:test';
    await seedContact(
      id: 'contact:a',
      displayName: 'Monica',
      peerPublicMaterial: 'peer-a',
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Me',
        avatarId: 'a01',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Monica',
        avatarId: 'a01',
        contactId: const drift.Value('contact:a'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Third participant',
        avatarId: 'a02',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final missing = await listMissingPlanPeerContacts(db: db, planId: planId);

    expect(missing, hasLength(1));
    expect(missing.single.displayName, 'Third participant');
  });

  test('listPlanPeerContactRows marks connected and missing peers', () async {
    const planId = 'plan:rows';
    await seedContact(
      id: 'contact:a',
      displayName: 'Monica',
      peerPublicMaterial: 'peer-a',
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Monica',
        avatarId: 'a01',
        contactId: const drift.Value('contact:a'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Ròberr',
        avatarId: 'a02',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final rows = await listPlanPeerContactRows(db: db, planId: planId);

    expect(rows, hasLength(2));
    expect(rows[0].participant.displayName, 'Monica');
    expect(rows[0].isConnected, isTrue);
    expect(rows[1].participant.displayName, 'Ròberr');
    expect(rows[1].isConnected, isFalse);
  });

  test('relayReachableContactForParticipant matches name without contactId', () async {
    await seedContact(
      id: 'contact:c',
      displayName: 'Ròberr',
      peerPublicMaterial: 'peer-c',
      avatarId: 'a03',
    );
    final contacts = await db.listContacts();
    final participant = Participant(
      id: 'plan:x:p2',
      displayName: 'Ròberr',
      avatarId: 'a03',
      contactId: null,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final matched = relayReachableContactForParticipant(participant, contacts);

    expect(matched?.id, 'contact:c');
  });

  test(
    'relayContactsForActivePlanMembers excludes departed roster contacts only',
    () async {
      const planId = 'plan:term';
      const ejectedId = '$planId:p2';
      await seedContact(
        id: 'contact:louys',
        displayName: 'Louys',
        peerPublicMaterial: 'peer-l',
      );
      await seedContact(
        id: 'contact:roberr',
        displayName: 'Roberr',
        peerPublicMaterial: 'peer-r',
      );
      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      for (final entry in [
        ('$planId:self', 'Monica', 'contact:monica'),
        ('$planId:p1', 'Louys', 'contact:louys'),
        (ejectedId, 'Roberr', 'contact:roberr'),
      ]) {
        await db.upsertParticipant(
          ParticipantsCompanion.insert(
            id: entry.$1,
            displayName: entry.$2,
            avatarId: 'a',
            contactId: drift.Value(entry.$3),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
      }

      final membership = HousingParticipationMembershipService(db);
      await membership.ensureMembershipsForPlan(planId);
      await membership.markDeparted(
        planId: planId,
        participantId: ejectedId,
        departureKind: HousingParticipationChangeKind.ejection,
        changeId: 'pc:1',
      );

      final reachable = (await db.listContacts())
          .where(isRelayReachableContact)
          .toList();
      final targets = await relayContactsForActivePlanMembers(
        db: db,
        planId: planId,
        relayReachableContacts: reachable,
      );

      expect(targets.map((c) => c.id), ['contact:louys']);
    },
  );

  test(
    'housingProposalDeliveryTargets uses bound contact only (no avatar fan-out)',
    () async {
      await seedContact(
        id: 'contact:leo',
        displayName: 'Leo',
        peerPublicMaterial: 'peer-leo',
        avatarId: 'mdi:7',
      );
      await seedContact(
        id: 'contact:roberr',
        displayName: 'Ròberr',
        peerPublicMaterial: 'peer-roberr',
        avatarId: 'mdi:7',
      );
      final contacts = await db.listContacts();
      final leo = contacts.firstWhere((c) => c.id == 'contact:leo');
      final reachable = contacts.where(isRelayReachableContact).toList();

      const planId = 'plan:avatar-collision';
      final participant = Participant(
        id: '$planId:p0',
        displayName: 'Leo',
        avatarId: 'mdi:7',
        contactId: 'contact:leo',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final targets = housingProposalDeliveryTargets(
        participant: participant,
        selectedContact: leo,
        relayReachableContacts: reachable,
      );

      expect(targets.map((c) => c.id), ['contact:leo']);
    },
  );

  test(
    'housingProposalDeliveryTargets refuses ambiguous avatar-only matches',
    () async {
      await seedContact(
        id: 'contact:leo',
        displayName: 'Leo',
        peerPublicMaterial: 'peer-leo',
        avatarId: 'mdi:7',
      );
      await seedContact(
        id: 'contact:roberr',
        displayName: 'Ròberr',
        peerPublicMaterial: 'peer-roberr',
        avatarId: 'mdi:7',
      );
      final reachable = (await db.listContacts())
          .where(isRelayReachableContact)
          .toList();

      const planId = 'plan:avatar-collision';
      final participant = Participant(
        id: '$planId:p0',
        displayName: 'Leo',
        avatarId: 'mdi:7',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final targets = housingProposalDeliveryTargets(
        participant: participant,
        selectedContact: null,
        relayReachableContacts: reachable,
      );

      // Name still unique for Leo — prefer name over ambiguous avatar.
      expect(targets.map((c) => c.id), ['contact:leo']);

      final nameless = Participant(
        id: '$planId:p1',
        displayName: '',
        avatarId: 'mdi:7',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final ambiguous = housingProposalDeliveryTargets(
        participant: nameless,
        selectedContact: null,
        relayReachableContacts: reachable,
      );
      expect(ambiguous, isEmpty);
    },
  );
}
