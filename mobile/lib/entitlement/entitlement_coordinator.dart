import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'entitlement_client.dart';
import 'entitlement_gate.dart';
import 'participant_installation_store.dart';
import 'plan_participant_installation_registry.dart';

/// Wires local installation identity, roster metadata, and relay gates.
class EntitlementCoordinator {
  EntitlementCoordinator({
    required AppConfig config,
    required ParticipantInstallationStore installationStore,
    required PlanParticipantInstallationRegistry registry,
    EntitlementClient? client,
  })  : _config = config,
        _installationStore = installationStore,
        _registry = registry,
        _client = client ??
            (config.entitlementEnabled
                ? EntitlementClient(baseUrl: config.entitlementBaseUrl!)
                : null);

  static EntitlementCoordinator? _instance;

  static EntitlementCoordinator? get maybeInstance => _instance;

  static void install(EntitlementCoordinator coordinator) {
    _instance = coordinator;
  }

  static void uninstallForTesting() {
    _instance?.close();
    _instance = null;
  }

  final AppConfig _config;
  final ParticipantInstallationStore _installationStore;
  final PlanParticipantInstallationRegistry _registry;
  final EntitlementClient? _client;

  bool get enabled => _config.entitlementEnabled && _client != null;

  Future<void> ensureRegistered() async {
    if (!enabled) return;
    try {
      final id = await _installationStore.loadOrCreateId();
      await _client!.registerInstallation(id);
    } on Object catch (e, st) {
      debugPrint('entitlement: register failed: $e\n$st');
    }
  }

  Future<void> bindSelfParticipant({
    required String planId,
    required String selfParticipantId,
  }) async {
    if (!enabled) return;
    final id = await _installationStore.loadOrCreateId();
    await _registry.setInstallationId(
      planId: planId,
      participantId: selfParticipantId,
      installationId: id,
    );
  }

  Future<String> installationIdForSnapshot({
    required String planId,
    required String participantId,
  }) async {
    await bindSelfParticipant(
      planId: planId,
      selfParticipantId: participantId,
    );
    return _registry.installationIdFor(
          planId: planId,
          participantId: participantId,
        ) ??
        await _installationStore.loadOrCreateId();
  }

  Future<void> ingestParticipantSnapshot({
    required String planId,
    required String participantId,
    required String? installationId,
  }) async {
    if (!enabled || installationId == null || installationId.isEmpty) return;
    await _registry.setInstallationId(
      planId: planId,
      participantId: participantId,
      installationId: installationId,
    );
  }

  Future<void> ingestSnapshotsFromPayload({
    required String planId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
  }) async {
    if (!enabled) return;
    final raw = payload['participantSnapshots'];
    if (raw is! List) return;
    for (final entry in raw) {
      if (entry is! Map) continue;
      final sourcePid = entry['id'] as String?;
      final inst = entry['participantInstallationId'] as String?;
      if (sourcePid == null || inst == null || inst.isEmpty) continue;
      final localPid = sourceToLocalParticipant[sourcePid] ?? sourcePid;
      await ingestParticipantSnapshot(
        planId: planId,
        participantId: localPid,
        installationId: inst,
      );
    }
  }

  Future<void> reportRosterIfComplete({
    required String planId,
    required String revisionId,
    required List<String> participantIds,
  }) async {
    if (!enabled) return;
    final roster = _registry.rosterInstallationIds(
      planId: planId,
      participantIds: participantIds,
    );
    if (roster == null) {
      debugPrint(
        'entitlement: roster incomplete for $planId '
        '(${participantIds.length} participants)',
      );
      return;
    }
    try {
      await _client!.reportPlanRoster(
        planId: planId,
        revisionId: revisionId,
        participantInstallationIds: roster,
      );
      debugPrint('entitlement: roster reported for $planId rev=$revisionId');
    } on Object catch (e, st) {
      debugPrint('entitlement: roster report failed: $e\n$st');
    }
  }

  Future<EntitlementGate?> gateFor({
    required String planId,
    required String selfParticipantId,
    required int kind,
    String? expenseId,
    String? revisionId,
    String? decisionKind,
  }) async {
    if (!enabled || !EntitlementGate.isGatedKind(kind)) return null;
    await bindSelfParticipant(planId: planId, selfParticipantId: selfParticipantId);
    final installationId = _registry.installationIdFor(
      planId: planId,
      participantId: selfParticipantId,
    );
    if (installationId == null || installationId.isEmpty) {
      final fallback = await _installationStore.loadOrCreateId();
      await _registry.setInstallationId(
        planId: planId,
        participantId: selfParticipantId,
        installationId: fallback,
      );
      return EntitlementGate.forHousing(
        participantInstallationId: fallback,
        planId: planId,
        kind: kind,
        expenseId: expenseId,
        revisionId: revisionId,
        decisionKind: decisionKind,
      );
    }
    return EntitlementGate.forHousing(
      participantInstallationId: installationId,
      planId: planId,
      kind: kind,
      expenseId: expenseId,
      revisionId: revisionId,
      decisionKind: decisionKind,
    );
  }

  void close() => _client?.close();
}
