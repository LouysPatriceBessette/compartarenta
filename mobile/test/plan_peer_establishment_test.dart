import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/housing/plan_peer_establishment_service.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/relay/envelopes.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/routing.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

class _FakeContactNotificationSink implements ContactNotificationSink {
  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {}

  @override
  Future<void> contactAddedViaInvitation({required String displayName}) async {}

  @override
  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  }) async {}

  @override
  Future<void> contactAddRequestFailed({required String errorCode}) async {}

  @override
  Future<void> contactDisconnected({required String displayName}) async {}

  @override
  Future<void> planPeerEstablishmentRequestReceived({
    required String requesterDisplayName,
    required String proposerDisplayName,
    required String planId,
  }) async {}
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
  });

  test('exportProposalForParticipant includes peerPublicMaterialB64', () async {
    final dbFile = File(
      '${Directory.systemTemp.path}/plan_est_export_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final db = _DbForTesting(NativeDatabase(dbFile));
    addTearDown(() async {
      await db.close();
      if (dbFile.existsSync()) dbFile.deleteSync();
    });

    final planId = 'plan:test';
    final peerSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final peerPub = await InMemoryIdentityKeystore(seed: peerSeed).publicKey();
    final peerB64 = RelayRouting.b64(peerPub);

    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Monica',
        avatarId: 'a01',
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Louys',
        avatarId: 'a02',
        contactId: const Value('contact:louys'),
        createdAt: DateTime.utc(2026),
      ),
    );
    await ContactsRepository(db).upsertLocalOnly(
      id: 'contact:louys',
      displayName: 'Louys',
      avatarId: 'a02',
    );
    await ContactsRepository(db).promoteToConnected(
      id: 'contact:louys',
      relayRoutingIdB64: 'route-louys',
      peerPublicMaterialB64: peerB64,
    );

    final packageId = 'pkg:$planId';
    final revisionId = 'rev:$planId:1';
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: packageId,
            planId: planId,
            createdAt: DateTime.utc(2026),
          ),
        );
    await db.into(db.proposalRevisions).insert(
          ProposalRevisionsCompanion.insert(
            id: revisionId,
            packageId: packageId,
            contentHash: 'hash',
            proposerParticipantId: '$planId:self',
            payloadJson: jsonEncode({
              'packageId': packageId,
              'revisionId': revisionId,
              'proposerParticipantId': '$planId:self',
              'plan': {'type': 'housing', 'title': 'Test', 'lines': []},
            }),
            createdAt: DateTime.utc(2026),
          ),
        );

    final exported = await HousingProposalTransportService(db)
        .exportProposalForParticipant(
          planId: planId,
          revisionId: revisionId,
          targetParticipantId: '$planId:p1',
        );
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    final snapshots = decoded['participantSnapshots'] as List;
    final louysSnap = snapshots.cast<Map>().firstWhere(
          (s) => s['displayName'] == 'Louys',
        );
    expect(louysSnap['peerPublicMaterialB64'], peerB64);
  });

  test('import builds watch list and accept promotes requester contact', () async {
    final relay = FakeRelayClient();
    final louysSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 10));
    final roberrSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 20));
    final louysPub = await InMemoryIdentityKeystore(seed: louysSeed).publicKey();
    final roberrPub = await InMemoryIdentityKeystore(seed: roberrSeed).publicKey();

    final louysDbFile = File(
      '${Directory.systemTemp.path}/plan_est_louys_import_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final louysDb = _DbForTesting(NativeDatabase(louysDbFile));
    addTearDown(() async {
      await louysDb.close();
      if (louysDbFile.existsSync()) louysDbFile.deleteSync();
    });

    final monicaContactId = 'contact:monica';
    await ContactsRepository(louysDb).upsertLocalOnly(
      id: monicaContactId,
      displayName: 'Monica',
      avatarId: 'a01',
    );
    await ContactsRepository(louysDb).promoteToConnected(
      id: monicaContactId,
      relayRoutingIdB64: 'route-monica',
      peerPublicMaterialB64: RelayRouting.b64(
        await InMemoryIdentityKeystore(seed: Uint8List(32)).publicKey(),
      ),
    );

    final proposalJson = jsonEncode({
      'packageId': 'pkg:source',
      'revisionId': 'rev:source:1',
      'proposerParticipantId': 'monica:self',
      'targetParticipantId': 'monica:louys',
      'participantSnapshots': [
        {
          'id': 'monica:self',
          'displayName': 'Monica',
          'avatarId': 'a01',
        },
        {
          'id': 'monica:louys',
          'displayName': 'Louys',
          'avatarId': 'a02',
          'peerPublicMaterialB64': RelayRouting.b64(louysPub),
        },
        {
          'id': 'monica:roberr',
          'displayName': 'Roberr',
          'avatarId': 'a03',
          'peerPublicMaterialB64': RelayRouting.b64(roberrPub),
        },
      ],
      'plan': {
        'type': 'housing',
        'title': 'Flat',
        'defaultCurrency': 'EUR',
        'lines': [],
        'ratios': [],
      },
    });

    await HousingProposalTransportService(louysDb).importReceivedProposal(
      proposalJson: proposalJson,
      targetParticipantId: 'monica:louys',
      senderContactId: monicaContactId,
      senderDisplayName: 'Monica',
      senderAvatarId: 'a01',
    );

    final planId = (await louysDb.listPlans()).single.id;
    final rows = await PlanPeerEstablishmentService(louysDb).listForPlan(planId);
    expect(rows, hasLength(1));
    expect(rows.single.peerDisplayName, 'Roberr');

    final roberrDbFile = File(
      '${Directory.systemTemp.path}/plan_est_roberr_import_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final roberrDb = _DbForTesting(NativeDatabase(roberrDbFile));
    addTearDown(() async {
      await roberrDb.close();
      if (roberrDbFile.existsSync()) roberrDbFile.deleteSync();
    });

    await HousingProposalTransportService(roberrDb).importReceivedProposal(
      proposalJson: proposalJson,
      targetParticipantId: 'monica:roberr',
      senderContactId: 'contact:monica-r',
      senderDisplayName: 'Monica',
      senderAvatarId: 'a01',
    );
    final roberrPlanId = (await roberrDb.listPlans()).single.id;

    final louysOrch = HandshakeOrchestrator(
      db: louysDb,
      identity: InMemoryIdentityKeystore(seed: louysSeed),
      relay: relay,
      contacts: ContactsRepository(louysDb),
      invitations: ContactInvitationsRepository(louysDb),
      contactNotifications: _FakeContactNotificationSink(),
    );

    await louysOrch.sendPlanPeerEstablishmentRequest(
      planId: planId,
      participantId: rows.single.participantId,
    );

    final roberrOrch = HandshakeOrchestrator(
      db: roberrDb,
      identity: InMemoryIdentityKeystore(seed: roberrSeed),
      relay: relay,
      contacts: ContactsRepository(roberrDb),
      invitations: ContactInvitationsRepository(roberrDb),
      contactNotifications: _FakeContactNotificationSink(),
    );
    await roberrOrch.pollSteadyStateInboxes();

    final louysRow = await PlanPeerEstablishmentService(roberrDb)
        .listForPlan(roberrPlanId);
    final inbound = louysRow.singleWhere(
      (r) => r.inboundPendingAt != null,
      orElse: () => throw StateError('no inbound pending'),
    );
    await roberrOrch.respondPlanPeerEstablishmentRequest(
      establishmentId: inbound.id,
      accepted: true,
    );

    await louysOrch.pollSteadyStateInboxes();

    final louysContacts = await ContactsRepository(louysDb).list();
    expect(
      louysContacts.any(
        (c) =>
            c.kind == 'connected' &&
            c.peerPublicMaterial == RelayRouting.b64(roberrPub),
      ),
      isTrue,
    );
  });

  test('refuse response records refusedAt on requester row', () async {
    final relay = FakeRelayClient();
    final requesterSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 30));
    final targetSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 40));
    final requesterPub =
        await InMemoryIdentityKeystore(seed: requesterSeed).publicKey();
    final targetPub = await InMemoryIdentityKeystore(seed: targetSeed).publicKey();

    final dbFile = File(
      '${Directory.systemTemp.path}/plan_est_refuse_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final db = _DbForTesting(NativeDatabase(dbFile));
    addTearDown(() async {
      await db.close();
      if (dbFile.existsSync()) dbFile.deleteSync();
    });

    final planId = 'received:refuse';
    final now = DateTime.utc(2026, 6, 14);
    await db.upsertPlanPeerEstablishment(
      PlanPeerEstablishmentsCompanion.insert(
        id: '$planId:p1',
        planId: planId,
        participantId: '$planId:p1',
        peerPublicMaterialB64: RelayRouting.b64(targetPub),
        peerDisplayName: 'Target',
        peerAvatarId: 'a02',
        proposerDisplayName: 'Monica',
        outboundPendingAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final requesterIdentity = InMemoryIdentityKeystore(seed: requesterSeed);
    final targetIdentity = InMemoryIdentityKeystore(seed: targetSeed);
    final selfAddr = await RelayRouting.steadyStateAddress(
      firstPub: requesterPub,
      secondPub: targetPub,
    );
    final peerAddr = await RelayRouting.steadyStateAddress(
      firstPub: targetPub,
      secondPub: requesterPub,
    );
    await relay.establishRouting(
      selfIdentity: selfAddr,
      peerIdentity: peerAddr,
    );
    await relay.establishRouting(
      selfIdentity: peerAddr,
      peerIdentity: selfAddr,
    );

    final frame = await EnvelopeCodec.encryptContactEstablishmentResponse(
      envelope: ContactEstablishmentResponseEnvelope(
        senderLongTermPublicKey: targetPub,
        accepted: false,
      ),
      senderLongTermPrivateKey: await targetIdentity.loadOrCreatePrivateKey(),
      peerLongTermPublicKey: requesterPub,
    );
    await relay.postEnvelope(
      senderIdentity: peerAddr,
      recipientIdentity: selfAddr,
      idempotencyKey: Uint8List.fromList(List<int>.filled(16, 7)),
      ciphertext: frame,
      kind: EnvelopeKind.contactEstablishmentResponse,
      ttl: const Duration(days: 30),
    );

    final orch = HandshakeOrchestrator(
      db: db,
      identity: requesterIdentity,
      relay: relay,
      contacts: ContactsRepository(db),
      invitations: ContactInvitationsRepository(db),
      contactNotifications: _FakeContactNotificationSink(),
    );
    await orch.pollSteadyStateInboxes();

    final row = await db.getPlanPeerEstablishment('$planId:p1');
    expect(row?.outboundPendingAt, isNull);
    expect(row?.refusedAt, isNotNull);
  });
}
