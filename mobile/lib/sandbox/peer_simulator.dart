import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import '../contacts/contact_invitations_repository.dart';
import '../contacts/invitation_code.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../device/device_binding_service.dart';
import '../housing/proposals/housing_proposal_revision_state.dart';
import '../housing/proposals/housing_proposal_transport_service.dart';
import '../housing/proposals/plan_agreement_proposal_service.dart';
import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import '../relay/identity_keystore.dart';
import '../relay/testing/fake_relay_client.dart';
import 'sandbox_bot_catalog.dart';
import 'sandbox_mode.dart';
import 'sandbox_relay.dart';

class _SandboxDb extends AppDatabase {
  _SandboxDb(super.e) : super.forTesting();
}

/// One simulated peer installation in the same process.
class SandboxBotPeer {
  SandboxBotPeer({
    required this.displayName,
    required this.avatarId,
    required this.db,
    required this.dbFile,
    required this.identity,
    required this.orchestrator,
    required this.contacts,
  });

  final String displayName;
  final String avatarId;
  final AppDatabase db;
  final File dbFile;
  final IdentityKeystore identity;
  final HandshakeOrchestrator orchestrator;
  final ContactsRepository contacts;
}

/// Spawns bot peers on [SandboxRelay], auto-accepts in-scope peer decisions.
class PeerSimulator {
  PeerSimulator._({
    required FakeRelayClient relay,
    required AppPreferences prefs,
  }) : _relay = relay,
       _prefs = prefs;

  static PeerSimulator? _instance;

  static PeerSimulator? get maybeInstance => _instance;

  static PeerSimulator get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('PeerSimulator.install(...) during sandbox bootstrap.');
    }
    return i;
  }

  static PeerSimulator install({
    required FakeRelayClient relay,
    required AppPreferences prefs,
  }) {
    _instance?.dispose();
    final sim = PeerSimulator._(relay: relay, prefs: prefs);
    _instance = sim;
    relay.onEnvelopeStored = sim._onEnvelopeStored;
    return sim;
  }

  static void clearInstalled() {
    _instance?.dispose();
    _instance = null;
  }

  static const Duration _reactDebounce = Duration(milliseconds: 200);

  final FakeRelayClient _relay;
  final AppPreferences _prefs;
  final List<SandboxBotPeer> _bots = <SandboxBotPeer>[];
  final Random _rng = Random();
  Timer? _reactDebounceTimer;
  bool _reactRunning = false;
  bool _reactNeededAfterRun = false;
  int _reactionsPaused = 0;
  bool _disposed = false;
  int _botSeq = 0;

  /// Test/observability: bot↔bot connect attempts (mesh at invite only).
  @visibleForTesting
  int botPairConnectAttempts = 0;

  List<SandboxBotPeer> get bots => List.unmodifiable(_bots);

  int get invitedCount => _bots.length;

  /// Suppress inbox reactions while the human send path posts envelopes.
  void pauseReactions() {
    _reactionsPaused++;
    _reactDebounceTimer?.cancel();
    _reactDebounceTimer = null;
  }

  /// Resume reactions and schedule one coalesced [reactOnce] if paused depth hits 0.
  void resumeReactions() {
    if (_reactionsPaused > 0) {
      _reactionsPaused--;
    }
    if (_reactionsPaused == 0) {
      _scheduleReactDebounced();
    }
  }

  void dispose() {
    _disposed = true;
    _reactDebounceTimer?.cancel();
    _reactDebounceTimer = null;
    _relay.onEnvelopeStored = null;
    for (final bot in _bots) {
      bot.orchestrator.stopPolling();
      unawaited(bot.db.close());
      try {
        if (bot.dbFile.existsSync()) bot.dbFile.deleteSync();
      } catch (_) {}
    }
    _bots.clear();
  }

  void _onEnvelopeStored() {
    if (_disposed) return;
    if (_reactionsPaused > 0) return;
    _scheduleReactDebounced();
  }

  void _scheduleReactDebounced() {
    if (_disposed) return;
    if (_reactionsPaused > 0) return;
    _reactDebounceTimer?.cancel();
    _reactDebounceTimer = Timer(_reactDebounce, () {
      _reactDebounceTimer = null;
      unawaited(_runReactSerialized());
    });
  }

  Future<void> _runReactSerialized() async {
    if (_disposed || _reactionsPaused > 0) return;
    if (_reactRunning) {
      _reactNeededAfterRun = true;
      return;
    }
    _reactRunning = true;
    try {
      do {
        _reactNeededAfterRun = false;
        await reactOnce();
      } while (_reactNeededAfterRun && !_disposed && _reactionsPaused == 0);
    } finally {
      _reactRunning = false;
    }
  }

  /// Poll bot + human inboxes and auto-accept pending housing proposals.
  ///
  /// Does not heal bot↔bot mesh (that runs only in [inviteNextBot]).
  Future<void> reactOnce() async {
    if (_disposed) return;
    final sw = Stopwatch()..start();
    debugPrint('PeerSimulator react start bots=${_bots.length}');
    for (final bot in List<SandboxBotPeer>.from(_bots)) {
      try {
        await bot.orchestrator.processAllPendingHandshakes();
        await bot.orchestrator.pollSteadyStateInboxes();
        await _autoAcceptPendingProposals(bot);
      } catch (e, st) {
        debugPrint('PeerSimulator bot ${bot.displayName} react failed: $e\n$st');
      }
    }
    final human = HandshakeOrchestrator.maybeInstance;
    if (human != null) {
      try {
        await human.processAllPendingHandshakes();
        await human.pollSteadyStateInboxes();
      } catch (e, st) {
        debugPrint('PeerSimulator human poll failed: $e\n$st');
      }
    }
    sw.stop();
    debugPrint('PeerSimulator react end ${sw.elapsedMilliseconds}ms');
  }

  Future<void> _autoAcceptPendingProposals(SandboxBotPeer bot) async {
    final transport = HousingProposalTransportService(bot.db);
    final plans = await bot.db.listPlans();
    for (final plan in plans) {
      if (plan.type != 'housing') continue;
      final revisionId = await transport.pendingRevisionIdForPlan(plan.id);
      if (revisionId == null) continue;
      // pendingRevisionId stays set until unanimous activation — not until
      // this bot responds. Re-accepting every reactOnce floods FakeRelay and
      // notifications (see terminal.log storm: dozens of accepts / 1000+ notifies).
      if (!await _botStillNeedsToAccept(
            bot,
            planId: plan.id,
            revisionId: revisionId,
          )) {
        continue;
      }
      try {
        await bot.orchestrator.sendHousingProposalResponse(
          planId: plan.id,
          status: ProposalResponseStatus.accepted,
          revisionId: revisionId,
        );
        debugPrint(
          'PeerSimulator ${bot.displayName} accepted proposal ${plan.id} '
          'rev=$revisionId',
        );
      } catch (e, st) {
        debugPrint(
          'PeerSimulator auto-accept proposal ${plan.id} '
          '(${bot.displayName}) failed: $e\n$st',
        );
      }
    }
  }

  /// True when this bot's `:self` row may still Accept (status pending).
  Future<bool> _botStillNeedsToAccept(
    SandboxBotPeer bot, {
    required String planId,
    required String revisionId,
  }) async {
    final rev = await (bot.db.select(bot.db.proposalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingleOrNull();
    if (rev == null) return false;
    final state = HousingProposalRevisionState.fromJson(rev.payloadJson);
    final selfId = '$planId:self';
    final responses = await (bot.db.select(bot.db.proposalResponses)
          ..where((t) => t.revisionId.equals(revisionId)))
        .get();
    final selfStatus = responses
            .where((r) => r.participantId == selfId)
            .map((r) => r.status)
            .firstOrNull ??
        ProposalResponseStatus.pending.name;
    return housingParticipantMayRespond(
      revision: state,
      participantResponseStatus: selfStatus,
      proposerParticipantId: rev.proposerParticipantId,
      participantId: selfId,
    );
  }

  @visibleForTesting
  Future<bool> botStillNeedsToAcceptForTest(
    SandboxBotPeer bot, {
    required String planId,
    required String revisionId,
  }) =>
      _botStillNeedsToAccept(bot, planId: planId, revisionId: revisionId);

  /// Invite the next catalog bot via generate → redeem → poll (no code UI).
  Future<SandboxBotPeer?> inviteNextBot({
    required HandshakeOrchestrator humanOrchestrator,
    required String humanDisplayName,
    required String humanAvatarId,
  }) async {
    if (!SandboxMode.isActive(_prefs)) {
      throw StateError('inviteNextBot requires sandboxMode');
    }
    if (_bots.length >= SandboxBotCatalog.maxBots) {
      return null;
    }
    final index = _bots.length;
    final name = SandboxBotCatalog.displayNames[index];
    final avatar = SandboxBotCatalog.randomAvatarId(_rng);
    final bot = await _spawnBot(
      displayName: name,
      avatarId: avatar,
    );
    final priorBots = List<SandboxBotPeer>.from(_bots);
    _bots.add(bot);
    await _prefs.setSandboxInvitedBotCount(_bots.length);

    final invite = await humanOrchestrator.generateInvitation(
      validFor: const Duration(hours: 24),
      stubDisplayName: name,
      stubAvatarId: avatar,
    );
    final parsed = parseInvitationCode(invite.shortCode);
    if (parsed is! InvitationCodeOk) {
      throw StateError('sandbox invite short code parse failed');
    }
    await bot.orchestrator.redeemInvitation(
      code: parsed.code,
      selfDisplayName: name,
      selfAvatarId: avatar,
    );
    await humanOrchestrator.processAllPendingHandshakes();
    await bot.orchestrator.processAllPendingHandshakes();
    await humanOrchestrator.processAllPendingHandshakes();
    await bot.orchestrator.processAllPendingHandshakes();

    // Bots must be relay-reachable to each other or proposal accept fails
    // (plan_missing_peer_contacts) when the roster has multiple peers.
    pauseReactions();
    try {
      for (final other in priorBots) {
        await _connectBotPair(inviter: other, invitee: bot);
      }
    } finally {
      resumeReactions();
    }

    await reactOnce();
    return bot;
  }

  /// Full handshake between two sandbox bots on the shared FakeRelay.
  Future<void> _connectBotPair({
    required SandboxBotPeer inviter,
    required SandboxBotPeer invitee,
  }) async {
    botPairConnectAttempts++;
    final invite = await inviter.orchestrator.generateInvitation(
      validFor: const Duration(hours: 24),
      stubDisplayName: invitee.displayName,
      stubAvatarId: invitee.avatarId,
    );
    final parsed = parseInvitationCode(invite.shortCode);
    if (parsed is! InvitationCodeOk) {
      throw StateError('sandbox bot-bot invite short code parse failed');
    }
    await invitee.orchestrator.redeemInvitation(
      code: parsed.code,
      selfDisplayName: invitee.displayName,
      selfAvatarId: invitee.avatarId,
    );
    await inviter.orchestrator.processAllPendingHandshakes();
    await invitee.orchestrator.processAllPendingHandshakes();
    await inviter.orchestrator.processAllPendingHandshakes();
    await invitee.orchestrator.processAllPendingHandshakes();
  }

  @visibleForTesting
  Future<bool> botsAreConnectedForTest(
    SandboxBotPeer a,
    SandboxBotPeer b,
  ) =>
      _botsAreConnected(a, b);

  Future<bool> _botsAreConnected(SandboxBotPeer a, SandboxBotPeer b) async {
    final bPub = await b.identity.publicKeyB64();
    final contacts = await a.contacts.list();
    return contacts.any(
      (c) =>
          c.kind == 'connected' &&
          (c.peerPublicMaterial ?? '') == bPub,
    );
  }

  Future<SandboxBotPeer> _spawnBot({
    required String displayName,
    required String avatarId,
  }) async {
    final id = _botSeq++;
    final dbFile = File(
      '${Directory.systemTemp.path}/compartarenta_sandbox_bot_$id.sqlite',
    );
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    final seed = Uint8List.fromList(
      List<int>.generate(32, (i) => (id * 37 + i * 13 + 7) & 0xff),
    );
    final db = _SandboxDb(NativeDatabase(dbFile));
    final identity = InMemoryIdentityKeystore(seed: seed);
    final contacts = ContactsRepository(db);
    final invitations = ContactInvitationsRepository(db);
    final orchestrator = HandshakeOrchestrator(
      db: db,
      identity: identity,
      relay: _relay,
      contacts: contacts,
      invitations: invitations,
      pollInterval: const Duration(days: 365),
      deviceBinding: DeviceBindingService.forTesting('sandbox-bot-$id'),
    );
    orchestrator.enableSandboxPeerAutoAccept(
      profile: () async => (
        displayName: displayName,
        avatarId: avatarId,
      ),
    );
    return SandboxBotPeer(
      displayName: displayName,
      avatarId: avatarId,
      db: db,
      dbFile: dbFile,
      identity: identity,
      orchestrator: orchestrator,
      contacts: contacts,
    );
  }
}
