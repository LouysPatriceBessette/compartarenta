import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/device/device_binding_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/sandbox/peer_simulator.dart';
import 'package:compartarenta/sandbox/sandbox_relay.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Db extends AppDatabase {
  _Db(super.e) : super.forTesting();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PeerSimulator inviteNextBot connects catalog bot via FakeRelay', () async {
    SharedPreferences.setMockInitialValues({
      'sandbox.mode': true,
    });
    final prefs = await AppPreferences.load();
    final relay = SandboxRelay.ensureFresh();
    final humanFile = File(
      '${Directory.systemTemp.path}/sandbox_peer_human.sqlite',
    );
    if (humanFile.existsSync()) humanFile.deleteSync();
    final humanDb = _Db(NativeDatabase(humanFile));
    final humanOrch = HandshakeOrchestrator(
      db: humanDb,
      identity: InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      ),
      relay: relay,
      contacts: ContactsRepository(humanDb),
      invitations: ContactInvitationsRepository(humanDb),
      pollInterval: const Duration(days: 1),
      deviceBinding: DeviceBindingService.forTesting('sandbox-human'),
    );
    humanOrch.enableSandboxPeerAutoAccept(
      profile: () async => (displayName: 'Human', avatarId: 'mdi:0'),
    );
    HandshakeOrchestrator.install(humanOrch);
    final sim = PeerSimulator.install(relay: relay, prefs: prefs);

    final bot = await sim.inviteNextBot(
      humanOrchestrator: humanOrch,
      humanDisplayName: 'Human',
      humanAvatarId: 'mdi:0',
    );
    expect(bot, isNotNull);
    expect(bot!.displayName, 'Louys');
    final contacts = await ContactsRepository(humanDb).list();
    expect(contacts.where((c) => c.kind == 'connected'), isNotEmpty);

    final bot2 = await sim.inviteNextBot(
      humanOrchestrator: humanOrch,
      humanDisplayName: 'Human',
      humanAvatarId: 'mdi:0',
    );
    expect(bot2, isNotNull);
    expect(bot2!.displayName, 'Monica');
    final bot2Pub = await bot2.identity.publicKeyB64();
    final bot1Contacts = await bot.contacts.list();
    expect(
      bot1Contacts.any(
        (c) =>
            c.kind == 'connected' && (c.peerPublicMaterial ?? '') == bot2Pub,
      ),
      isTrue,
      reason: 'bots must mesh so multi-peer proposal accept can succeed',
    );

    final meshAfterInvite = sim.botPairConnectAttempts;
    expect(meshAfterInvite, greaterThanOrEqualTo(1));

    // Envelope storm must not re-run bot↔bot mesh (ANR path).
    final sender = Uint8List.fromList(List<int>.filled(32, 1));
    final recipient = Uint8List.fromList(List<int>.filled(32, 2));
    await relay.establishRouting(
      selfIdentity: sender,
      peerIdentity: recipient,
    );
    sim.pauseReactions();
    for (var i = 0; i < 5; i++) {
      await relay.postEnvelope(
        senderIdentity: sender,
        recipientIdentity: recipient,
        idempotencyKey: Uint8List.fromList(
          List<int>.generate(16, (j) => i + j),
        ),
        ciphertext: Uint8List.fromList([1, 2, 3]),
        kind: 1,
        ttl: const Duration(hours: 1),
      );
    }
    sim.resumeReactions();
    await sim.reactOnce();
    expect(
      sim.botPairConnectAttempts,
      meshAfterInvite,
      reason: 'reactOnce must not start new bot↔bot handshakes',
    );
    expect(await sim.botsAreConnectedForTest(bot, bot2), isTrue);

    PeerSimulator.clearInstalled();
    SandboxRelay.clear();
    HandshakeOrchestrator.clearInstalledInstanceAfterDevDatabaseReset();
    await humanDb.close();
    if (humanFile.existsSync()) humanFile.deleteSync();
  });

  test(
    'auto-accept skips when bot self already responded (no re-accept storm)',
    () async {
      SharedPreferences.setMockInitialValues({'sandbox.mode': true});
      final prefs = await AppPreferences.load();
      final relay = SandboxRelay.ensureFresh();
      final humanFile = File(
        '${Directory.systemTemp.path}/sandbox_peer_human_accept_guard.sqlite',
      );
      if (humanFile.existsSync()) humanFile.deleteSync();
      final humanDb = _Db(NativeDatabase(humanFile));
      final humanOrch = HandshakeOrchestrator(
        db: humanDb,
        identity: InMemoryIdentityKeystore(
          seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 3)),
        ),
        relay: relay,
        contacts: ContactsRepository(humanDb),
        invitations: ContactInvitationsRepository(humanDb),
        pollInterval: const Duration(days: 1),
        deviceBinding: DeviceBindingService.forTesting('sandbox-human-guard'),
      );
      humanOrch.enableSandboxPeerAutoAccept(
        profile: () async => (displayName: 'Human', avatarId: 'mdi:0'),
      );
      HandshakeOrchestrator.install(humanOrch);
      final sim = PeerSimulator.install(relay: relay, prefs: prefs);

      final bot = await sim.inviteNextBot(
        humanOrchestrator: humanOrch,
        humanDisplayName: 'Human',
        humanAvatarId: 'mdi:0',
      );
      expect(bot, isNotNull);

      const planId = 'plan:sandbox-guard';
      const revisionId = 'rev:sandbox-guard';
      final now = DateTime.utc(2026, 7, 16);
      await bot!.db.into(bot.db.plans).insert(
            PlansCompanion.insert(
              id: planId,
              type: 'housing',
              createdAt: now,
            ),
          );
      await bot.db.into(bot.db.participants).insert(
            ParticipantsCompanion.insert(
              id: '$planId:self',
              displayName: bot.displayName,
              avatarId: bot.avatarId,
              createdAt: now,
            ),
          );
      await bot.db.into(bot.db.proposalPackages).insert(
            ProposalPackagesCompanion.insert(
              id: 'pkg:$planId',
              planId: planId,
              createdAt: now,
              pendingRevisionId: const drift.Value(revisionId),
            ),
          );
      await bot.db.into(bot.db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: revisionId,
              packageId: 'pkg:$planId',
              contentHash: 'hash:$revisionId',
              proposerParticipantId: '$planId:p0',
              payloadJson: jsonEncode({
                'kind': PlanAgreementProposalService.kind,
                'lifecycleState': 'open',
              }),
              createdAt: now,
            ),
          );

      expect(
        await sim.botStillNeedsToAcceptForTest(
          bot,
          planId: planId,
          revisionId: revisionId,
        ),
        isTrue,
        reason: 'pending self response may still accept',
      );

      await bot.db.into(bot.db.proposalResponses).insert(
            ProposalResponsesCompanion.insert(
              id: 'resp:$revisionId:$planId:self',
              revisionId: revisionId,
              participantId: '$planId:self',
              status: ProposalResponseStatus.accepted.name,
              respondedAt: drift.Value(now),
            ),
          );

      expect(
        await sim.botStillNeedsToAcceptForTest(
          bot,
          planId: planId,
          revisionId: revisionId,
        ),
        isFalse,
        reason: 'already-accepted must not re-enter auto-accept',
      );

      final postsBefore = relay.postEnvelopeCallCount;
      await sim.reactOnce();
      await sim.reactOnce();
      expect(
        relay.postEnvelopeCallCount,
        postsBefore,
        reason: 'reactOnce must not re-broadcast accept for settled self',
      );

      PeerSimulator.clearInstalled();
      SandboxRelay.clear();
      HandshakeOrchestrator.clearInstalledInstanceAfterDevDatabaseReset();
      await humanDb.close();
      if (humanFile.existsSync()) humanFile.deleteSync();
    },
  );
}
