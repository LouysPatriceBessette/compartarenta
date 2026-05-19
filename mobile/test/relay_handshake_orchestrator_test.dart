import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/relay/envelopes.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/relay_client.dart';
import 'package:compartarenta/relay/routing.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

class _Side {
  _Side({
    required this.db,
    required this.dbFile,
    required this.identity,
    required this.orchestrator,
    required this.contacts,
    required this.notifications,
  });

  final AppDatabase db;
  final File dbFile;
  final IdentityKeystore identity;
  final HandshakeOrchestrator orchestrator;
  final ContactsRepository contacts;
  final _FakeContactNotificationSink notifications;
}

int _relayDbFileSeq = 0;

Future<_Side> _spawnSide({
  required RelayClient relay,
  required Uint8List identitySeed,
  Duration pollInterval = const Duration(seconds: 60),
}) async {
  final id = _relayDbFileSeq++;
  final dbFile = File(
    '${Directory.systemTemp.path}/relay_handshake_test_$id.sqlite',
  );
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
  }
  final db = _DbForTesting(NativeDatabase(dbFile));
  final identity = InMemoryIdentityKeystore(seed: identitySeed);
  final contacts = ContactsRepository(db);
  final invitations = ContactInvitationsRepository(db);
  final notifications = _FakeContactNotificationSink();
  final orchestrator = HandshakeOrchestrator(
    db: db,
    identity: identity,
    relay: relay,
    contacts: contacts,
    invitations: invitations,
    contactNotifications: notifications,
    pollInterval: pollInterval,
  );
  return _Side(
    db: db,
    dbFile: dbFile,
    identity: identity,
    orchestrator: orchestrator,
    contacts: contacts,
    notifications: notifications,
  );
}

final class _FakeContactNotificationSink implements ContactNotificationSink {
  final addRequests = <String>[];
  final addRequestResolutions = <({String displayName, bool accepted})>[];
  final addRequestFailures = <String>[];
  final disconnections = <String>[];

  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {
    addRequests.add(displayName);
  }

  @override
  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  }) async {
    addRequestResolutions.add((displayName: displayName, accepted: accepted));
  }

  @override
  Future<void> contactAddRequestFailed({required String errorCode}) async {
    addRequestFailures.add(errorCode);
  }

  @override
  Future<void> contactDisconnected({required String displayName}) async {
    disconnections.add(displayName);
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  late FakeRelayClient relay;
  late _Side inviter;
  late _Side invitee;

  setUp(() async {
    relay = FakeRelayClient();
    inviter = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
    );
    invitee = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)),
    );
  });

  tearDown(() async {
    inviter.orchestrator.stopPolling();
    invitee.orchestrator.stopPolling();
    await inviter.db.close();
    await invitee.db.close();
    try {
      if (inviter.dbFile.existsSync()) inviter.dbFile.deleteSync();
    } catch (_) {}
    try {
      if (invitee.dbFile.existsSync()) invitee.dbFile.deleteSync();
    } catch (_) {}
  });

  test('full happy-path handshake promotes both stubs to connected', () async {
    // Step 1 — inviter generates a code; relay should now hold the two
    //          handshake-direction routings.
    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'pending peer',
      stubAvatarId: 'mdi:account',
    );
    expect(relay.routings.length, 2);

    // Parse the short code back into an InvitationCode the invitee can use.
    final parsed = parseInvitationCode(invite.shortCode);
    expect(parsed, isA<InvitationCodeOk>());
    final code = (parsed as InvitationCodeOk).code;

    // Step 2 — invitee sends hello. Inbox at addrInviter now holds 1 envelope.
    final redeem = await invitee.orchestrator.redeemInvitation(
      code: code,
      selfDisplayName: 'Invitee Self-Name',
      selfAvatarId: 'mdi:invitee-avatar',
    );
    expect(relay.envelopeCount, 1);
    expect(relay.storedEnvelopes.single.kind, EnvelopeKind.hello);

    // Step 3 — inviter polls, picks up hello, transitions to helloReceived.
    await inviter.orchestrator.processAllPendingHandshakes();
    expect(
      relay.envelopeCount,
      0,
      reason: 'hello envelope should be acknowledged after decryption',
    );
    expect(inviter.orchestrator.incomingHandshakes.value.length, 1);
    final incoming = inviter.orchestrator.incomingHandshakes.value.single;
    expect(incoming.peerDisplayName, 'Invitee Self-Name');
    expect(incoming.peerAvatarId, 'mdi:invitee-avatar');
    expect(inviter.notifications.addRequests, ['Invitee Self-Name']);
    final fallbackIncoming = await inviter.orchestrator
        .incomingHandshakeForContact(invite.localContactId);
    expect(fallbackIncoming?.handshakeId, incoming.handshakeId);

    // Invitation nonce is consumed regardless of accept/reject outcome.
    final invitationRow = await (inviter.db.select(
      inviter.db.contactInvitations,
    )..where((t) => t.id.equals(invite.invitation.id))).getSingle();
    expect(invitationRow.status, InvitationStatus.used);

    // Step 4 — inviter accepts. Relay should now hold an ack envelope
    //          for the invitee, and a steady-state routing.
    await inviter.orchestrator.acceptIncoming(
      incoming.handshakeId,
      selfDisplayName: 'Inviter Self-Name',
      selfAvatarId: 'mdi:inviter-avatar',
    );
    expect(relay.envelopeCount, 1);
    expect(relay.storedEnvelopes.single.kind, EnvelopeKind.ack);

    // Inviter's stub Contact is now connected.
    final inviterContact = await inviter.contacts.get(invite.localContactId);
    expect(inviterContact, isNotNull);
    expect(inviterContact!.kind, 'connected');
    expect(inviterContact.displayName, 'Invitee Self-Name');
    expect(inviterContact.peerPublicMaterial, isNotNull);

    // Step 5 — invitee polls, decrypts ack, promotes its stub.
    await invitee.orchestrator.processAllPendingHandshakes();
    final inviteeContact = await invitee.contacts.get(redeem.localContactId);
    expect(inviteeContact, isNotNull);
    expect(inviteeContact!.kind, 'connected');
    expect(inviteeContact.displayName, 'Inviter Self-Name');
    expect(inviteeContact.peerPublicMaterial, isNotNull);
    expect(invitee.notifications.addRequestResolutions, [
      (displayName: 'Inviter Self-Name', accepted: true),
    ]);

    // After consumption, no envelopes remain in the relay.
    expect(relay.envelopeCount, 0);

    // Steady-state routing was established by both sides.
    // 2 handshake-direction + 1 inviter-side steady + 1 invitee-side steady = 4
    // minus 2 decommissioned handshake-direction = 2 remaining.
    expect(relay.routings.length, 2);
  });

  test('failed unknown inviter handshake remains pollable', () async {
    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'pending peer',
      stubAvatarId: 'mdi:account',
    );
    final code =
        (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;

    await invitee.orchestrator.redeemInvitation(
      code: code,
      selfDisplayName: 'Invitee Self-Name',
      selfAvatarId: 'mdi:invitee-avatar',
    );

    final handshakeId = '${invite.invitation.id}:inviter';
    await (inviter.db.update(
      inviter.db.pendingHandshakes,
    )..where((t) => t.id.equals(handshakeId))).write(
      const PendingHandshakesCompanion(
        state: Value(HandshakeState.failed),
        lastErrorCode: Value('unknown'),
      ),
    );

    final active = await inviter.orchestrator.activePendingHandshakeRows();
    expect(active.map((row) => row.id), contains(handshakeId));

    await inviter.orchestrator.processAllPendingHandshakes();

    final incoming = inviter.orchestrator.incomingHandshakes.value.single;
    expect(incoming.handshakeId, handshakeId);
    expect(incoming.peerDisplayName, 'Invitee Self-Name');
  });

  test(
    'inbound disconnect emits a contact disconnection notification',
    () async {
      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'pending peer',
        stubAvatarId: 'mdi:account',
      );
      final code =
          (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
      final redeem = await invitee.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      await inviter.orchestrator.processAllPendingHandshakes();
      final incoming = inviter.orchestrator.incomingHandshakes.value.single;
      await inviter.orchestrator.acceptIncoming(
        incoming.handshakeId,
        selfDisplayName: 'Inviter Self-Name',
        selfAvatarId: 'mdi:inviter-avatar',
      );
      await invitee.orchestrator.processAllPendingHandshakes();

      await invitee.orchestrator.sendDisconnect(redeem.localContactId);
      await inviter.orchestrator.pollSteadyStateInboxes();

      expect(inviter.notifications.disconnections, ['Invitee Self-Name']);
      final inviterContact = await inviter.contacts.get(invite.localContactId);
      expect(inviterContact?.kind, 'local-only');
      expect(inviterContact?.disconnectedAt, isNotNull);
    },
  );

  test(
    'reconnection reuses disconnected contacts instead of duplicating stubs',
    () async {
      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'pending peer',
        stubAvatarId: 'mdi:account',
      );
      final code =
          (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
      final redeem = await invitee.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      await inviter.orchestrator.processAllPendingHandshakes();
      await inviter.orchestrator.acceptIncoming(
        inviter.orchestrator.incomingHandshakes.value.single.handshakeId,
        selfDisplayName: 'Inviter Self-Name',
        selfAvatarId: 'mdi:inviter-avatar',
      );
      await invitee.orchestrator.processAllPendingHandshakes();

      await invitee.orchestrator.sendDisconnect(redeem.localContactId);
      await inviter.orchestrator.pollSteadyStateInboxes();
      expect(
        (await invitee.contacts.get(redeem.localContactId))?.disconnectedAt,
        isNotNull,
      );
      expect(
        (await inviter.contacts.get(invite.localContactId))?.disconnectedAt,
        isNotNull,
      );

      final reconnect = await invitee.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'unused reconnect stub',
        stubAvatarId: 'mdi:unused',
        reconnectContactId: redeem.localContactId,
      );
      expect(reconnect.localContactId, redeem.localContactId);

      final reconnectCode =
          (parseInvitationCode(reconnect.shortCode) as InvitationCodeOk).code;
      await inviter.orchestrator.redeemInvitation(
        code: reconnectCode,
        selfDisplayName: 'Inviter Self-Name',
        selfAvatarId: 'mdi:inviter-avatar',
      );
      await invitee.orchestrator.processAllPendingHandshakes();
      await invitee.orchestrator.acceptIncoming(
        invitee.orchestrator.incomingHandshakes.value.single.handshakeId,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      await inviter.orchestrator.processAllPendingHandshakes();

      final inviteeVisible = await invitee.contacts.list();
      final inviterVisible = await inviter.contacts.list();
      expect(inviteeVisible, hasLength(1));
      expect(inviterVisible, hasLength(1));
      expect(inviteeVisible.single.id, redeem.localContactId);
      expect(inviterVisible.single.id, invite.localContactId);
      expect(inviteeVisible.single.kind, 'connected');
      expect(inviterVisible.single.kind, 'connected');
    },
  );

  test('rejection path drops both stubs and signals the invitee', () async {
    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'pending peer',
      stubAvatarId: 'mdi:account',
    );
    final code =
        (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;

    final redeem = await invitee.orchestrator.redeemInvitation(
      code: code,
      selfDisplayName: 'Invitee Name',
      selfAvatarId: 'mdi:invitee-avatar',
    );
    await inviter.orchestrator.processAllPendingHandshakes();
    final incoming = inviter.orchestrator.incomingHandshakes.value.single;

    await inviter.orchestrator.rejectIncoming(
      incoming.handshakeId,
      selfDisplayName: 'Inviter Self-Name',
      selfAvatarId: 'mdi:inviter-avatar',
    );

    // Inviter's stub is gone.
    final inviterContact = await inviter.contacts.get(invite.localContactId);
    expect(
      inviterContact?.deletedAt,
      isNotNull,
      reason: 'rejected stub is deleted locally',
    );

    // Invitee polls, sees rejection, drops its stub.
    await invitee.orchestrator.processAllPendingHandshakes();
    final inviteeContact = await invitee.contacts.get(redeem.localContactId);
    expect(inviteeContact?.deletedAt, isNotNull);
    expect(invitee.notifications.addRequestResolutions, [
      (displayName: 'Inviter Self-Name', accepted: false),
    ]);
  });

  test('replayed hello after nonce consumption is ignored', () async {
    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'pending peer',
      stubAvatarId: 'mdi:account',
    );
    final code =
        (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;

    await invitee.orchestrator.redeemInvitation(
      code: code,
      selfDisplayName: 'Invitee Name',
      selfAvatarId: 'mdi:invitee-avatar',
    );
    await inviter.orchestrator.processAllPendingHandshakes();

    // Now manually drop a second hello envelope at the same address by
    // reusing the relay routing the inviter had pre-registered for the
    // hello direction. The second envelope must be ignored by the
    // inviter (nonce consumed); the stub state must not regress.
    final hexInv = Uint8List.fromList(_hexDecode(invite.invitation.id));
    final hexNonce = Uint8List.fromList(_hexDecode(invite.invitation.nonce));
    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: hexInv,
      nonce: hexNonce,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: hexInv,
      nonce: hexNonce,
    );
    final inviterHandshakePub = await RelayRouting.handshakePublicKey(
      await RelayRouting.handshakePrivateKey(
        invitationId: hexInv,
        nonce: hexNonce,
      ),
    );
    final replayFrame = await EnvelopeCodec.encryptHello(
      envelope: HelloEnvelope(
        invitationId: hexInv,
        inviteeLongTermPublicKey: await invitee.identity.publicKey(),
        displayName: 'Spoof',
        avatarId: 'spoof',
        echoedNonce: hexNonce,
      ),
      invitationNonce: hexNonce,
      inviteeLongTermPrivateKey: await invitee.identity
          .loadOrCreatePrivateKey(),
      inviterHandshakePublicKey: inviterHandshakePub,
    );
    await relay.postEnvelope(
      senderIdentity: addrInvitee,
      recipientIdentity: addrInviter,
      idempotencyKey: Uint8List.fromList(List<int>.filled(16, 1)),
      ciphertext: replayFrame,
      kind: EnvelopeKind.hello,
      ttl: const Duration(hours: 1),
    );

    await inviter.orchestrator.processAllPendingHandshakes();

    final incoming = inviter.orchestrator.incomingHandshakes.value;
    // Still one incoming row from the original hello, not two — the
    // replay was silently dropped.
    expect(incoming.length, 1);
    expect(incoming.single.peerDisplayName, 'Invitee Name');
  });
}

List<int> _hexDecode(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}
