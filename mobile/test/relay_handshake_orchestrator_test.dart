import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/activity/relay_activity_log_service.dart';
import 'package:compartarenta/contacts/contact_duplicate_handshake_dialog_state.dart';
import 'package:compartarenta/contacts/contact_duplicate_module_anchor.dart';
import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/device/device_binding_service.dart';
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
  Future<({String displayName, String avatarId})> Function()?
  ackProfileForAutoAccept,
  String? deviceBindingId,
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
    deviceBinding: DeviceBindingService(
      fixedIdForTesting: deviceBindingId ?? 'binding-test-$id',
    ),
  );
  orchestrator.ackProfileForAutoAccept = ackProfileForAutoAccept;
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
  final addedViaInvitation = <String>[];
  final addRequestResolutions = <({String displayName, bool accepted})>[];
  final addRequestFailures = <String>[];
  final duplicateModuleAnchorRejections = <void>[];
  final disconnections = <String>[];

  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {
    addRequests.add(displayName);
  }

  @override
  Future<void> contactAddedViaInvitation({required String displayName}) async {
    addedViaInvitation.add(displayName);
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
  Future<void> contactDuplicateModuleAnchorRejected() async {
    duplicateModuleAnchorRejections.add(null);
  }

  @override
  Future<void> contactDisconnected({required String displayName}) async {
    disconnections.add(displayName);
  }

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
      ackProfileForAutoAccept: () async => (
        displayName: 'Inviter Self-Name',
        avatarId: 'mdi:inviter-avatar',
      ),
    );
    invitee = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)),
      ackProfileForAutoAccept: () async => (
        displayName: 'Invitee Self-Name',
        avatarId: 'mdi:invitee-avatar',
      ),
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

    // Step 3 — inviter polls, picks up hello, auto-accepts, posts ack.
    await inviter.orchestrator.processAllPendingHandshakes();
    expect(
      relay.envelopeCount,
      1,
      reason: 'ack envelope should be posted after auto-accept',
    );
    expect(relay.storedEnvelopes.single.kind, EnvelopeKind.ack);
    expect(inviter.orchestrator.incomingHandshakes.value, isEmpty);
    expect(inviter.notifications.addedViaInvitation, ['Invitee Self-Name']);
    expect(inviter.notifications.addRequests, isEmpty);
    final fallbackIncoming = await inviter.orchestrator
        .incomingHandshakeForContact(invite.localContactId);
    expect(fallbackIncoming, isNull);

    // Invitation nonce is consumed regardless of accept/reject outcome.
    final invitationRow = await (inviter.db.select(
      inviter.db.contactInvitations,
    )..where((t) => t.id.equals(invite.invitation.id))).getSingle();
    expect(invitationRow.status, InvitationStatus.used);

    // Inviter's stub Contact is now connected.
    final inviterContact = await inviter.contacts.get(invite.localContactId);
    expect(inviterContact, isNotNull);
    expect(inviterContact!.kind, 'connected');
    expect(inviterContact.displayName, 'Invitee Self-Name');
    expect(inviterContact.peerPublicMaterial, isNotNull);

    // Step 4 — invitee polls, decrypts ack, promotes its stub.
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

  test(
    'invitee retries hello post after transient post timeout',
    () async {
      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'pending peer',
        stubAvatarId: 'mdi:account',
      );
      final code =
          (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;

      relay.postEnvelopeTimeoutsRemaining = 1;
      final redeem = await invitee.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      expect(relay.envelopeCount, 0);
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.dispatchingHello,
      );

      await invitee.orchestrator.processAllPendingHandshakes();
      expect(relay.envelopeCount, 1);
      expect(relay.storedEnvelopes.single.kind, EnvelopeKind.hello);
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.awaitingAck,
      );

      await inviter.orchestrator.processAllPendingHandshakes();
      await invitee.orchestrator.processAllPendingHandshakes();
      final inviteeContact = await invitee.contacts.get(redeem.localContactId);
      expect(inviteeContact?.kind, 'connected');
    },
  );

  test(
    'invitee hello post idempotent after timeout with stored envelope',
    () async {
      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'pending peer',
        stubAvatarId: 'mdi:account',
      );
      final code =
          (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;

      relay.timeoutAfterPostOnce = true;
      final redeem = await invitee.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      expect(relay.envelopeCount, 1);
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.dispatchingHello,
      );

      await invitee.orchestrator.processAllPendingHandshakes();
      expect(relay.envelopeCount, 1, reason: 'idempotent retry must not duplicate');
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.awaitingAck,
      );
    },
  );

  test(
    'inviter polls hello after transient inbox fetch timeout',
    () async {
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
      expect(relay.envelopeCount, 1);

      relay.fetchInboxTimeoutsRemaining = 1;
      await inviter.orchestrator.processAllPendingHandshakes();
      expect(relay.storedEnvelopes.single.kind, EnvelopeKind.hello);

      await inviter.orchestrator.processAllPendingHandshakes();

      final inviterContact = await inviter.contacts.get(invite.localContactId);
      expect(inviterContact?.kind, 'connected');
      expect(relay.storedEnvelopes.single.kind, EnvelopeKind.ack);
    },
  );

  test(
    'invitee retries ack after transient establishRouting timeout',
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
      expect(relay.storedEnvelopes.single.kind, EnvelopeKind.ack);

      relay.establishRoutingTimeoutsRemaining = 1;
      await invitee.orchestrator.processAllPendingHandshakes();

      expect(relay.envelopeCount, 1, reason: 'ack must stay until processing finishes');
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.awaitingAck,
      );
      final midContact = await invitee.contacts.get(redeem.localContactId);
      expect(midContact?.kind, isNot('connected'));

      relay.establishRoutingTimeoutsRemaining = 0;
      await invitee.orchestrator.processAllPendingHandshakes();

      expect(relay.envelopeCount, 0);
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.completed,
      );
      final inviteeContact = await invitee.contacts.get(redeem.localContactId);
      expect(inviteeContact?.kind, 'connected');
    },
  );

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

    final inviterContact = await inviter.contacts.get(invite.localContactId);
    expect(inviterContact?.kind, 'connected');
    expect(inviterContact?.displayName, 'Invitee Self-Name');
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
      await invitee.orchestrator.processAllPendingHandshakes();

      await invitee.orchestrator.sendDisconnect(redeem.localContactId);
      await inviter.orchestrator.pollSteadyStateInboxes();

      expect(inviter.notifications.disconnections, ['Invitee Self-Name']);
      final inviterContact = await inviter.contacts.get(invite.localContactId);
      expect(inviterContact?.kind, 'local-only');
      expect(inviterContact?.disconnectedAt, isNotNull);
      final logs = await inviter.db.select(inviter.db.relayActivityLogEntries).get();
      expect(
        logs.any((e) => e.kind == RelayActivityLogKinds.contactDisconnected),
        isTrue,
      );
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
    inviter.orchestrator.autoAcceptIncomingHandshakes = false;
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
    final handshakeLogs =
        await inviter.db.select(inviter.db.relayActivityLogEntries).get();
    expect(
      handshakeLogs.any(
        (e) => e.kind == RelayActivityLogKinds.contactHandshakeReceived,
      ),
      isTrue,
    );

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
      // Rejected acks intentionally omit display_name, so the invitee falls
      // back to the localized 'Unknown' placeholder. See `encryptAck` in
      // `lib/relay/envelopes.dart`.
      (displayName: 'Unknown', accepted: false),
    ]);
  });

  test('replayed hello after nonce consumption is ignored', () async {
    inviter.orchestrator.autoAcceptIncomingHandshakes = false;
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
        deviceBindingId: 'binding-replay-test',
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

  test(
    'redeem survives post timeout when hello was stored on relay',
    () async {
      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'pending peer',
        stubAvatarId: 'mdi:account',
      );
      final parsed = parseInvitationCode(invite.shortCode);
      expect(parsed, isA<InvitationCodeOk>());
      final code = (parsed as InvitationCodeOk).code;

      relay.timeoutAfterPostOnce = true;
      final redeem = await invitee.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Invitee Self-Name',
        selfAvatarId: 'mdi:invitee-avatar',
      );
      expect(relay.envelopeCount, 1);
      expect(relay.idempotentPostCount, 1);
      expect(relay.postEnvelopeCallCount, 1);
      expect(invitee.notifications.addRequestFailures, isEmpty);
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.dispatchingHello,
      );

      await inviter.orchestrator.processAllPendingHandshakes();
      expect(relay.postEnvelopeCallCount, 2); // inviter ack

      await invitee.orchestrator.processAllPendingHandshakes();
      expect(relay.postEnvelopeCallCount, 3); // idempotent hello retry
      expect(relay.idempotentPostCount, 2); // hello + ack map entries
      final stateAfterHelloRetry =
          await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId);
      // Ack may land in the same poll cycle once hello dispatch is confirmed.
      expect(
        stateAfterHelloRetry,
        anyOf(HandshakeState.awaitingAck, HandshakeState.completed),
      );

      if (stateAfterHelloRetry != HandshakeState.completed) {
        await invitee.orchestrator.processAllPendingHandshakes();
      }
      expect(
        await invitee.orchestrator.pendingHandshakeState(redeem.handshakeId),
        HandshakeState.completed,
      );
      expect(
        invitee.notifications.addRequestResolutions,
        [(displayName: 'Inviter Self-Name', accepted: true)],
      );
    },
  );

  test('re-handshake with same device binding merges connected contact', () async {
    final relay = FakeRelayClient();
    const sharedBinding = 'monica-device-binding-shared';
    final inviter = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      deviceBindingId: 'louys-binding',
      ackProfileForAutoAccept: () async => (
        displayName: 'Louys',
        avatarId: 'mdi:louys',
      ),
    );
    final inviteeFirst = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 0x20 + i)),
      deviceBindingId: sharedBinding,
    );

    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'Monica',
      stubAvatarId: 'mdi:monica',
    );
    final code = (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
    await inviteeFirst.orchestrator.redeemInvitation(
      code: code,
      selfDisplayName: 'Monica',
      selfAvatarId: 'mdi:monica',
    );
    await inviter.orchestrator.processAllPendingHandshakes();
    await inviteeFirst.orchestrator.processAllPendingHandshakes();

    final firstContacts = await inviter.contacts.list();
    expect(firstContacts.where((c) => c.kind == 'connected').length, 1);
    final firstContactId = firstContacts.first.id;

    final inviteeSecond = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 0x40 + i)),
      deviceBindingId: sharedBinding,
    );
    final invite2 = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'Monica',
      stubAvatarId: 'mdi:monica',
    );
    final code2 =
        (parseInvitationCode(invite2.shortCode) as InvitationCodeOk).code;
    await inviteeSecond.orchestrator.redeemInvitation(
      code: code2,
      selfDisplayName: 'Monica',
      selfAvatarId: 'mdi:monica',
    );
    await inviter.orchestrator.processAllPendingHandshakes();
    await inviteeSecond.orchestrator.processAllPendingHandshakes();

    final after = await inviter.contacts.list();
    final connected = after.where((c) => c.kind == 'connected').toList();
    expect(connected.length, 1);
    expect(connected.single.id, firstContactId);
    expect(connected.single.peerDeviceBindingId, sharedBinding);
    expect(
      inviter.orchestrator.pendingContactDuplicateDialog.value?.kind,
      ContactDuplicateDialogKind.inviterMerged,
    );
  });

  test(
    're-handshake with same device binding rejects when housing plan anchors contact',
    () async {
      final relay = FakeRelayClient();
      const sharedBinding = 'monica-device-binding-housing';
      final inviter = await _spawnSide(
        relay: relay,
        identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => i + 2)),
        deviceBindingId: 'louys-binding-housing',
        ackProfileForAutoAccept: () async => (
          displayName: 'Louys',
          avatarId: 'mdi:louys',
        ),
      );
      final inviteeFirst = await _spawnSide(
        relay: relay,
        identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 0x30 + i)),
        deviceBindingId: sharedBinding,
      );

      final invite = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'Monica',
        stubAvatarId: 'mdi:monica',
      );
      final code =
          (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
      await inviteeFirst.orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: 'Monica',
        selfAvatarId: 'mdi:monica',
      );
      await inviter.orchestrator.processAllPendingHandshakes();
      await inviteeFirst.orchestrator.processAllPendingHandshakes();

      final firstContactId = (await inviter.contacts.list()).first.id;
      await _seedActiveHousingPlanForContact(
        inviter.db,
        planId: 'plan:monica-anchor',
        contactId: firstContactId,
      );

      final inviteeSecond = await _spawnSide(
        relay: relay,
        identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 0x50 + i)),
        deviceBindingId: sharedBinding,
      );
      final invite2 = await inviter.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'Monica',
        stubAvatarId: 'mdi:monica',
      );
      final code2 =
          (parseInvitationCode(invite2.shortCode) as InvitationCodeOk).code;
      final redeem2 = await inviteeSecond.orchestrator.redeemInvitation(
        code: code2,
        selfDisplayName: 'Monica',
        selfAvatarId: 'mdi:monica',
      );
      await inviter.orchestrator.processAllPendingHandshakes();
      await inviteeSecond.orchestrator.processAllPendingHandshakes();

      final connected = (await inviter.contacts.list())
          .where((c) => c.kind == 'connected')
          .toList();
      expect(connected.length, 1);
      expect(connected.single.id, firstContactId);

      expect(
        inviter.orchestrator.pendingContactDuplicateDialog.value?.kind,
        ContactDuplicateDialogKind.inviterRejectedAnchor,
      );
      expect(
        inviter.orchestrator.pendingContactDuplicateDialog.value?.anchorKind,
        DuplicateModuleAnchorKind.housing,
      );
      expect(
        await inviteeSecond.orchestrator.pendingHandshakeState(
          redeem2.handshakeId,
        ),
        HandshakeState.rejected,
      );
      expect(inviteeSecond.notifications.duplicateModuleAnchorRejections.length, 1);
      await Future.wait([
        inviteeSecond.orchestrator.processAllPendingHandshakes(),
        inviteeSecond.orchestrator.processAllPendingHandshakes(),
      ]);
      expect(inviteeSecond.notifications.duplicateModuleAnchorRejections.length, 1);
      expect(inviteeSecond.notifications.addRequestResolutions, isEmpty);
      expect(
        inviteeSecond.orchestrator.pendingContactDuplicateDialog.value?.kind,
        ContactDuplicateDialogKind.inviteeRejectedAnchor,
      );
    },
  );
}

Future<void> _seedActiveHousingPlanForContact(
  AppDatabase db, {
  required String planId,
  required String contactId,
}) async {
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
      displayName: 'Self',
      avatarId: 'a01',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p1',
      displayName: 'Monica',
      avatarId: 'a01',
      contactId: Value(contactId),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agr:$planId',
      planId: planId,
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: DateTime.utc(2026, 12, 31),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$planId',
      planId: planId,
      activeRevisionId: const Value('rev:active'),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: 'rev:active',
      packageId: 'pkg:$planId',
      contentHash: 'hash:active',
      proposerParticipantId: '$planId:self',
      payloadJson: '{"lifecycleState":"active"}',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

List<int> _hexDecode(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}
