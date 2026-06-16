import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_plan_peer_identity_reconcile.dart';
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

  test('reconcilePlanMediatedPeerIdentity updates participant and snapshots', () async {
    const planId = 'received:test';
    const participantId = '$planId:p1';
    const peerB64 = 'peer-key-b64';
    const revisionId = 'rev:$planId:1';
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: participantId,
        displayName: 'Old Bob',
        avatarId: 'a02',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlanPeerEstablishment(
      PlanPeerEstablishmentsCompanion.insert(
        id: '$planId:p1',
        planId: planId,
        participantId: participantId,
        peerPublicMaterialB64: peerB64,
        peerDisplayName: 'Old Bob',
        peerAvatarId: 'a02',
        proposerDisplayName: 'Monica',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId',
            planId: planId,
            pendingRevisionId: const drift.Value(revisionId),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.proposalRevisions).insert(
          ProposalRevisionsCompanion.insert(
            id: revisionId,
            packageId: 'pkg:$planId',
            contentHash: 'hash',
            proposerParticipantId: '$planId:self',
            payloadJson: jsonEncode({
              'lifecycleState': 'open',
              'participantSnapshots': [
                {
                  'id': 'source:p1',
                  'displayName': 'Old Bob',
                  'avatarId': 'a02',
                  'peerPublicMaterialB64': peerB64,
                },
              ],
            }),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    await reconcilePlanMediatedPeerIdentity(
      db: db,
      peerPublicMaterialB64: peerB64,
      displayName: 'New Bob',
      avatarId: 'a02',
      planId: planId,
      participantId: participantId,
    );

    final participant = await (db.select(db.participants)
          ..where((t) => t.id.equals(participantId)))
        .getSingle();
    expect(participant.displayName, 'New Bob');

    final establishment = await db.getPlanPeerEstablishment('$planId:p1');
    expect(establishment?.peerDisplayName, 'New Bob');

    final rev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingle();
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    final snaps = payload['participantSnapshots'] as List;
    expect(snaps.single['displayName'], 'New Bob');
  });

  test('planMediatedPeerNameMismatch detects case-insensitive drift', () {
    expect(
      planMediatedPeerNameMismatch(
        storedName: 'Bob',
        incomingName: 'bob',
      ),
      isFalse,
    );
    expect(
      planMediatedPeerNameMismatch(
        storedName: 'Bob',
        incomingName: 'Robert',
      ),
      isTrue,
    );
  });
}
