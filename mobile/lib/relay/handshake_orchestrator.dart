import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../activity/relay_activity_log_service.dart';
import '../contacts/contact_display.dart';
import '../contacts/contact_invitations_repository.dart';
import '../contacts/invitation_code.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../housing/proposals/housing_proposal_transport_service.dart';
import '../housing/proposals/plan_agreement_proposal_service.dart';
import '../housing/realized_expense/realized_expense_ledger_service.dart';
import '../housing/realized_expense/realized_expense_repository.dart';
import '../housing/realized_expense/realized_expense_status.dart';
import '../housing/realized_expense/realized_expense_sync_service.dart';
import '../notifications/contact_notification_service.dart';
import '../notifications/push_notification_service.dart';
import '../prefs/app_preferences.dart';
import 'envelopes.dart';
import 'identity_keystore.dart';
import 'relay_client.dart';
import 'relay_diagnostics.dart';
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

class HousingProposalSendResult {
  const HousingProposalSendResult({
    required this.sentCount,
    required this.failedParticipantIds,
    this.relayStatusByParticipantId = const {},
  });

  final int sentCount;
  final List<String> failedParticipantIds;

  /// Per roster participant id: `queued` (relay POST ok) or `failed`.
  final Map<String, String> relayStatusByParticipantId;
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

  /// Same [RelayClient] passed at construction (used for routing push).
  RelayClient get relayClient => _relay;

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

  /// Optional hook invoked after routing topology changes so the app can
  /// refresh closed-app push token registrations on the relay.
  static Future<void> Function()? refreshClosedAppPushRegistration;

  static void requestClosedAppPushRegistrationSync() {
    final fn = refreshClosedAppPushRegistration;
    if (fn == null) return;
    unawaited(
      fn().catchError((Object e, StackTrace st) {
        debugPrint('Closed-app push registration sync failed: $e\n$st');
      }),
    );
  }

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
  /// Local invitation expiry for [code] when this device created the invite.
  Future<DateTime?> lookupInvitationExpiresAtUtc(InvitationCode code) async {
    final row = await (_db.select(_db.contactInvitations)
          ..where((t) => t.id.equals(code.invitationIdHex())))
        .getSingleOrNull();
    if (row == null || row.status != InvitationStatus.pending) return null;
    return row.expiresAt;
  }

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
    String? reconnectContactId,
  }) async {
    final created = _now().toUtc();
    final code = InvitationCode.generate();
    final invitationIdHex = code.invitationIdHex();
    final stubContactId =
        reconnectContactId ?? 'contact:handshake:$invitationIdHex';

    // 1) Stub Contact (local-only, will be promoted on accept). Reconnection
    // invitations point at the existing disconnected Contact instead.
    if (reconnectContactId == null) {
      await _contacts.upsertLocalOnly(
        id: stubContactId,
        displayName: stubDisplayName,
        avatarId: stubAvatarId,
        createdAt: created,
        updatedAt: created,
      );
    }

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
    requestClosedAppPushRegistrationSync();

    final expiresAt = created.add(validFor);
    final row = await (_db.select(
      _db.contactInvitations,
    )..where((t) => t.id.equals(invitationIdHex))).getSingle();
    return (
      invitation: row,
      localContactId: stubContactId,
      shortCode: code.renderShort(),
      deepLink: code.renderDeepLink(expiresAtUtc: expiresAt),
      webLink: code.renderWebLink(expiresAtUtc: expiresAt),
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
  Future<void> rejectIncoming(
    String handshakeId, {
    String? selfDisplayName,
    String? selfAvatarId,
  }) async {
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
    final String displayName;
    final String avatarId;
    if (selfDisplayName != null && selfAvatarId != null) {
      displayName = selfDisplayName;
      avatarId = selfAvatarId;
    } else {
      final prefs = await AppPreferences.load();
      displayName = selfDisplayName ?? prefs.displayName;
      avatarId = selfAvatarId ?? prefs.avatarId;
    }
    final inviterLongTermPub = await _identity.publicKey();
    final inviteePub = RelayRouting.unb64(peerPubB64);

    final ackFrame = await EnvelopeCodec.encryptAck(
      envelope: AckEnvelope(
        invitationId: invitationIdBytes,
        inviterLongTermPublicKey: inviterLongTermPub,
        accepted: false,
        displayName: displayName,
        avatarId: avatarId,
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
    requestClosedAppPushRegistrationSync();
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
    requestClosedAppPushRegistrationSync();

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
      if (!await _hasSteadyInboxPollTargets()) {
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

  /// Contacts with a stored peer long-term public key, deduped by that key.
  /// Includes `connected` rows and demoted / handshake rows so a reinstall on
  /// the peer device does not hide the inbox when an older row is still stored.
  Future<List<({Contact contact, Uint8List peerPub})>> _steadyInboxPollPeers() async {
    final all = await _contacts.list();
    final seenPeer = <String>{};
    final out = <({Contact contact, Uint8List peerPub})>[];
    for (final c in all) {
      if (c.id.startsWith('contact:local:')) continue;
      final peerB64 = c.peerPublicMaterial;
      if (peerB64 == null || peerB64.isEmpty) continue;
      if (!seenPeer.add(peerB64)) continue;
      try {
        out.add((contact: c, peerPub: RelayRouting.unb64(peerB64)));
      } catch (_) {
        // ignore invalid peer material
      }
    }
    return out;
  }

  Future<bool> _hasSteadyInboxPollTargets() async {
    return (await _steadyInboxPollPeers()).isNotEmpty;
  }

  Future<Contact?> _contactForPeerPublicKey(Uint8List peerPub) async {
    for (final c in await _contacts.list()) {
      final b64 = c.peerPublicMaterial;
      if (b64 == null || b64.isEmpty) continue;
      try {
        if (_bytesEqual(RelayRouting.unb64(b64), peerPub)) return c;
      } catch (_) {
        // ignore
      }
    }
    return null;
  }

  /// Polls the relay steady-state inbox once per known peer public key for
  /// inbound steady envelopes (profile, disconnect, housing proposal, …).
  ///
  /// UIs should listen to [steadyStateInboxTick] and refresh contact rows.
  Future<void> pollSteadyStateInboxes() async {
    try {
      await _pollSteadyStateInboxesBody();
    } catch (e, st) {
      debugPrint('pollSteadyStateInboxes failed: $e\n$st');
    }
  }

  Future<void> _pollSteadyStateInboxesBody() async {
    final targets = await _steadyInboxPollPeers();
    if (targets.isEmpty) {
      final total = (await _contacts.list()).length;
      RelayDiagnostics.logSteadyInbox(
        'steady inbox poll skipped: no peer keys ($total contact row(s))',
      );
      return;
    }
    RelayDiagnostics.logSteadyInbox(
      'steady inbox poll: ${targets.length} peer key(s)',
    );

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();

    for (final target in targets) {
      final contact = target.contact;
      final peerPub = target.peerPub;

      final Uint8List myListen = await RelayRouting.steadyStateAddress(
        firstPub: selfPub,
        secondPub: peerPub,
      );
      final List<RelayEnvelopeView> envs;
      try {
        envs = await _relay.fetchInbox(recipient: myListen);
      } on RelayClientError catch (e) {
        RelayDiagnostics.logSteadyInbox(
          'steady inbox fetch failed for ${contact.id}: $e',
        );
        continue;
      } on TimeoutException catch (e) {
        RelayDiagnostics.logSteadyInbox(
          'steady inbox fetch timed out for ${contact.id}: $e',
        );
        continue;
      }
      if (envs.isEmpty) {
        RelayDiagnostics.logSteadyInbox('steady inbox empty for ${contact.id}');
      } else {
        RelayDiagnostics.logSteadyInbox(
          'steady inbox fetched ${envs.length} envelope(s) for ${contact.id}',
        );
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
          } else if (env.kind == EnvelopeKind.housingProposal) {
            await _handleInboundHousingProposal(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
            );
          } else if (env.kind == EnvelopeKind.housingProposalResponse) {
            await _handleInboundHousingProposalResponse(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
            );
          } else if (env.kind == EnvelopeKind.housingRealizedExpensePropose) {
            await _handleInboundHousingRealizedExpensePropose(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
            );
          } else if (env.kind == EnvelopeKind.housingRealizedExpenseAccept ||
              env.kind == EnvelopeKind.housingRealizedExpenseReject) {
            await _handleInboundHousingRealizedExpenseDecision(
              contact: contact,
              envelope: env,
              myListenAddr: myListen,
              selfPriv: selfPriv,
              peerPub: peerPub,
              kind: env.kind,
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

  /// Ensures the relay has an active steady-state row for [selfListenAddr] and
  /// [peerListenAddr]. Idempotent (re-register after relay wipe or reinstall).
  Future<void> _ensureSteadyRoutingRegistered({
    required Uint8List selfListenAddr,
    required Uint8List peerListenAddr,
  }) async {
    await _relay.establishRouting(
      selfIdentity: selfListenAddr,
      peerIdentity: peerListenAddr,
    );
  }

  /// Recipient routing ids whose inboxes this device polls: steady-state
  /// addresses for each connected contact plus handshake listen addresses
  /// for pending handshakes that still need relay polling.
  Future<List<Uint8List>> routingWakeRecipientIdentities() async {
    final out = <Uint8List>[];
    void addUnique(Uint8List id) {
      for (final e in out) {
        if (_bytesEqual(e, id)) return;
      }
      out.add(id);
    }

    final rows = await _db.listPendingHandshakes();
    for (final row in rows) {
      if (!_shouldPollHandshakeRow(row)) continue;
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
      addUnique(listenAddr);
    }

    final selfPub = await _identity.publicKey();
    final contacts = await _contacts.list();
    for (final contact in contacts) {
      if (contact.kind != 'connected') continue;
      final peerB64 = contact.peerPublicMaterial;
      if (peerB64 == null || peerB64.isEmpty) continue;
      final Uint8List peerPub;
      try {
        peerPub = RelayRouting.unb64(peerB64);
      } catch (_) {
        continue;
      }
      final myListen = await RelayRouting.steadyStateAddress(
        firstPub: selfPub,
        secondPub: peerPub,
      );
      addUnique(myListen);
    }

    return out;
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
    requestClosedAppPushRegistrationSync();
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

  Future<void> _handleInboundHousingProposal({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
  }) async {
    final HousingProposalEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptHousingProposal(
        frame: envelope.ciphertext,
        receiverLongTermPrivateKey: selfPriv,
      );
    } on EnvelopeDecryptionError catch (e, st) {
      debugPrint(
        'housing_proposal decrypt failed for ${contact.id} '
        '(envelope ${envelope.envelopeId}): $e\n$st',
      );
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }
    var senderContact = contact;
    if (!_bytesEqual(decrypted.senderLongTermPublicKey, peerPub)) {
      final matched = await _contactForPeerPublicKey(
        decrypted.senderLongTermPublicKey,
      );
      if (matched == null) {
        debugPrint(
          'housing_proposal sender pubkey mismatch for ${contact.id} '
          '(envelope ${envelope.envelopeId})',
        );
        await _relay.ackEnvelope(
          envelopeId: envelope.envelopeId,
          recipient: myListenAddr,
        );
        return;
      }
      debugPrint(
        'housing_proposal sender matched contact ${matched.id} '
        '(polled via ${contact.id})',
      );
      senderContact = matched;
    }

    final imported = await HousingProposalTransportService(_db)
        .importReceivedProposal(
      proposalJson: decrypted.proposalJson,
      targetParticipantId: decrypted.targetParticipantId,
      senderContactId: senderContact.id,
      senderDisplayName: senderContact.displayName,
      senderAvatarId: senderContact.avatarId,
    );
    debugPrint('housing_proposal imported from ${senderContact.id}');
    await RelayActivityLogService(_db).append(
      kind: RelayActivityLogKinds.housingProposalReceived,
      initiatorKind: RelayActivityLogService.initiatorContact,
      initiatorContactId: senderContact.id,
      initiatorDisplayName: senderContact.displayName,
      planId: imported.planId,
      revisionId: imported.revisionId,
    );
    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    await PushNotificationService.showLocalHousingProposalNotification(
      senderDisplayName: senderContact.displayName,
    );
  }

  Future<void> _handleInboundHousingProposalResponse({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
  }) async {
    final HousingProposalResponseEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptHousingProposalResponse(
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

    await _applyHousingProposalResponse(
      decrypted,
      senderDisplayName: contact.displayName,
    );
    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
  }

  Future<void> _handleInboundHousingRealizedExpensePropose({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
  }) async {
    final HousingRealizedExpenseEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptHousingRealizedExpensePropose(
        frame: envelope.ciphertext,
        receiverLongTermPrivateKey: selfPriv,
      );
    } on EnvelopeDecryptionError catch (e, st) {
      debugPrint(
        'housing_realized_expense decrypt failed for ${contact.id}: $e\n$st',
      );
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }
    var senderContact = contact;
    if (!_bytesEqual(decrypted.senderLongTermPublicKey, peerPub)) {
      final matched = await _contactForPeerPublicKey(
        decrypted.senderLongTermPublicKey,
      );
      if (matched == null) {
        await _relay.ackEnvelope(
          envelopeId: envelope.envelopeId,
          recipient: myListenAddr,
        );
        return;
      }
      senderContact = matched;
    }

    final imported = await RealizedExpenseSyncService(_db).importProposedFromPeer(
      expenseJson: decrypted.expenseJson,
      senderContactId: senderContact.id,
    );
    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );
    if (!imported) return;

    final expenseId = _expenseIdFromProposeJson(decrypted.expenseJson);
    if (expenseId != null) {
      final expense = await RealizedExpenseRepository(_db).getById(expenseId);
      if (expense != null) {
        await RealizedExpenseLedgerService(_db).markPlanActiveUseIfNeeded(
          expense.planId,
        );
      }
    }

    RelayDiagnostics.logHousingRealizedExpense(
      'imported from ${senderContact.id}',
    );
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    await PushNotificationService.showLocalHousingRealizedExpenseNotification(
      senderDisplayName: senderContact.displayName,
      expenseId: expenseId,
    );
  }

  String? _expenseIdFromProposeJson(String expenseJson) {
    try {
      final map = jsonDecode(expenseJson) as Map<String, dynamic>;
      final id = map['expense_id'] as String?;
      if (id == null || id.isEmpty) return null;
      return id;
    } on Object {
      return null;
    }
  }

  Future<void> _handleInboundHousingRealizedExpenseDecision({
    required Contact contact,
    required RelayEnvelopeView envelope,
    required Uint8List myListenAddr,
    required Uint8List selfPriv,
    required Uint8List peerPub,
    required int kind,
  }) async {
    final HousingRealizedExpenseDecisionEnvelope decrypted;
    try {
      decrypted = await EnvelopeCodec.decryptHousingRealizedExpenseDecision(
        kind: kind,
        frame: envelope.ciphertext,
        receiverLongTermPrivateKey: selfPriv,
      );
    } on EnvelopeDecryptionError catch (e, st) {
      debugPrint(
        'housing_realized_expense decision decrypt failed for ${contact.id}: '
        '$e\n$st',
      );
      await _relay.ackEnvelope(
        envelopeId: envelope.envelopeId,
        recipient: myListenAddr,
      );
      return;
    }
    var senderContact = contact;
    if (!_bytesEqual(decrypted.senderLongTermPublicKey, peerPub)) {
      final matched = await _contactForPeerPublicKey(
        decrypted.senderLongTermPublicKey,
      );
      if (matched == null) {
        await _relay.ackEnvelope(
          envelopeId: envelope.envelopeId,
          recipient: myListenAddr,
        );
        return;
      }
      senderContact = matched;
    }

    final applied = await RealizedExpenseSyncService(_db).importDecisionFromPeer(
      decisionJson: decrypted.decisionJson,
      senderContactId: senderContact.id,
    );
    await _relay.ackEnvelope(
      envelopeId: envelope.envelopeId,
      recipient: myListenAddr,
    );
    if (!applied) return;

    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    if (kind == EnvelopeKind.housingRealizedExpenseReject) {
      await PushNotificationService.showLocalHousingRealizedExpenseRejectedNotification(
        senderDisplayName: senderContact.displayName,
      );
    }
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
    final notificationDisplayName = ack.displayName.isEmpty
        ? 'Unknown'
        : ack.displayName;
    await _contactNotifications.contactAddRequestResolved(
      displayName: notificationDisplayName,
      accepted: ack.accepted,
    );
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
    startPolling();
    requestClosedAppPushRegistrationSync();
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

    final peerPublicMaterialB64 = RelayRouting.b64(
      ack.inviterLongTermPublicKey,
    );
    final reconnectCandidate = await _contacts.disconnectedReconnectCandidate(
      peerPublicMaterialB64: peerPublicMaterialB64,
      displayName: ack.displayName.isEmpty ? null : ack.displayName,
      avatarId: ack.avatarId.isEmpty ? null : ack.avatarId,
    );
    final promoteContactId = reconnectCandidate?.id ?? row.contactStubId;
    await _contacts.promoteToConnected(
      id: promoteContactId,
      relayRoutingIdB64: RelayRouting.b64(peerListenAddr),
      peerPublicMaterialB64: peerPublicMaterialB64,
      displayName: ack.displayName.isEmpty ? null : ack.displayName,
      avatarId: ack.avatarId.isEmpty ? null : ack.avatarId,
    );
    if (promoteContactId != row.contactStubId) {
      await _contacts.deleteLocally(row.contactStubId);
    }

    await _markHandshake(
      row.id,
      state: HandshakeState.completed,
      peerLongTermPublicMaterialB64: RelayRouting.b64(
        ack.inviterLongTermPublicKey,
      ),
    );
    startPolling();
    requestClosedAppPushRegistrationSync();
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

  Future<HousingProposalSendResult> sendHousingProposalToPlanParticipants({
    required String planId,
    required String revisionId,
  }) async {
    final participants = (await _db.listParticipants())
        .where((p) => p.id.startsWith('$planId:p'))
        .toList(growable: false);
    if (participants.isEmpty) {
      debugPrint('housing_proposal no participant rows for $planId');
      return const HousingProposalSendResult(
        sentCount: 0,
        failedParticipantIds: <String>[],
        relayStatusByParticipantId: {},
      );
    }

    final transport = HousingProposalTransportService(_db);
    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    final allConnectedContacts = (await _contacts.list())
        .where((c) => c.kind == 'connected')
        .toList(growable: false);
    var sent = 0;
    final failed = <String>[];
    final relayStatusByParticipantId = <String, String>{};

    for (final participant in participants) {
      final contactId = participant.contactId;
      final contact = contactId == null ? null : await _contacts.get(contactId);
      final targets = _housingProposalTargetContacts(
        participant: participant,
        selectedContact: contact,
        connectedContacts: allConnectedContacts,
        planParticipantCount: participants.length,
      );
      if (targets.isEmpty) {
        debugPrint(
          'housing_proposal no connected target for ${participant.id}',
        );
        failed.add(participant.id);
        relayStatusByParticipantId[participant.id] = 'failed';
        continue;
      }

      var deliveredToAnyTarget = false;
      try {
        final proposalJson = await transport.exportProposalForParticipant(
          planId: planId,
          revisionId: revisionId,
          targetParticipantId: participant.id,
        );
        for (final target in targets) {
          final peerPubB64 = target.peerPublicMaterial;
          if (peerPubB64 == null || peerPubB64.isEmpty) continue;
          try {
            final peerPub = RelayRouting.unb64(peerPubB64);
            final frame = await EnvelopeCodec.encryptHousingProposal(
              envelope: HousingProposalEnvelope(
                senderLongTermPublicKey: selfPub,
                proposalJson: proposalJson,
                targetParticipantId: participant.id,
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
            await _ensureSteadyRoutingRegistered(
              selfListenAddr: selfAddr,
              peerListenAddr: peerAddr,
            );
            await _relay.postEnvelope(
              senderIdentity: selfAddr,
              recipientIdentity: peerAddr,
              idempotencyKey: _randomBytes(16),
              ciphertext: frame,
              kind: EnvelopeKind.housingProposal,
              ttl: _steadyTtl,
            );
            debugPrint(
              'housing_proposal posted for ${participant.id} to ${target.id}',
            );
            deliveredToAnyTarget = true;
          } on Object catch (e) {
            debugPrint(
              'housing_proposal to ${participant.id}/${target.id} failed: $e',
            );
          }
        }
      } on Object catch (e) {
        debugPrint('housing_proposal to ${participant.id} failed: $e');
      }
      if (deliveredToAnyTarget) {
        debugPrint('housing_proposal delivered for ${participant.id}');
        sent++;
        relayStatusByParticipantId[participant.id] = 'queued';
      } else {
        failed.add(participant.id);
        relayStatusByParticipantId[participant.id] = 'failed';
      }
    }

    return HousingProposalSendResult(
      sentCount: sent,
      failedParticipantIds: List.unmodifiable(failed),
      relayStatusByParticipantId: Map.unmodifiable(relayStatusByParticipantId),
    );
  }

  List<Contact> _housingProposalTargetContacts({
    required Participant participant,
    required Contact? selectedContact,
    required List<Contact> connectedContacts,
    required int planParticipantCount,
  }) {
    final targets = <Contact>[];
    final seenPeerMaterial = <String>{};

    void add(Contact? contact) {
      if (contact == null || contact.kind != 'connected') return;
      final peer = contact.peerPublicMaterial;
      if (peer == null || peer.isEmpty || !seenPeerMaterial.add(peer)) return;
      targets.add(contact);
    }

    add(selectedContact);

    final participantName = participant.displayName.trim().toLowerCase();
    final participantAvatar = participant.avatarId.trim();
    for (final contact in connectedContacts) {
      final nameMatches =
          participantName.isNotEmpty &&
          contact.effectiveDisplayName.trim().toLowerCase() == participantName;
      final avatarMatches =
          participantAvatar.isNotEmpty && contact.avatarId == participantAvatar;
      if (nameMatches || avatarMatches) {
        add(contact);
      }
    }

    if (planParticipantCount == 1 && connectedContacts.isNotEmpty) {
      // A rare reinstall/reconnect can leave stale connected rows that still
      // accept relay POSTs but are no longer polled by the peer. For a single
      // invitee plan, fan out to the local connected candidates so the current
      // reinstall identity can receive the proposal.
      for (final contact in connectedContacts) {
        add(contact);
      }
    }

    return targets;
  }

  Future<HousingProposalSendResult> sendHousingProposalResponse({
    required String planId,
    required ProposalResponseStatus status,
    String message = '',
    String? revisionId,
  }) async {
    final transport = HousingProposalTransportService(_db);
    final selectedRevisionId =
        revisionId ?? await transport.pendingRevisionIdForPlan(planId);
    if (selectedRevisionId == null) {
      throw HandshakeOrchestratorError('unknown');
    }
    final selfParticipantId = '$planId:self';
    await transport.expireRevisionIfNeeded(
      planId: planId,
      revisionId: selectedRevisionId,
    );
    await PlanAgreementProposalService(_db).recordResponse(
      revisionId: selectedRevisionId,
      participantId: selfParticipantId,
      status: status,
      message: message,
    );
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(selectedRevisionId);
    final sourcePackageId =
        (payload['sourcePackageId'] as String?) ??
        (payload['packageId'] as String?) ??
        '';
    final sourceRevisionId =
        (payload['sourceRevisionId'] as String?) ??
        (payload['revisionId'] as String?) ??
        selectedRevisionId;
    final sourceParticipantId = await transport.sourceParticipantIdForLocal(
      revisionId: selectedRevisionId,
      localParticipantId: selfParticipantId,
    );

    final response = HousingProposalResponseEnvelope(
      senderLongTermPublicKey: await _identity.publicKey(),
      sourcePackageId: sourcePackageId,
      sourceRevisionId: sourceRevisionId,
      sourceParticipantId: sourceParticipantId,
      status: status.name,
      message: message.trim(),
    );
    final sendResult = await _broadcastHousingProposalResponse(
      planId: planId,
      response: response,
    );
    await RelayActivityLogService(_db).append(
      kind: RelayActivityLogKinds.housingProposalResponse,
      initiatorKind: RelayActivityLogService.initiatorSelf,
      planId: planId,
      packageId: sourcePackageId,
      revisionId: selectedRevisionId,
      details: {'status': status.name},
    );
    if (status == ProposalResponseStatus.accepted) {
      await transport.tryActivatePlanIfUnanimous(
        planId: planId,
        revisionId: selectedRevisionId,
      );
    } else {
      await transport.archiveInvalidatedProposal(
        planId: planId,
        revisionId: selectedRevisionId,
        status: status,
        responderParticipantId: selfParticipantId,
      );
    }
    return sendResult;
  }

  Future<HousingProposalSendResult> _broadcastHousingProposalResponse({
    required String planId,
    required HousingProposalResponseEnvelope response,
  }) async {
    final participants = (await _db.listParticipants())
        .where(
          (p) =>
              (p.id.startsWith('$planId:p') || p.id == '$planId:self') &&
              p.contactId != null,
        )
        .toList(growable: false);
    if (participants.isEmpty) {
      return const HousingProposalSendResult(
        sentCount: 0,
        failedParticipantIds: <String>[],
      );
    }

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    var sent = 0;
    final failed = <String>[];

    for (final participant in participants) {
      final contactId = participant.contactId;
      if (contactId == null) continue;
      final contact = await _contacts.get(contactId);
      final peerPubB64 = contact?.peerPublicMaterial;
      if (contact == null ||
          contact.kind != 'connected' ||
          peerPubB64 == null ||
          peerPubB64.isEmpty) {
        failed.add(participant.id);
        continue;
      }

      try {
        final peerPub = RelayRouting.unb64(peerPubB64);
        final frame = await EnvelopeCodec.encryptHousingProposalResponse(
          envelope: response,
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
        await _ensureSteadyRoutingRegistered(
          selfListenAddr: selfAddr,
          peerListenAddr: peerAddr,
        );
        await _relay.postEnvelope(
          senderIdentity: selfAddr,
          recipientIdentity: peerAddr,
          idempotencyKey: _randomBytes(16),
          ciphertext: frame,
          kind: EnvelopeKind.housingProposalResponse,
          ttl: _steadyTtl,
        );
        sent++;
      } on Object catch (e) {
        debugPrint('housing_proposal_response to ${participant.id} failed: $e');
        failed.add(participant.id);
      }
    }

    return HousingProposalSendResult(
      sentCount: sent,
      failedParticipantIds: List.unmodifiable(failed),
    );
  }

  /// Broadcasts a proposed realized expense to connected co-participants.
  Future<void> sendRealizedExpensePropose({required String expenseId}) async {
    final repo = RealizedExpenseRepository(_db);
    final expense = await repo.getById(expenseId);
    if (expense == null) return;

    final attachments = await repo.attachmentsFor(expenseId);
    final expenseJson = await RealizedExpenseSyncService(_db).buildProposeJson(
      expense: expense,
      attachments: attachments,
    );

    final planId = expense.planId;
    final participants = (await _db.listParticipants())
        .where((p) => p.id.startsWith('$planId:p'))
        .toList(growable: false);
    if (participants.isEmpty) {
      RelayDiagnostics.logHousingRealizedExpense('no peers for $planId');
      return;
    }

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    final allConnectedContacts = (await _contacts.list())
        .where((c) => c.kind == 'connected')
        .toList(growable: false);

    for (final participant in participants) {
      final contactId = participant.contactId;
      final contact = contactId == null ? null : await _contacts.get(contactId);
      final targets = _housingProposalTargetContacts(
        participant: participant,
        selectedContact: contact,
        connectedContacts: allConnectedContacts,
        planParticipantCount: participants.length,
      );
      for (final target in targets) {
        final peerPubB64 = target.peerPublicMaterial;
        if (peerPubB64 == null || peerPubB64.isEmpty) continue;
        try {
          final peerPub = RelayRouting.unb64(peerPubB64);
          final frame = await EnvelopeCodec.encryptHousingRealizedExpensePropose(
            envelope: HousingRealizedExpenseEnvelope(
              senderLongTermPublicKey: selfPub,
              expenseJson: expenseJson,
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
          await _ensureSteadyRoutingRegistered(
            selfListenAddr: selfAddr,
            peerListenAddr: peerAddr,
          );
          await _relay.postEnvelope(
            senderIdentity: selfAddr,
            recipientIdentity: peerAddr,
            idempotencyKey: _randomBytes(16),
            ciphertext: frame,
            kind: EnvelopeKind.housingRealizedExpensePropose,
            ttl: _steadyTtl,
          );
          RelayDiagnostics.logHousingRealizedExpense(
            'posted for $planId to ${target.id}',
          );
        } on Object catch (e) {
          debugPrint(
            'housing_realized_expense to ${participant.id}/${target.id} failed: $e',
          );
        }
      }
    }
    await RealizedExpenseLedgerService(_db).markPlanActiveUseIfNeeded(planId);
  }

  Future<void> sendRealizedExpenseAccept({
    required String expenseId,
    required String participantId,
  }) async {
    await _sendRealizedExpenseDecision(
      expenseId: expenseId,
      participantId: participantId,
      decision: RealizedExpenseDecision.accepted,
      kind: EnvelopeKind.housingRealizedExpenseAccept,
    );
  }

  Future<void> sendRealizedExpenseReject({
    required String expenseId,
    required String participantId,
    required String justification,
  }) async {
    await _sendRealizedExpenseDecision(
      expenseId: expenseId,
      participantId: participantId,
      decision: RealizedExpenseDecision.rejected,
      kind: EnvelopeKind.housingRealizedExpenseReject,
      justification: justification,
    );
  }

  Future<void> _sendRealizedExpenseDecision({
    required String expenseId,
    required String participantId,
    required String decision,
    required int kind,
    String? justification,
  }) async {
    final expense = await RealizedExpenseRepository(_db).getById(expenseId);
    if (expense == null) return;

    final decisionJson = await RealizedExpenseSyncService(_db).buildDecisionJson(
      expenseId: expenseId,
      packageId: expense.packageId,
      participantId: participantId,
      decision: decision,
      justification: justification,
    );

    final planId = expense.planId;
    final participants = (await _db.listParticipants())
        .where((p) => p.id.startsWith('$planId:p'))
        .toList(growable: false);
    if (participants.isEmpty) return;

    final selfPriv = await _identity.loadOrCreatePrivateKey();
    final selfPub = await _identity.publicKey();
    final allConnectedContacts = (await _contacts.list())
        .where((c) => c.kind == 'connected')
        .toList(growable: false);

    for (final participant in participants) {
      final contactId = participant.contactId;
      final contact = contactId == null ? null : await _contacts.get(contactId);
      final targets = _housingProposalTargetContacts(
        participant: participant,
        selectedContact: contact,
        connectedContacts: allConnectedContacts,
        planParticipantCount: participants.length,
      );
      for (final target in targets) {
        final peerPubB64 = target.peerPublicMaterial;
        if (peerPubB64 == null || peerPubB64.isEmpty) continue;
        try {
          final peerPub = RelayRouting.unb64(peerPubB64);
          final frame = await EnvelopeCodec.encryptHousingRealizedExpenseDecision(
            kind: kind,
            envelope: HousingRealizedExpenseDecisionEnvelope(
              senderLongTermPublicKey: selfPub,
              decisionJson: decisionJson,
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
          await _ensureSteadyRoutingRegistered(
            selfListenAddr: selfAddr,
            peerListenAddr: peerAddr,
          );
          await _relay.postEnvelope(
            senderIdentity: selfAddr,
            recipientIdentity: peerAddr,
            idempotencyKey: _randomBytes(16),
            ciphertext: frame,
            kind: kind,
            ttl: _steadyTtl,
          );
        } on Object catch (e) {
          debugPrint(
            'housing_realized_expense decision to ${participant.id}/'
            '${target.id} failed: $e',
          );
        }
      }
    }
  }

  Future<void> _applyHousingProposalResponse(
    HousingProposalResponseEnvelope response, {
    required String senderDisplayName,
  }) async {
    final revision = await _matchingHousingRevision(response.sourceRevisionId);
    if (revision == null) return;
    final transport = HousingProposalTransportService(_db);
    final pkgEarly = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.id.equals(revision.packageId))).getSingleOrNull();
    if (pkgEarly != null) {
      await transport.expireRevisionIfNeeded(
        planId: pkgEarly.planId,
        revisionId: revision.id,
      );
    }
    final revisionPayload =
        jsonDecode(revision.payloadJson) as Map<String, dynamic>;
    if (revisionPayload['lifecycleState'] == 'archived') return;

    ProposalResponseStatus? status;
    for (final candidate in ProposalResponseStatus.values) {
      if (candidate.name == response.status) {
        status = candidate;
        break;
      }
    }
    if (status == null) return;
    final participantId = await transport.localParticipantIdForSource(
      revisionId: revision.id,
      sourceParticipantId: response.sourceParticipantId,
    );
    if (participantId == null) return;
    await PlanAgreementProposalService(_db).recordResponse(
      revisionId: revision.id,
      participantId: participantId,
      status: status,
      message: response.message,
    );
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.id.equals(revision.packageId))).getSingleOrNull();
    if (pkg != null) {
      if (status == ProposalResponseStatus.accepted) {
        await transport.tryActivatePlanIfUnanimous(
          planId: pkg.planId,
          revisionId: revision.id,
        );
      } else {
        await transport.archiveInvalidatedProposal(
          planId: pkg.planId,
          revisionId: revision.id,
          status: status,
          responderParticipantId: participantId,
        );
      }
    }
    await PushNotificationService.showLocalHousingDecisionNotification(
      senderDisplayName: senderDisplayName,
    );
  }

  Future<ProposalRevision?> _matchingHousingRevision(
    String sourceRevisionId,
  ) async {
    final direct = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(sourceRevisionId))).getSingleOrNull();
    if (direct != null) return direct;
    final revisions = await _db.select(_db.proposalRevisions).get();
    for (final revision in revisions) {
      try {
        final payload =
            jsonDecode(revision.payloadJson) as Map<String, dynamic>;
        if (payload['sourceRevisionId'] == sourceRevisionId) {
          return revision;
        }
      } catch (_) {
        // Ignore malformed historical payloads.
      }
    }
    return null;
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
    steadyStateInboxTick.value = steadyStateInboxTick.value + 1;
    requestClosedAppPushRegistrationSync();
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
