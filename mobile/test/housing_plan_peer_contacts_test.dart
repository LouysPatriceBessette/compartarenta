import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_plan_peer_contacts.dart';
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
}
