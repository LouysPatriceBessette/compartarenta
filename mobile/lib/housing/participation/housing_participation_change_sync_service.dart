import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../db/app_database.dart';
import '../housing_participant_snapshot_map.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';
import 'housing_participation_change_service.dart';
import 'housing_participation_membership_service.dart';

class _LocalPlanTarget {
  const _LocalPlanTarget({required this.planId, required this.packageId});

  final String planId;
  final String packageId;
}

/// Steady-state JSON sync for participation change (client-only relay kinds).
class HousingParticipationChangeSyncService {
  HousingParticipationChangeSyncService(this._db);

  final AppDatabase _db;

  Future<String> buildProposeJson(
    HousingParticipationChange change, {
    String? statusWireOverride,
  }) async {
    final roster = await participantsForPlan(_db, change.planId);
    return jsonEncode({
      'change_id': change.id,
      'package_id': change.packageId,
      'plan_id': change.planId,
      'kind': change.kind,
      'initiator_participant_id': change.initiatorParticipantId,
      if (change.targetParticipantId != null)
        'target_participant_id': change.targetParticipantId,
      if (change.departureDate != null)
        'departure_date': change.departureDate!.toUtc().toIso8601String(),
      'status': statusWireOverride ?? change.status,
      'created_at': change.createdAt.toUtc().toIso8601String(),
      'participant_snapshots': _snapshotsFromRoster(roster),
    });
  }

  Future<String> buildDecisionJson({
    required String changeId,
    required String participantId,
    required String status,
  }) async {
    final change = await (_db.select(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingleOrNull();
    final roster =
        change == null
            ? <Participant>[]
            : await participantsForPlan(_db, change.planId);
    return jsonEncode({
      'change_id': changeId,
      if (change != null) 'plan_id': change.planId,
      if (change != null) 'package_id': change.packageId,
      'participant_id': participantId,
      'status': status,
      'decided_at': DateTime.now().toUtc().toIso8601String(),
      'participant_snapshots': _snapshotsFromRoster(roster),
    });
  }

  Future<String> buildNotifyJson(HousingParticipationChange change) async {
    return buildProposeJson(change);
  }

  Future<bool> importProposeFromPeer({
    required String changeJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(changeJson) as Map<String, dynamic>;
    final changeId = payload['change_id'] as String? ?? '';
    if (changeId.isEmpty) return false;

    final payloadPackageId = payload['package_id'] as String? ?? '';
    final payloadPlanId = payload['plan_id'] as String? ?? '';
    final target = await _resolveLocalPlanTarget(
      payloadPackageId: payloadPackageId,
      payloadPlanId: payloadPlanId,
    );
    if (target == null) {
      _log(
        'propose skip: no local plan for package=$payloadPackageId '
        'plan=$payloadPlanId',
      );
      return false;
    }
    final planId = target.planId;
    final localPackageId = target.packageId;
    if (payloadPlanId.isNotEmpty && payloadPlanId != planId) {
      _log('propose resolved plan $payloadPlanId → $planId');
    }

    await HousingParticipationMembershipService(_db).ensureMembershipsForPlan(
      planId,
    );

    final snapshots = payload['participant_snapshots'];
    final sourceToLocal = await mapSourceParticipantIdsFromSnapshots(
      db: _db,
      planId: planId,
      snapshots: snapshots,
    );

    final sourceInitiator =
        payload['initiator_participant_id'] as String? ?? '';
    final sourceTarget = payload['target_participant_id'] as String?;
    final localInitiator = await resolveImportedParticipantId(
      db: _db,
      planId: planId,
      sourceParticipantId: sourceInitiator,
      sourceToLocal: sourceToLocal,
      senderContactId: senderContactId,
      snapshots: snapshots,
    );
    if (localInitiator == null || localInitiator.isEmpty) {
      _log('propose skip: initiator not mapped for $changeId');
      return false;
    }
    final localTarget =
        sourceTarget == null
            ? null
            : await resolveImportedParticipantId(
              db: _db,
              planId: planId,
              sourceParticipantId: sourceTarget,
              sourceToLocal: sourceToLocal,
              snapshots: snapshots,
            );
    if (sourceTarget != null &&
        sourceTarget.isNotEmpty &&
        (localTarget == null || localTarget.isEmpty)) {
      _log('propose skip: target not mapped for $changeId');
      return false;
    }

    final existing = await (_db.select(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.initiatorParticipantId != localInitiator ||
          existing.targetParticipantId != localTarget) {
        await (_db.update(_db.housingParticipationChanges)
              ..where((t) => t.id.equals(changeId)))
            .write(
          HousingParticipationChangesCompanion(
            initiatorParticipantId: drift.Value(localInitiator),
            targetParticipantId: drift.Value(localTarget),
          ),
        );
        _log(
          'propose $changeId remapped participants '
          '(initiator $sourceInitiator→$localInitiator, '
          'target $sourceTarget→$localTarget)',
        );
      } else {
        _log('propose $changeId already present (idempotent ok)');
      }
      await _applyEffectiveFromPayloadIfNeeded(payload, changeId);
      return true;
    }

    await _db.into(_db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: localPackageId,
        kind: payload['kind'] as String? ?? '',
        initiatorParticipantId: localInitiator,
        targetParticipantId: drift.Value(localTarget),
        departureDate: drift.Value(_parseDate(payload['departure_date'])),
        status:
            payload['status'] as String? ??
            HousingParticipationChangeStatus.pending.wireValue,
        createdAt:
            _parseDate(payload['created_at']) ?? DateTime.now().toUtc(),
      ),
    );

    final kind = HousingParticipationChangeKind.fromWire(
      payload['kind'] as String?,
    );
    if (kind?.requiresUnanimousVote == true && localInitiator.isNotEmpty) {
      await _db.into(_db.housingParticipationDecisions).insertOnConflictUpdate(
        HousingParticipationDecisionsCompanion.insert(
          changeId: changeId,
          participantId: localInitiator,
          status: HousingParticipationDecisionStatus.accepted.wireValue,
          decidedAt: drift.Value(DateTime.now().toUtc()),
        ),
      );
    }

    _log(
      'imported propose $changeId from $senderContactId '
      '(initiator $sourceInitiator→$localInitiator, '
      'target $sourceTarget→$localTarget)',
    );
    await _applyEffectiveFromPayloadIfNeeded(payload, changeId);
    return true;
  }

  Future<bool> importDecisionFromPeer({
    required String decisionJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(decisionJson) as Map<String, dynamic>;
    final changeId = payload['change_id'] as String? ?? '';
    final sourceParticipantId = payload['participant_id'] as String? ?? '';
    final status = payload['status'] as String? ?? '';
    if (changeId.isEmpty || sourceParticipantId.isEmpty || status.isEmpty) {
      return false;
    }

    final change = await (_db.select(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingleOrNull();
    if (change == null) return false;

    final sourceToLocal = await mapSourceParticipantIdsFromSnapshots(
      db: _db,
      planId: change.planId,
      snapshots: payload['participant_snapshots'],
    );
    var localParticipantId = await resolveImportedParticipantId(
      db: _db,
      planId: change.planId,
      sourceParticipantId: sourceParticipantId,
      sourceToLocal: sourceToLocal,
      senderContactId: senderContactId,
      snapshots: payload['participant_snapshots'],
    );
    if (localParticipantId == null || localParticipantId.isEmpty) {
      _log('decision skip: participant not mapped for $changeId');
      return false;
    }

    final existingDecision =
        await (_db.select(_db.housingParticipationDecisions)
              ..where(
                (t) =>
                    t.changeId.equals(changeId) &
                    t.participantId.equals(localParticipantId),
              ))
            .getSingleOrNull();
    if (existingDecision != null) {
      _log('decision $changeId from $senderContactId already present');
      return true;
    }

    final wasPending =
        change.status == HousingParticipationChangeStatus.pending.wireValue;
    if (!wasPending &&
        change.status != HousingParticipationChangeStatus.effective.wireValue) {
      return false;
    }

    await _db.into(_db.housingParticipationDecisions).insertOnConflictUpdate(
      HousingParticipationDecisionsCompanion.insert(
        changeId: changeId,
        participantId: localParticipantId,
        status: status,
        decidedAt: drift.Value(
          _parseDate(payload['decided_at']) ?? DateTime.now().toUtc(),
        ),
      ),
    );

    if (wasPending) {
      await HousingParticipationChangeService(
        _db,
      ).evaluatePendingSettlement(changeId);
    }

    _log('imported decision on $changeId from $senderContactId');
    return true;
  }

  Future<bool> importNotifyFromPeer({
    required String notifyJson,
    required String senderContactId,
  }) async {
    return importProposeFromPeer(
      changeJson: notifyJson,
      senderContactId: senderContactId,
    );
  }

  List<Map<String, Object?>> _snapshotsFromRoster(List<Participant> roster) {
    return [
      for (final p in roster)
        {
          'id': p.id,
          'displayName': p.displayName,
          if (p.avatarId.isNotEmpty) 'avatarId': p.avatarId,
          if (p.contactId != null) 'contactId': p.contactId,
        },
    ];
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Maps sender-local `received:*` plan ids to this device's active housing plan.
  Future<_LocalPlanTarget?> _resolveLocalPlanTarget({
    required String payloadPackageId,
    required String payloadPlanId,
  }) async {
    if (payloadPackageId.isNotEmpty) {
      final byPkg = await (_db.select(_db.proposalPackages)
            ..where((t) => t.id.equals(payloadPackageId)))
          .getSingleOrNull();
      if (byPkg?.activeRevisionId != null && byPkg!.activeRevisionId!.isNotEmpty) {
        return _LocalPlanTarget(planId: byPkg.planId, packageId: byPkg.id);
      }
    }

    if (payloadPlanId.isNotEmpty) {
      final byPlan = await (_db.select(_db.proposalPackages)
            ..where((t) => t.planId.equals(payloadPlanId)))
          .get();
      for (final pkg in byPlan) {
        if (pkg.activeRevisionId != null && pkg.activeRevisionId!.isNotEmpty) {
          return _LocalPlanTarget(planId: pkg.planId, packageId: pkg.id);
        }
      }
    }

    final active = await (_db.select(_db.proposalPackages)
          ..where((t) => t.activeRevisionId.isNotNull()))
        .get();
    if (active.length == 1) {
      final pkg = active.single;
      if (pkg.activeRevisionId != null && pkg.activeRevisionId!.isNotEmpty) {
        return _LocalPlanTarget(planId: pkg.planId, packageId: pkg.id);
      }
    } else if (active.length > 1) {
      for (final pkg in active) {
        if (pkg.activeRevisionId == null || pkg.activeRevisionId!.isEmpty) {
          continue;
        }
        final plan = await (_db.select(_db.plans)
              ..where((t) => t.id.equals(pkg.planId)))
            .getSingleOrNull();
        if (plan?.type == 'housing') {
          return _LocalPlanTarget(planId: pkg.planId, packageId: pkg.id);
        }
      }
    }

    if (payloadPlanId.isNotEmpty) {
      final plan = await (_db.select(_db.plans)
            ..where((t) => t.id.equals(payloadPlanId)))
          .getSingleOrNull();
      if (plan != null) {
        var packageId = payloadPackageId;
        if (packageId.isEmpty) {
          final packages = await (_db.select(_db.proposalPackages)
                ..where((t) => t.planId.equals(payloadPlanId)))
              .get();
          for (final pkg in packages) {
            if (pkg.activeRevisionId != null &&
                pkg.activeRevisionId!.isNotEmpty) {
              packageId = pkg.id;
              break;
            }
          }
        }
        if (packageId.isEmpty) {
          packageId = 'pkg:$payloadPlanId';
        }
        return _LocalPlanTarget(planId: payloadPlanId, packageId: packageId);
      }
    }
    return null;
  }

  void _log(String message) {
    debugPrint('housing_participation_change $message');
  }

  Future<void> _applyEffectiveFromPayloadIfNeeded(
    Map<String, dynamic> payload,
    String changeId,
  ) async {
    final status = HousingParticipationChangeStatus.fromWire(
      payload['status'] as String?,
    );
    if (status != HousingParticipationChangeStatus.effective) return;
    await HousingParticipationChangeService(_db).applyEffectiveFromPeerNotify(
      changeId,
    );
  }
}
