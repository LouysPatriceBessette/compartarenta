import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../contacts/contact_invitations_repository.dart';
import '../contacts/invitation_code.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../notifications/contact_notification_service.dart';
import '../prefs/app_preferences.dart';
import 'envelopes.dart';
import 'identity_keystore.dart';
import 'relay_client.dart';
import 'routing.dart';

/// Handshake state machine values mirrored from `PendingHandshakes.state`.
///
/// Inviter timeline:
///   awaitingHello -> helloReceived -> completed | rejected
/// Invitee timeline:
///   awaitingAck   -> completed | rejected
/// Either side can transition to `failed` on unrecoverable error.
class HandshakeState {
  static const String awaitingHello = 'awaiting_hello';
  static const String awaitingAck = 'awaiting_ack';

  /// Inviter has validated the hello; the peer's profile is stashed on
  /// the row, waiting for the local user to accept or reject.
  static const String helloReceived = 'hello_received';

  static const String rejected = 'rejected';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

/// Role values mirrored from `PendingHandshakes.role`.
class HandshakeRole {
  static const String inviter = 'inviter';
  static const String invitee = 'invitee';
}

/// Lightweight view used by the UI to surface incoming handshakes from
/// the inviter side without forcing it to know the DB schema.
class IncomingHandshakeView {
  IncomingHandshakeView({
    required this.handshakeId,
    required this.invitationIdHex,
    required this.peerDisplayName,
    required this.peerAvatarId,
    required this.peerPublicMaterialB64,
    required this.contactStubId,
    required this.receivedAt,
  });

  final String handshakeId;
  final String invitationIdHex;
  final String peerDisplayName;
  final String peerAvatarId;
  final String peerPublicMaterialB64;
  final String contactStubId;
  final DateTime receivedAt;
}

/// Fired when a peer's canonical name no longer matches the local user's
/// display label override for that contact (see `contact-peer-display-ownership`).
class ProfileLabelConflict {
  ProfileLabelConflict({
    required this.contactId,
    required this.newCanonicalDisplayName,
    required this.localDisplayLabel,
  });

  final String contactId;
  final String newCanonicalDisplayName;
  final String localDisplayLabel;
}

/// Result of a redeem attempt on the invitee side.
class RedeemHandshakeResult {
  RedeemHandshakeResult({
    required this.handshakeId,
    required this.localContactId,
  });

  final String handshakeId;
  final String localContactId;
}

/// Errors surfaced by the orchestrator.
class HandshakeOrchestratorError implements Exception {
  HandshakeOrchestratorError(this.code, [this.cause]);

  /// One of: `relay_unavailable`, `relay_error`, `invalid_code`,
  /// `already_completed`, `nonce_already_consumed`, `expired_code`,
  /// `unknown`.
  final String code;
  final Object? cause;

  @override
  String toString() =>
      'HandshakeOrchestratorError($code${cause == null ? '' : ': $cause'})';
}

/// Coordinates the entire Contacts handshake lifecycle on this device.
///
/// One instance per process; held by [bootstrap] and surfaced through the
/// [HandshakeOrchestrator.instance] static getter so any screen can drive
/// the flow without dependency injection.
///
/// Behaviour summary:
///
/// * **Generate an invitation** ([generateInvitation]): creates a stub
///   Contact, persists the local invitation row, pre-registers both
///   handshake-routing directions on the relay so the invitee can post
///   `hello` and so this device can post `ack` back to the invitee's
///   long-term address once the handshake completes.
/// * **Redeem an invitation** ([redeemInvitation]): derives handshake
///   addresses + handshake keys from the code, creates a stub Contact,
///   encrypts and posts the `hello`, persists a row in
///   `PendingHandshakes` so polling will pick up the ack.
/// * **Polling** ([processAllPendingHandshakes]): for each non-terminal
///   row, fetches the relevant relay inbox, decrypts incoming envelopes,
///   and either surfaces them via [incomingHandshakes] (inviter waiting
///   on accept/reject) or finishes the flow (invitee receiving the ack).
///   The periodic poll also runs [pollSteadyStateInboxes] so inbound
///   steady-state envelopes reach connected contacts.
/// * **Accept / Reject** ([acceptIncoming] / [rejectIncoming]): sends
///   the ack envelope, promotes (or discards) the local stub, and
///   establishes the steady-state routing on the relay.
/// * **Steady state** ([sendProfileUpdate], [sendDisconnect]): small
///   encrypted envelopes between connected contacts. Profile updates do
///   not transition any Contact kind; disconnect demotes both ends back
///   to local-only.
class HandshakeOrchestrator {
  HandshakeOrchestrator({
    required AppDatabase db,
    required IdentityKeystore identity,
    required RelayClient relay,
    required ContactsRepository contacts,
    required ContactInvitationsRepository invitations,
    ContactNotificationSink contactNotifications =
        const DefaultContactNotificationSink(),
    Duration pollInterval = const Duration(seconds: 10),
    Duration helloTtl = const Duration(hours: 24),
    Duration ackTtl = const Duration(hours: 24),
    Duration steadyTtl = const Duration(hours: 24),
    DateTime Function() now = DateTime.now,
  }) : _db = db,
       _identity = identity,
       _relay = relay,
       _contacts = contacts,
       _invitations = invitations,
       _contactNotifications = contactNotifications,
       _pollInterval = pollInterval,
       _helloTtl = helloTtl,
       _ackTtl = ackTtl,
       _steadyTtl = steadyTtl,
       _now = now;

  final AppDatabase _db;
  final IdentityKeystore _identity;
  final RelayClient _relay;
  final ContactsRepository _contacts;
  final ContactInvitationsRepository _invitations;
  final ContactNotificationSink _contactNotifications;
  final Duration _pollInterval;
  final Duration _helloTtl;
  final Duration _ackTtl;
  final Duration _steadyTtl;
  final DateTime Function() _now;

  static HandshakeOrchestrator? _instance;

  /// Globally accessible orchestrator. Set during [bootstrap]. Tests can
  /// install a custom one via [installForTesting].
  static HandshakeOrchestrator get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'HandshakeOrchestrator has not been initialised. Call '
        'HandshakeOrchestrator.install(...) during bootstrap.',
      );
    }
    return i;
  }

  /// Returns the installed orchestrator, or `null` if none has been
  /// installed yet. Useful in environments (tests, dev builds with no
  /// relay configured) where the relay layer is intentionally absent.
  static HandshakeOrchestrator? get maybeInstance => _instance;

  /// Installs the process-wide orchestrator. Must be called once during
  /// bootstrap. Subsequent calls replace the instance (useful for
  /// rebinding after preference changes).
  static void install(HandshakeOrchestrator orchestrator) {
    _instance = orchestrator;
  }

  @visibleForTesting
  static void installForTesting(HandshakeOrchestrator orchestrator) {
    _instance = orchestrator;
  }

  Timer? _pollTimer;
  bool _processing = false;

  /// Exposes the list of incoming handshakes awaiting accept / reject on
  /// the inviter side. UI binds to this to show the confirmation card.
  final ValueNotifier<List<IncomingHandshakeView>> incomingHandshakes =
      ValueNotifier<List<IncomingHandshakeView>>(const []);

  /// Incremented whenever a steady-state inbox envelope is applied
  /// ([EnvelopeKind.profileUpdate] or [EnvelopeKind.disconnect]) so contact
  /// UIs can refresh.
  final ValueNotifier<int> steadyStateInboxTick = ValueNotifier<int>(0);

  /// When a profile-update changes a peer's canonical name but the local user
  /// had a different [Contacts.localDisplayLabel], UIs MAY listen and prompt.
  final ValueNotifier<ProfileLabelConflict?> profileLabelConflict =
      ValueNotifier<ProfileLabelConflict?>(null);

  /// Disposes timers + notifiers. Mostly useful in tests.
  void dispose() {
    _pollTimer?.cancel();
    incomingHandshakes.dispose();
    steadyStateInboxTick.dispose();
    profileLabelConflict.dispose();
  }

  /// Starts the periodic polling timer. Safe to call multiple times.
  ///
  /// The first tick fires after [pollInterval]; callers that want an
  /// immediate poll should `await processAllPendingHandshakes()` before
  /// or after this call. Letting `Timer.periodic` own the first tick
  /// avoids races between the unawaited startup poll and an explicit
  /// caller (especially tests) running on the same orchestrator.
  void startPolling() {
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => unawaited(_safePoll()));
  }

  /// Stops the periodic polling timer.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Stops relay polling and closes the bootstrap-owned [AppDatabase] so the
  /// on-disk SQLite files can be removed (development-only local DB reset).
  Future<void> releaseLocalDatabaseConnectionForDevReset() async {
    stopPolling();
    await _db.close();
    AppDatabase.clearProcessScopeIfReferencing(_db);
  }

  /// Clears the process-wide orchestrator after its database was closed for a
  /// dev reset. A full app restart is required to reinstall the relay stack.
  static void clearInstalledInstanceAfterDevDatabaseReset() {
    _instance = null;
  }

  Future<void> _safePoll() async {
    if (_processing) return;
    _processing = true;
    try {
      await processAllPendingHandshakes();
      await pollSteadyStateInboxes();
    } catch (e, st) {
      debugPrint('HandshakeOrchestrator poll failed: $e\n$st');
    } finally {
      _processing = false;
    }
  }

  // ---------------------------------------------------------------------
  // Inviter side
  // ---------------------------------------------------------------------

  /// Generates a new invitation, creates a local stub Contact, registers
  /// the handshake routing on the relay, and starts polling.
  ///
  /// [stubDisplayName] / [stubAvatarId] feed the local stub so the user
  /// has a non-empty Contact to look at while the invitee thinks about
  /// the request. The display name will be **replaced** by the invitee's
  /// chosen self-name on accept.
  Future<
    ({
      ContactInvitation invitation,
      String localContactId,
      String shortCode,
      String deepLink,
      String webLink,
    })
  >
  generateInvitation({
    required Duration validFor,
    required String stubDisplayName,
    required String stubAvatarId,
  }) async {
    final created = _now().toUtc();
    final code = InvitationCode.generate();
    final invitationIdHex = code.invitationIdHex();
    final stubContactId = 'contact:handshake:$invitationIdHex';

    // 1) Stub Contact (local-only, will be promoted on accept).
    await _contacts.upsertLocalOnly(
      id: stubContactId,
      displayName: stubDisplayName,
      avatarId: stubAvatarId,
      createdAt: created,
      updatedAt: created,
    );

    // 2) Local invitation row owns the lifecycle (pending / used / ...).
    await _db.upsertContactInvitation(
      ContactInvitationsCompanion.insert(
        id: invitationIdHex,
        nonce: code.nonceHex(),
        status: InvitationStatus.pending,
        createdAt: created,
        expiresAt: created.add(validFor),
        contactStubId: drift.Value(stubContactId),
      ),
    );

    // 3) Register the handshake routing both directions so the invitee's
    //    hello AND the eventual ack are admitted by the relay.
    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: code.invitationId,
      nonce: code.nonce,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: code.invitationId,
      nonce: code.nonce,
    );
    try {
      await _relay.establishRouting(
        selfIdentity: addrInvitee,
        peerIdentity: addrInviter,
      );
      await _relay.establishRouting(
        selfIdentity: addrInviter,
        peerIdentity: addrInvitee,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    } on TimeoutException catch (e) {
      throw HandshakeOrchestratorError('relay_unavailable', e);
    }

    // 4) Pending handshake row keeps the orchestrator polling.
    final pendingId = _pendingHandshakeId(
      invitationIdHex,
      HandshakeRole.inviter,
    );
    await _db.upsertPendingHandshake(
      PendingHandshakesCompanion.insert(
        id: pendingId,
        invitationIdHex: invitationIdHex,
        nonceHex: code.nonceHex(),
        role: HandshakeRole.inviter,
        state: HandshakeState.awaitingHello,
        contactStubId: stubContactId,
        createdAt: created,
        updatedAt: created,
        expiresAt: created.add(validFor),
      ),
    );

    startPolling();

    final row = await (_db.select(
      _db.contactInvitations,
    )..where((t) => t.id.equals(invitationIdHex))).getSingle();
    return (
      invitation: row,
      localContactId: stubContactId,
      shortCode: code.renderShort(),
      deepLink: code.renderDeepLink(),
      webLink: code.renderWebLink(),
    );
  }

  /// Inviter accepts an incoming handshake.
  ///
  /// [selfDisplayName] and [selfAvatarId] are the LOCAL user's identity
  /// values (typically read from `AppPreferences`) shipped inside the
  /// ack envelope so the invitee can render the new connected contact.
  /// Sends the `ack`, promotes the stub Contact to connected with the
  /// invitee's display name / avatar, and registers the steady-state
  /// routing on the relay.
  Future<void> acceptIncoming(
    String handshakeId, {
    required String selfDisplayName,
    required String selfAvatarId,
  }) async {
    final row = await _db.getPendingHandshake(handshakeId);
    if (row == null) {
      throw HandshakeOrchestratorError('unknown');
    }
    if (row.role != HandshakeRole.inviter ||
        row.state != HandshakeState.helloReceived) {
      throw HandshakeOrchestratorError('already_completed');
    }
    final peerPubB64 = row.peerLongTermPublicMaterialB64;
    if (peerPubB64 == null) {
      throw HandshakeOrchestratorError('unknown');
    }
    await _finalizeInviterAccept(
      handshakeRow: row,
      peerPubBytes: RelayRouting.unb64(peerPubB64),
      peerDisplayName: row.peerDisplayName,
      peerAvatarId: row.peerAvatarId,
      selfDisplayName: selfDisplayName,
      selfAvatarId: selfAvatarId,
    );
  }

  /// Inviter rejects an incoming handshake. Sends a `rejected` ack so
  /// the invitee gets a documented signal back, then drops the local
  /// stub Contact (no promotion happens).
  Future<void> rejectIncoming(String handshakeId) async {
    final row = await _db.getPendingHandshake(handshakeId);
    if (row == null) {
      throw HandshakeOrchestratorError('unknown');
    }
    if (row.role != HandshakeRole.inviter) {
      throw HandshakeOrchestratorError('unknown');
    }
    final peerPubB64 = row.peerLongTermPublicMaterialB64;
    if (peerPubB64 == null) {
      throw HandshakeOrchestratorError('unknown');
    }
    final invitationIdBytes = _hexDecode(row.invitationIdHex);
    final nonceBytes = _hexDecode(row.nonceHex);
    final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final inviterLongTermPub = await _identity.publicKey();
    final inviteePub = RelayRouting.unb64(peerPubB64);

    final ackFrame = await EnvelopeCodec.encryptAck(
      envelope: AckEnvelope(
        invitationId: invitationIdBytes,
        inviterLongTermPublicKey: inviterLongTermPub,
        accepted: false,
      ),
      invitationNonce: nonceBytes,
      inviterHandshakePrivateKey: inviterHandshakePriv,
      inviteeLongTermPublicKey: inviteePub,
    );
    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    try {
      await _relay.postEnvelope(
        senderIdentity: addrInviter,
        recipientIdentity: addrInvitee,
        idempotencyKey: _randomBytes(16),
        ciphertext: ackFrame,
        kind: EnvelopeKind.ack,
        ttl: _ackTtl,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    }

    // Drop the local stub: rejection means no relationship was formed.
    await _contacts.deleteLocally(row.contactStubId);

    await _markHandshake(row.id, state: HandshakeState.rejected);
    await _decommissionHandshakeAddresses(
      addrInviter: addrInviter,
      addrInvitee: addrInvitee,
    );
    await refreshIncomingHandshakes();
  }

  // ---------------------------------------------------------------------
  // Invitee side
  // ---------------------------------------------------------------------

  /// Invitee submits a parsed invitation code: this method creates the
  /// stub Contact, encrypts the `hello` envelope, posts it to the
  /// inviter's handshake address, persists a polling row, and starts
  /// polling so the ack will be picked up.
  Future<RedeemHandshakeResult> redeemInvitation({
    required InvitationCode code,
    required String selfDisplayName,
    required String selfAvatarId,
  }) async {
    final created = _now().toUtc();
    final invitationIdHex = code.invitationIdHex();
    final stubContactId = 'contact:redeemed:$invitationIdHex';

    final pendingId = _pendingHandshakeId(
      invitationIdHex,
      HandshakeRole.invitee,
    );
    final existing = await _db.getPendingHandshake(pendingId);
    if (existing != null && existing.state != HandshakeState.failed) {
      throw HandshakeOrchestratorError('already_completed');
    }

    final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
      invitationId: code.invitationId,
      nonce: code.nonce,
    );
    final inviterHandshakePub = await RelayRouting.handshakePublicKey(
      inviterHandshakePriv,
    );

    final inviteePriv = await _identity.loadOrCreatePrivateKey();
    final inviteePub = await _identity.publicKey();

    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: code.invitationId,
      nonce: code.nonce,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: code.invitationId,
      nonce: code.nonce,
    );

    // Local stub — replaced by the inviter's profile once we get the ack.
    await _contacts.upsertLocalOnly(
      id: stubContactId,
      displayName: 'Pending handshake',
      avatarId: selfAvatarId,
      createdAt: created,
      updatedAt: created,
    );

    // Encrypt the hello envelope.
    final helloFrame = await EnvelopeCodec.encryptHello(
      envelope: HelloEnvelope(
        invitationId: code.invitationId,
        inviteeLongTermPublicKey: inviteePub,
        displayName: selfDisplayName,
        avatarId: selfAvatarId,
        echoedNonce: code.nonce,
      ),
      invitationNonce: code.nonce,
      inviteeLongTermPrivateKey: inviteePriv,
      inviterHandshakePublicKey: inviterHandshakePub,
    );

    // Post the envelope. The inviter has already pre-registered the
    // routing relationship at code-generation time.
    try {
      await _relay.postEnvelope(
        senderIdentity: addrInvitee,
        recipientIdentity: addrInviter,
        idempotencyKey: _randomBytes(16),
        ciphertext: helloFrame,
        kind: EnvelopeKind.hello,
        ttl: _helloTtl,
      );
    } on RelayClientError catch (e) {
      // Roll back local stub so an unsuccessful retry doesn't leave
      // orphaned rows behind.
      await _contacts.deleteLocally(stubContactId);
      throw HandshakeOrchestratorError(
        e.isNoRouting ? 'expired_code' : 'relay_error',
        e,
      );
    } on TimeoutException catch (e) {
      await _contacts.deleteLocally(stubContactId);
      throw HandshakeOrchestratorError('relay_unavailable', e);
    }

    await _db.upsertPendingHandshake(
      PendingHandshakesCompanion.insert(
        id: pendingId,
        invitationIdHex: invitationIdHex,
        nonceHex: code.nonceHex(),
        role: HandshakeRole.invitee,
        state: HandshakeState.awaitingAck,
        contactStubId: stubContactId,
        createdAt: created,
        updatedAt: created,
        expiresAt: created.add(_helloTtl),
      ),
    );

    startPolling();

    return RedeemHandshakeResult(
      handshakeId: pendingId,
      localContactId: stubContactId,
    );
  }

  // ---------------------------------------------------------------------
  // Polling loop
  // ---------------------------------------------------------------------

  /// Returns the current state of the pending handshake row with the given
  /// id, or `null` if the row has been removed (e.g. cleaned up after
  /// completion in a future revision). The returned value is one of the
  /// [HandshakeState] constants. Used by the invitee side to observe the
  /// outcome of an in-flight redeem so the UI can react when the ack
  /// lands (completed) or the inviter rejects (rejected).
  Future<String?> pendingHandshakeState(String handshakeId) async {
    final row = await _db.getPendingHandshake(handshakeId);
    return row?.state;
  }

  /// Returns the `lastErrorCode` recorded on the pending handshake row, or
  /// `null` if no error was stored. Used together with [pendingHandshakeState]
  /// to surface specific failure reasons to the UI.
  Future<String?> pendingHandshakeErrorCode(String handshakeId) async {
    final row = await _db.getPendingHandshake(handshakeId);
    return row?.lastErrorCode;
  }

  /// Fetches each non-terminal handshake's inbox and processes any
  /// envelope it finds. Safe to call from a Timer or manually from a
  /// pull-to-refresh action.
  Future<void> processAllPendingHandshakes() async {
    final rows = await activePendingHandshakeRows();
    if (rows.isEmpty) {
      await refreshIncomingHandshakes();
      final hasConnected = (await _contacts.list()).any(
        (c) => c.kind == 'connected',
      );
      if (!hasConnected) {
        stopPolling();
      }
      return;
    }
    for (final row in rows) {
      try {
        await _processOne(row);
      } catch (e, st) {
        debugPrint('handshake row ${row.id} poll error: $e\n$st');
        await _markHandshake(
          row.id,
          lastErrorCode: e is HandshakeOrchestratorError ? e.code : 'unknown',
        );
      }
    }
    await refreshIncomingHandshakes();
  }

  Future<List<PendingHandshake>> activePendingHandshakeRows() async {
    final rows = await _db.listPendingHandshakes();
    return rows.where(_shouldPollHandshakeRow).toList(growable: false);
  }

  Future<List<PendingHandshake>> allPendingHandshakeRowsForDiagnostics() {
    return _db.listPendingHandshakes();
  }

  bool _shouldPollHandshakeRow(PendingHandshake row) {
    if (row.state == HandshakeState.awaitingHello ||
        row.state == HandshakeState.awaitingAck) {
      return true;
    }
    if (row.state != HandshakeState.failed) return false;
    final code = row.lastErrorCode;
    return code.isEmpty ||
        code == 'unknown' ||
        code == 'relay_error' ||
        code == 'relay_unavailable';
  }

  /// Polls the relay steady-state inbox once per connected contact for
  /// inbound [EnvelopeKind.profileUpdate] and [EnvelopeKind.disconnect].
  ///
  /// UIs should listen to [steadyStateInboxTick] and refresh contact rows.
  Future<void> pollSteadyStateInboxes() async {
    final connected = (await _contacts.list())
        .where((c) => c.kind == 'connected')
        .toList();
    if (connected.isEmpty) return;

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();

    for (final contact in connected) {
      final peerB64 = contact.peerPublicMaterial;
      if (peerB64 == null || peerB64.isEmpty) continue;

      final Uint8List peerPub;
      try {
        peerPub = RelayRouting.unb64(peerB64);
      } catch (_) {
        continue;
      }

      final Uint8List myListen = await RelayRouting.steadyStateAddress(
        firstPub: selfPub,
        secondPub: peerPub,
      );
      final List<RelayEnvelopeView> envs;
      try {
        envs = await _relay.fetchInbox(recipient: myListen);
      } on RelayClientError {
        continue;
      } on TimeoutException {
        continue;
      }
      for (final env in envs) {
        try {
          if (env.kind == EnvelopeKind.disconnect) {
            await _handleInboundDisconnect(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
            );
          } else if (env.kind == EnvelopeKind.profileUpdate) {
            await _handleInboundProfileUpdate(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
            );
          } else {
            await _relay.ackEnvelope(
              envelopeId: env.envelopeId,
              recipient: myListen,
            );
          }
        } catch (e, st) {
          debugPrint('steady inbox env ${env.envelopeId} failed: $e\n$st');
          try {
            await _relay.ackEnvelope(
              envelopeId: env.envelopeId,
              recipient: myListen,
            );
          } catch (_) {
            // ignore
          }
        }
      }
    }
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _maybeRelayDisconnectSteady(
    Uint8List selfSteady,
    Uint8List peerSteady,
  ) async {
    try {
      await _relay.disconnectRouting(
        selfIdentity: selfSteady,
        peerIdentity: peerSteady,
      );
    } on RelayClientError catch (e) {
      debugPrint('steady disconnectRouting failed: $e');
    } on TimeoutException catch (e) {
      debugPrint('steady disconnectRouting timed out: $e');
    }
  }

  Future<void> _handleInboundDisconnect({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
  }) async {
    final DisconnectEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptDisconnect(
        frame: envelope.ciphertext,
        receiverLongTermPrivateKey: selfPriv,
      );
    } on EnvelopeDecryptionError {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }
    if (!_bytesEqual(decrypted.senderLongTermPublicKey, peerPub)) {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }

    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );

    final routingB64 = contact.relayRoutingId;
    await _contacts.demoteToLocalOnly(contact.id);
    if (routingB64 != null && routingB64.isNotEmpty) {
      await _maybeRelayDisconnectSteady(
        myListenAddr,
        RelayRouting.unb64(routingB64),
      );
    }
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    await _contactNotifications.contactDisconnected(
      displayName: contact.displayName,
    );
  }

  Future<void> _handleInboundProfileUpdate({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
  }) async {
    final ProfileUpdateEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptProfileUpdate(
        frame: envelope.ciphertext,
        receiverLongTermPrivateKey: selfPriv,
      );
    } on EnvelopeDecryptionError {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }
    if (!_bytesEqual(decrypted.senderLongTermPublicKey, peerPub)) {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }

    if (decrypted.hasHowILabelYou) {
      final raw = decrypted.howILabelYou.trim();
      await _contacts.setTheirLabelForMe(contact.id, raw.isEmpty ? null : raw);
    }

    final dn = decrypted.displayName.trim();
    final av = decrypted.avatarId.trim();
    if (dn.isNotEmpty || av.isNotEmpty) {
      final newDn = dn.isNotEmpty ? dn : contact.displayName;
      final newAv = av.isNotEmpty ? av : contact.avatarId;
      final label = contact.localDisplayLabel?.trim();
      if (label != null && label.isNotEmpty) {
        if (label == newDn.trim()) {
          await _contacts.clearLocalDisplayLabel(contact.id);
        }
      }
      await _contacts.rename(
        id: contact.id,
        displayName: newDn,
        avatarId: newAv,
      );
      if (label != null && label.isNotEmpty && label != newDn.trim()) {
        profileLabelConflict.value = ProfileLabelConflict(
          contactId: contact.id,
          newCanonicalDisplayName: newDn,
          localDisplayLabel: label,
        );
      }
    }

    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
  }

  Future<void> _processOne(PendingHandshake row) async {
    if (row.expiresAt.isBefore(_now().toUtc())) {
      await _markHandshake(
        row.id,
        state: HandshakeState.failed,
        lastErrorCode: 'expired',
      );
      return;
    }
    final invitationIdBytes = _hexDecode(row.invitationIdHex);
    final nonceBytes = _hexDecode(row.nonceHex);
    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );

    final listenAddr = row.role == HandshakeRole.inviter
        ? addrInviter
        : addrInvitee;
    final List<RelayEnvelopeView> envs;
    try {
      envs = await _relay.fetchInbox(recipient: listenAddr);
    } on RelayClientError catch (e) {
      // Network issue / 5xx: leave the row alone and try again on the
      // next tick.
      debugPrint('Handshake poll fetch failed for ${row.id}: $e');
      return;
    } on TimeoutException catch (e) {
      debugPrint('Handshake poll fetch timed out for ${row.id}: $e');
      return;
    }
    if (envs.isNotEmpty) {
      debugPrint(
        'Handshake poll fetched ${envs.length} envelope(s) for ${row.id}',
      );
    }
    if (envs.isEmpty) return;

    for (final env in envs) {
      try {
        if (row.role == HandshakeRole.inviter &&
            env.kind == EnvelopeKind.hello) {
          await _handleHelloAsInviter(
            row: row,
            envelope: env,
            invitationIdBytes: invitationIdBytes,
            nonceBytes: nonceBytes,
            listenAddr: addrInviter,
          );
        } else if (row.role == HandshakeRole.invitee &&
            env.kind == EnvelopeKind.ack) {
          await _handleAckAsInvitee(
            row: row,
            envelope: env,
            invitationIdBytes: invitationIdBytes,
            nonceBytes: nonceBytes,
            listenAddr: addrInvitee,
            addrInviter: addrInviter,
            addrInvitee: addrInvitee,
          );
        } else {
          // Unexpected kind — ack on relay so we don't loop forever.
          await _relay.ackEnvelope(
            envelopeId: env.envelopeId,
            recipient: listenAddr,
          );
        }
      } catch (e, st) {
        debugPrint('envelope ${env.envelopeId} failed: $e\n$st');
        await _relay.ackEnvelope(
          envelopeId: env.envelopeId,
          recipient: listenAddr,
        );
      }
    }
  }

  Future<void> _handleHelloAsInviter({
    required PendingHandshake row,
    required RelayEnvelopeView envelope,
    required Uint8List invitationIdBytes,
    required Uint8List nonceBytes,
    required Uint8List listenAddr,
  }) async {
    // Validate that the local invitation row is still pending. Once a
    // hello has been validated (whether the inviter accepted or
    // rejected), the nonce is consumed: subsequent hellos referencing
    // the same invitation are dropped here.
    final invitationRow = await (_db.select(
      _db.contactInvitations,
    )..where((t) => t.id.equals(row.invitationIdHex))).getSingleOrNull();
    if (invitationRow == null ||
        invitationRow.status != InvitationStatus.pending) {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: listenAddr,
      );
      return;
    }

    final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final HelloEnvelope hello;
    try {
      hello = await EnvelopeCodec.decryptHello(
        frame: envelope.ciphertext,
        invitationNonce: nonceBytes,
        inviterHandshakePrivateKey: inviterHandshakePriv,
      );
    } on EnvelopeDecryptionError {
      // Bad envelope: ACK to discard it, stay awaiting.
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: listenAddr,
      );
      return;
    }

    // Nonce consumed; further hellos are ignored.
    await _invitations.markUsed(row.invitationIdHex, now: _now().toUtc());

    // Stash the peer identity + profile on the pending row so the
    // confirmation UI can render it. The decision (accept/reject)
    // happens later via [acceptIncoming] / [rejectIncoming].
    await _markHandshake(
      row.id,
      state: HandshakeState.helloReceived,
      peerLongTermPublicMaterialB64: RelayRouting.b64(
        hello.inviteeLongTermPublicKey,
      ),
      peerDisplayName: hello.displayName,
      peerAvatarId: hello.avatarId,
    );

    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: listenAddr,
    );
    await _contactNotifications.contactAddRequestReceived(
      displayName: hello.displayName,
    );
  }

  Future<void> _handleAckAsInvitee({
    required PendingHandshake row,
    required RelayEnvelopeView envelope,
    required Uint8List invitationIdBytes,
    required Uint8List nonceBytes,
    required Uint8List listenAddr,
    required Uint8List addrInviter,
    required Uint8List addrInvitee,
  }) async {
    final inviteePriv = await _identity.loadOrCreatePrivateKey();
    final AckEnvelope ack;
    try {
      ack = await EnvelopeCodec.decryptAck(
        frame: envelope.ciphertext,
        invitationId: invitationIdBytes,
        invitationNonce: nonceBytes,
        inviteeLongTermPrivateKey: inviteePriv,
      );
    } on EnvelopeDecryptionError {
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: listenAddr,
      );
      return;
    }

    if (ack.accepted) {
      await _finalizeInviteeAccept(row: row, ack: ack);
    } else {
      // Inviter rejected: drop the local stub, mark row rejected.
      await _contacts.deleteLocally(row.contactStubId);
      await _markHandshake(
        row.id,
        state: HandshakeState.rejected,
        peerLongTermPublicMaterialB64: RelayRouting.b64(
          ack.inviterLongTermPublicKey,
        ),
      );
    }
    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: listenAddr,
    );
    await _decommissionHandshakeAddresses(
      addrInviter: addrInviter,
      addrInvitee: addrInvitee,
    );
  }

  // ---------------------------------------------------------------------
  // Inviter accept finalisation
  // ---------------------------------------------------------------------

  Future<void> _finalizeInviterAccept({
    required PendingHandshake handshakeRow,
    required Uint8List peerPubBytes,
    required String peerDisplayName,
    required String peerAvatarId,
    required String selfDisplayName,
    required String selfAvatarId,
  }) async {
    final invitationIdBytes = _hexDecode(handshakeRow.invitationIdHex);
    final nonceBytes = _hexDecode(handshakeRow.nonceHex);
    final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final inviterLongTermPub = await _identity.publicKey();

    // Encrypt the ack with our LONG-TERM pub in the header so the invitee
    // learns it for the first time. The plaintext carries our chosen
    // display name + avatar so the invitee can render us as a connected
    // contact.
    final ackFrame = await EnvelopeCodec.encryptAck(
      envelope: AckEnvelope(
        invitationId: invitationIdBytes,
        inviterLongTermPublicKey: inviterLongTermPub,
        accepted: true,
        displayName: selfDisplayName,
        avatarId: selfAvatarId,
      ),
      invitationNonce: nonceBytes,
      inviterHandshakePrivateKey: inviterHandshakePriv,
      inviteeLongTermPublicKey: peerPubBytes,
    );
    final addrInviter = await RelayRouting.inviterHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );
    final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
      invitationId: invitationIdBytes,
      nonce: nonceBytes,
    );

    try {
      await _relay.postEnvelope(
        senderIdentity: addrInviter,
        recipientIdentity: addrInvitee,
        idempotencyKey: _randomBytes(16),
        ciphertext: ackFrame,
        kind: EnvelopeKind.ack,
        ttl: _ackTtl,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    }

    // Register the steady-state routing on the relay.
    final selfListenAddr = await RelayRouting.steadyStateAddress(
      firstPub: inviterLongTermPub,
      secondPub: peerPubBytes,
    );
    final peerListenAddr = await RelayRouting.steadyStateAddress(
      firstPub: peerPubBytes,
      secondPub: inviterLongTermPub,
    );
    try {
      await _relay.establishRouting(
        selfIdentity: selfListenAddr,
        peerIdentity: peerListenAddr,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    }

    // Promote the stub Contact and write peer material + routing.
    await _contacts.promoteToConnected(
      id: handshakeRow.contactStubId,
      relayRoutingIdB64: RelayRouting.b64(peerListenAddr),
      peerPublicMaterialB64: RelayRouting.b64(peerPubBytes),
      displayName: peerDisplayName,
      avatarId: peerAvatarId,
    );

    await _markHandshake(handshakeRow.id, state: HandshakeState.completed);
    await _decommissionHandshakeAddresses(
      addrInviter: addrInviter,
      addrInvitee: addrInvitee,
    );
    await refreshIncomingHandshakes();
  }

  Future<void> _finalizeInviteeAccept({
    required PendingHandshake row,
    required AckEnvelope ack,
  }) async {
    final inviteePub = await _identity.publicKey();
    final peerListenAddr = await RelayRouting.steadyStateAddress(
      firstPub: ack.inviterLongTermPublicKey,
      secondPub: inviteePub,
    );
    final selfListenAddr = await RelayRouting.steadyStateAddress(
      firstPub: inviteePub,
      secondPub: ack.inviterLongTermPublicKey,
    );

    try {
      await _relay.establishRouting(
        selfIdentity: selfListenAddr,
        peerIdentity: peerListenAddr,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    }

    await _contacts.promoteToConnected(
      id: row.contactStubId,
      relayRoutingIdB64: RelayRouting.b64(peerListenAddr),
      peerPublicMaterialB64: RelayRouting.b64(ack.inviterLongTermPublicKey),
      displayName: ack.displayName.isEmpty ? null : ack.displayName,
      avatarId: ack.avatarId.isEmpty ? null : ack.avatarId,
    );

    await _markHandshake(
      row.id,
      state: HandshakeState.completed,
      peerLongTermPublicMaterialB64: RelayRouting.b64(
        ack.inviterLongTermPublicKey,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Steady-state envelopes
  // ---------------------------------------------------------------------

  /// Sends a `profile_update` envelope to every connected contact in the
  /// local store. Callers should invoke this when the local user changes
  /// their own display name or avatar.
  Future<int> broadcastProfileUpdate({
    required String displayName,
    required String avatarId,
  }) async {
    final all = await _contacts.list();
    final connected = all.where((c) => c.kind == 'connected').toList();
    if (connected.isEmpty) return 0;

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    var dispatched = 0;
    for (final contact in connected) {
      final peerPubB64 = contact.peerPublicMaterial;
      if (peerPubB64 == null || peerPubB64.isEmpty) continue;
      final peerPub = RelayRouting.unb64(peerPubB64);
      final howLabel = (contact.localDisplayLabel ?? '').trim();
      final frame = await EnvelopeCodec.encryptProfileUpdate(
        envelope: ProfileUpdateEnvelope(
          senderLongTermPublicKey: selfPub,
          displayName: displayName,
          avatarId: avatarId,
          hasHowILabelYou: true,
          howILabelYou: howLabel,
        ),
        senderLongTermPrivateKey: selfPriv,
        peerLongTermPublicKey: peerPub,
      );
      final selfAddr = await RelayRouting.steadyStateAddress(
        firstPub: selfPub,
        secondPub: peerPub,
      );
      final peerAddr = await RelayRouting.steadyStateAddress(
        firstPub: peerPub,
        secondPub: selfPub,
      );
      try {
        await _relay.postEnvelope(
          senderIdentity: selfAddr,
          recipientIdentity: peerAddr,
          idempotencyKey: _randomBytes(16),
          ciphertext: frame,
          kind: EnvelopeKind.profileUpdate,
          ttl: _steadyTtl,
        );
        dispatched++;
      } on RelayClientError catch (e) {
        debugPrint('profile_update to ${contact.id} failed: $e');
      } on TimeoutException {
        // Best-effort; updates flow on next change.
      }
    }
    return dispatched;
  }

  /// Pushes the local user's canonical profile plus how they list [contactId]
  /// on this device, so the peer can surface it under profile appearances.
  Future<void> notifyPeerOfLocalDisplayLabelChange(String contactId) async {
    final contact = await _contacts.get(contactId);
    if (contact == null || contact.kind != 'connected') return;
    final peerPubB64 = contact.peerPublicMaterial;
    if (peerPubB64 == null || peerPubB64.isEmpty) return;

    final prefs = await AppPreferences.load();
    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    final peerPub = RelayRouting.unb64(peerPubB64);
    final howLabel = (contact.localDisplayLabel ?? '').trim();
    final frame = await EnvelopeCodec.encryptProfileUpdate(
      envelope: ProfileUpdateEnvelope(
        senderLongTermPublicKey: selfPub,
        displayName: prefs.displayName,
        avatarId: prefs.avatarId,
        hasHowILabelYou: true,
        howILabelYou: howLabel,
      ),
      senderLongTermPrivateKey: selfPriv,
      peerLongTermPublicKey: peerPub,
    );
    final selfAddr = await RelayRouting.steadyStateAddress(
      firstPub: selfPub,
      secondPub: peerPub,
    );
    final peerAddr = await RelayRouting.steadyStateAddress(
      firstPub: peerPub,
      secondPub: selfPub,
    );
    try {
      await _relay.postEnvelope(
        senderIdentity: selfAddr,
        recipientIdentity: peerAddr,
        idempotencyKey: _randomBytes(16),
        ciphertext: frame,
        kind: EnvelopeKind.profileUpdate,
        ttl: _steadyTtl,
      );
      steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    } on RelayClientError catch (e) {
      debugPrint('profile_update (label) to $contactId failed: $e');
    } on TimeoutException {
      // best-effort
    }
  }

  /// Sends a `disconnect` envelope to a single connected contact and
  /// demotes the local row back to `local-only`.
  Future<void> sendDisconnect(String contactId) async {
    final contact = await _contacts.get(contactId);
    if (contact == null || contact.kind != 'connected') {
      throw HandshakeOrchestratorError('unknown');
    }
    final peerPubB64 = contact.peerPublicMaterial;
    if (peerPubB64 == null || peerPubB64.isEmpty) {
      throw HandshakeOrchestratorError('unknown');
    }
    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    final peerPub = RelayRouting.unb64(peerPubB64);

    final frame = await EnvelopeCodec.encryptDisconnect(
      envelope: DisconnectEnvelope(senderLongTermPublicKey: selfPub),
      senderLongTermPrivateKey: selfPriv,
      peerLongTermPublicKey: peerPub,
    );
    final selfAddr = await RelayRouting.steadyStateAddress(
      firstPub: selfPub,
      secondPub: peerPub,
    );
    final peerAddr = await RelayRouting.steadyStateAddress(
      firstPub: peerPub,
      secondPub: selfPub,
    );

    try {
      await _relay.postEnvelope(
        senderIdentity: selfAddr,
        recipientIdentity: peerAddr,
        idempotencyKey: _randomBytes(16),
        ciphertext: frame,
        kind: EnvelopeKind.disconnect,
        ttl: _steadyTtl,
      );
      // Best-effort: also tell the relay our side is going down for this
      // pair, so future envelopes from us are rejected.
      await _relay.disconnectRouting(
        selfIdentity: selfAddr,
        peerIdentity: peerAddr,
      );
    } on RelayClientError catch (e) {
      throw HandshakeOrchestratorError('relay_error', e);
    } on TimeoutException catch (e) {
      throw HandshakeOrchestratorError('relay_unavailable', e);
    }

    await _contacts.demoteToLocalOnly(contactId);
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Future<void> _decommissionHandshakeAddresses({
    required Uint8List addrInviter,
    required Uint8List addrInvitee,
  }) async {
    // The relay's /v1/disconnect marks a routing relationship as
    // "disconnecting": existing envelopes can still be ack'd but no new
    // ones will be accepted. We tear down both directions of the
    // handshake pair so a leaked code cannot inject further hellos.
    try {
      await _relay.disconnectRouting(
        selfIdentity: addrInvitee,
        peerIdentity: addrInviter,
      );
    } on RelayClientError catch (e) {
      debugPrint('handshake decommission (invitee->inviter) failed: $e');
    }
    try {
      await _relay.disconnectRouting(
        selfIdentity: addrInviter,
        peerIdentity: addrInvitee,
      );
    } on RelayClientError catch (e) {
      debugPrint('handshake decommission (inviter->invitee) failed: $e');
    }
  }

  Future<void> _markHandshake(
    String id, {
    String? state,
    String? peerLongTermPublicMaterialB64,
    String? peerDisplayName,
    String? peerAvatarId,
    String? lastErrorCode,
  }) async {
    final now = _now().toUtc();
    await (_db.update(
      _db.pendingHandshakes,
    )..where((t) => t.id.equals(id))).write(
      PendingHandshakesCompanion(
        state: state == null ? const drift.Value.absent() : drift.Value(state),
        peerLongTermPublicMaterialB64: peerLongTermPublicMaterialB64 == null
            ? const drift.Value.absent()
            : drift.Value(peerLongTermPublicMaterialB64),
        peerDisplayName: peerDisplayName == null
            ? const drift.Value.absent()
            : drift.Value(peerDisplayName),
        peerAvatarId: peerAvatarId == null
            ? const drift.Value.absent()
            : drift.Value(peerAvatarId),
        lastErrorCode: lastErrorCode == null
            ? const drift.Value.absent()
            : drift.Value(lastErrorCode),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<IncomingHandshakeView?> incomingHandshakeForContact(
    String contactId,
  ) async {
    await refreshIncomingHandshakes();
    for (final view in incomingHandshakes.value) {
      if (view.contactStubId == contactId) return view;
    }
    return null;
  }

  Future<void> refreshIncomingHandshakes() async {
    final rows = await _db.listPendingHandshakes(
      statesIn: const [HandshakeState.helloReceived],
    );
    final views = <IncomingHandshakeView>[];
    for (final row in rows) {
      if (row.role != HandshakeRole.inviter) continue;
      final peerPubB64 = row.peerLongTermPublicMaterialB64;
      if (peerPubB64 == null) continue;
      views.add(
        IncomingHandshakeView(
          handshakeId: row.id,
          invitationIdHex: row.invitationIdHex,
          peerDisplayName: row.peerDisplayName,
          peerAvatarId: row.peerAvatarId,
          peerPublicMaterialB64: peerPubB64,
          contactStubId: row.contactStubId,
          receivedAt: row.updatedAt,
        ),
      );
    }
    incomingHandshakes.value = List.unmodifiable(views);
  }

  String _pendingHandshakeId(String invitationIdHex, String role) =>
      '$invitationIdHex:$role';

  Uint8List _hexDecode(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  Uint8List _randomBytes(int count) {
    final r = Random.secure();
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }

  /// Re-load the inviter's display name / avatar from a Contact row so
  /// the ack envelope carries them. Exposed as a hook so future updates
  /// to the local user's profile can flow through without rewiring.
  @visibleForTesting
  Future<({String displayName, String avatarId})> readLocalProfile(
    String stubContactId,
  ) async {
    final c = await _contacts.get(stubContactId);
    return (displayName: c?.displayName ?? '', avatarId: c?.avatarId ?? '');
  }
}
