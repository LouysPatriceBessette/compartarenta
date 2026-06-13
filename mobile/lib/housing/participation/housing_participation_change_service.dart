import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';
import '../agreement_rules_diff.dart';
import '../amendment/housing_active_agreement_service.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_inactive_participant_service.dart';
import 'housing_participation_change_kind.dart';
import 'housing_participation_membership_service.dart';
import 'housing_ratio_redistribution.dart';
import 'housing_withdrawal_penalty_ledger.dart';

/// CRUD and state transitions for participation change requests.
class HousingParticipationChangeService {
  HousingParticipationChangeService(this._db);

  final AppDatabase _db;

  HousingParticipationMembershipService get membershipService =>
      HousingParticipationMembershipService(_db);

  Future<String?> packageIdForPlan(String planId) async {
    final packages = await (_db.select(_db.proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .get();
    for (final pkg in packages) {
      if (pkg.activeRevisionId != null && pkg.activeRevisionId!.isNotEmpty) {
        return pkg.id;
      }
    }
    return null;
  }

  Future<HousingParticipationChange?> pendingForPlan(String planId) async {
    return (_db.select(_db.housingParticipationChanges)
          ..where(
            (t) =>
                t.planId.equals(planId) &
                t.status.equals(HousingParticipationChangeStatus.pending.wireValue),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .getSingleOrNull();
  }

  Future<List<HousingParticipationDecision>> decisionsFor(String changeId) =>
      (_db.select(_db.housingParticipationDecisions)
            ..where((t) => t.changeId.equals(changeId)))
          .get();

  Future<HousingParticipationChange?> getById(String changeId) =>
      (_db.select(_db.housingParticipationChanges)
            ..where((t) => t.id.equals(changeId)))
          .getSingleOrNull();

  Future<void> _assertNoPending(String planId) async {
    final pending = await pendingForPlan(planId);
    if (pending != null) {
      throw StateError('participation_change_already_pending');
    }
  }

  List<String> _deciderIds({
    required HousingParticipationChangeKind kind,
    required List<Participant> activeRoster,
    required String? targetParticipantId,
  }) {
    return switch (kind) {
      HousingParticipationChangeKind.immediateTermination =>
        activeRoster.map((p) => p.id).toList(),
      HousingParticipationChangeKind.ejection =>
        activeRoster
            .where((p) => p.id != targetParticipantId)
            .map((p) => p.id)
            .toList(),
      HousingParticipationChangeKind.voluntaryWithdrawal => const [],
    };
  }

  Future<HousingParticipationChange> _insertChange({
    required String planId,
    required String packageId,
    required HousingParticipationChangeKind kind,
    required String initiatorParticipantId,
    String? targetParticipantId,
    DateTime? departureDate,
  }) async {
    final id = 'pc:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc();
    final row = HousingParticipationChangesCompanion.insert(
      id: id,
      planId: planId,
      packageId: packageId,
      kind: kind.wireValue,
      initiatorParticipantId: initiatorParticipantId,
      targetParticipantId: drift.Value(targetParticipantId),
      departureDate: drift.Value(departureDate),
      status: HousingParticipationChangeStatus.pending.wireValue,
      createdAt: now,
    );
    await _db.into(_db.housingParticipationChanges).insert(row);
    return (await getById(id))!;
  }

  Future<void> _recordDecision({
    required String changeId,
    required String participantId,
    required HousingParticipationDecisionStatus status,
  }) async {
    await _db
        .into(_db.housingParticipationDecisions)
        .insertOnConflictUpdate(
          HousingParticipationDecisionsCompanion.insert(
            changeId: changeId,
            participantId: participantId,
            status: status.wireValue,
            decidedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<HousingParticipationChange> proposeImmediateTermination({
    required String planId,
    required String initiatorParticipantId,
  }) async {
    await _assertNoPending(planId);
    final membership = membershipService;
    await membership.ensureMembershipsForPlan(planId);
    if (await membership.activeParticipantCount(planId) < 2) {
      throw StateError('insufficient_participants');
    }
    final packageId = await packageIdForPlan(planId);
    if (packageId == null) throw StateError('no_active_package');

    final change = await _insertChange(
      planId: planId,
      packageId: packageId,
      kind: HousingParticipationChangeKind.immediateTermination,
      initiatorParticipantId: initiatorParticipantId,
      targetParticipantId: null,
    );
    await _recordDecision(
      changeId: change.id,
      participantId: initiatorParticipantId,
      status: HousingParticipationDecisionStatus.accepted,
    );
    await _evaluateSettlement(change.id);
    return (await getById(change.id))!;
  }

  Future<HousingParticipationChange> proposeVoluntaryWithdrawal({
    required String planId,
    required String initiatorParticipantId,
    required DateTime departureDate,
  }) async {
    await _assertNoPending(planId);
    final membership = membershipService;
    await membership.ensureMembershipsForPlan(planId);
    if (await membership.activeParticipantCount(planId) <= 2) {
      throw StateError('insufficient_participants');
    }
    final packageId = await packageIdForPlan(planId);
    if (packageId == null) throw StateError('no_active_package');

    final localDate = DateUtils.dateOnly(departureDate.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());
    if (localDate.isBefore(today)) {
      throw StateError('departure_date_in_past');
    }

    return _insertChange(
      planId: planId,
      packageId: packageId,
      kind: HousingParticipationChangeKind.voluntaryWithdrawal,
      initiatorParticipantId: initiatorParticipantId,
      targetParticipantId: initiatorParticipantId,
      departureDate: localDate.toUtc(),
    );
  }

  Future<HousingParticipationChange> proposeEjection({
    required String planId,
    required String initiatorParticipantId,
    required String targetParticipantId,
  }) async {
    await _assertNoPending(planId);
    final membership = membershipService;
    await membership.ensureMembershipsForPlan(planId);
    if (await membership.activeParticipantCount(planId) <= 2) {
      throw StateError('insufficient_participants');
    }
    if (targetParticipantId == initiatorParticipantId) {
      throw StateError('cannot_eject_self');
    }
    final packageId = await packageIdForPlan(planId);
    if (packageId == null) throw StateError('no_active_package');

    final change = await _insertChange(
      planId: planId,
      packageId: packageId,
      kind: HousingParticipationChangeKind.ejection,
      initiatorParticipantId: initiatorParticipantId,
      targetParticipantId: targetParticipantId,
    );
    await _recordDecision(
      changeId: change.id,
      participantId: initiatorParticipantId,
      status: HousingParticipationDecisionStatus.accepted,
    );
    await _evaluateSettlement(change.id);
    return (await getById(change.id))!;
  }

  Future<void> recordDecision({
    required String changeId,
    required String participantId,
    required bool accepted,
  }) async {
    final change = await getById(changeId);
    if (change == null) return;
    if (change.status != HousingParticipationChangeStatus.pending.wireValue) {
      return;
    }
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null || !kind.requiresUnanimousVote) return;

    await _recordDecision(
      changeId: changeId,
      participantId: participantId,
      status:
          accepted
              ? HousingParticipationDecisionStatus.accepted
              : HousingParticipationDecisionStatus.rejected,
    );
    await _evaluateSettlement(changeId);
  }

  Future<void> _evaluateSettlement(String changeId) async {
    final change = await getById(changeId);
    if (change == null) return;
    if (change.status != HousingParticipationChangeStatus.pending.wireValue) {
      return;
    }
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null) return;

    if (kind == HousingParticipationChangeKind.voluntaryWithdrawal) {
      await applyDueVoluntaryWithdrawals(change.planId);
      return;
    }

    final roster = await membershipService.activeParticipantsForPlan(
      change.planId,
    );
    final deciders = _deciderIds(
      kind: kind,
      activeRoster: roster,
      targetParticipantId: change.targetParticipantId,
    );
    final decisions = await decisionsFor(changeId);
    if (decisions.any(
      (d) => d.status == HousingParticipationDecisionStatus.rejected.wireValue,
    )) {
      await _setStatus(changeId, HousingParticipationChangeStatus.aborted);
      return;
    }
    final acceptedIds =
        decisions
            .where(
              (d) =>
                  d.status ==
                  HousingParticipationDecisionStatus.accepted.wireValue,
            )
            .map((d) => d.participantId)
            .toSet();
    if (!deciders.every(acceptedIds.contains)) return;

    await _applyEffective(change);
  }

  Future<void> applyDueVoluntaryWithdrawals(String planId) async {
    final pending = await pendingForPlan(planId);
    if (pending == null) return;
    final kind = HousingParticipationChangeKind.fromWire(pending.kind);
    if (kind != HousingParticipationChangeKind.voluntaryWithdrawal) return;

    final departure = pending.departureDate;
    if (departure == null) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final depDay = DateUtils.dateOnly(departure.toLocal());
    if (today.isBefore(depDay)) return;

    await _applyEffective(pending);
  }

  Future<void> _applyEffective(HousingParticipationChange change) async {
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null) return;
    final membership = membershipService;
    final inactiveSvc = HousingInactiveParticipantService(_db);
    final agreementSvc = HousingActiveAgreementService(_db);
    final penaltySvc = HousingWithdrawalPenaltyLedger(_db);

    switch (kind) {
      case HousingParticipationChangeKind.immediateTermination:
        await agreementSvc.closeAgreementAtToday(change.planId);
        await membership.markAllDeparted(
          planId: change.planId,
          departureKind: kind,
          changeId: change.id,
        );
      case HousingParticipationChangeKind.voluntaryWithdrawal:
        final leaverId =
            change.targetParticipantId ?? change.initiatorParticipantId;
        final remaining =
            (await membership.activeParticipantsForPlan(change.planId))
                .where((p) => p.id != leaverId)
                .map((p) => p.id)
                .toList();
        await membership.markDeparted(
          planId: change.planId,
          participantId: leaverId,
          departureKind: kind,
          changeId: change.id,
          departedAt: change.departureDate ?? DateTime.now(),
        );
        await inactiveSvc.createInactiveParticipant(
          planId: change.planId,
          sourceParticipantId: leaverId,
        );
        await penaltySvc.applyPenaltyIfDue(
          planId: change.planId,
          leaverParticipantId: leaverId,
          departureDate: change.departureDate ?? DateTime.now(),
          remainingParticipantIds: remaining,
        );
        await redistributeRatiosAfterDeparture(
          db: _db,
          planId: change.planId,
          departingParticipantId: leaverId,
          remainingParticipantIds: remaining,
        );
      case HousingParticipationChangeKind.ejection:
        final target = change.targetParticipantId;
        if (target == null || target.isEmpty) return;
        final remaining =
            (await membership.activeParticipantsForPlan(change.planId))
                .where((p) => p.id != target)
                .map((p) => p.id)
                .toList();
        await membership.markDeparted(
          planId: change.planId,
          participantId: target,
          departureKind: kind,
          changeId: change.id,
        );
        await inactiveSvc.createInactiveParticipant(
          planId: change.planId,
          sourceParticipantId: target,
        );
        await redistributeRatiosAfterDeparture(
          db: _db,
          planId: change.planId,
          departingParticipantId: target,
          remainingParticipantIds: remaining,
        );
    }
    await _setStatus(change.id, HousingParticipationChangeStatus.effective);
  }

  /// Whether departure side effects already ran for [change].
  Future<bool> departureSideEffectsApplied(
    HousingParticipationChange change,
  ) async {
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null) return true;

    return switch (kind) {
      HousingParticipationChangeKind.immediateTermination => () async {
        final roster = await participantsForPlan(_db, change.planId);
        for (final participant in roster) {
          if (await membershipService.isActiveMember(
            change.planId,
            participant.id,
          )) {
            return false;
          }
        }
        return true;
      }(),
      HousingParticipationChangeKind.voluntaryWithdrawal => () async {
        final leaverId =
            change.targetParticipantId ?? change.initiatorParticipantId;
        return !(await membershipService.isActiveMember(
          change.planId,
          leaverId,
        ));
      }(),
      HousingParticipationChangeKind.ejection => () async {
        final target = change.targetParticipantId;
        if (target == null || target.isEmpty) return true;
        return !(await membershipService.isActiveMember(change.planId, target));
      }(),
    };
  }

  /// Applies departure side effects after a peer notify with effective status.
  Future<void> applyEffectiveFromPeerNotify(String changeId) async {
    final change = await getById(changeId);
    if (change == null) return;
    if (await departureSideEffectsApplied(change)) {
      return;
    }
    await _applyEffective(change);
  }

  Future<void> _setStatus(
    String changeId,
    HousingParticipationChangeStatus status,
  ) async {
    await (_db.update(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .write(
      HousingParticipationChangesCompanion(
        status: drift.Value(status.wireValue),
        settledAt: drift.Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Minimum notice days for voluntary withdrawal for [participantId].
  Future<int> minNoticeDaysForParticipant(
    String planId,
    String participantId,
  ) async {
    final agr = await _db.getAgreementForPlan(planId);
    if (agr == null) return 0;
    final slice = AgreementRulesAgreementSlice(
      clauses: agr.clauses,
      minNoticeDays: agr.minNoticeDays,
      penaltyMinor: agr.penaltyMinor,
      withdrawalSameForAll: agr.withdrawalSameForAll,
      withdrawalPerParticipantJson: agr.withdrawalPerParticipantJson,
    );
    if (slice.withdrawalSameForAll == 'true') {
      return slice.minNoticeDays;
    }
    try {
      final map =
          jsonDecode(slice.withdrawalPerParticipantJson)
              as Map<String, dynamic>;
      final entry = map[participantId];
      if (entry is Map) {
        return (entry['minNoticeDays'] as num?)?.toInt() ?? slice.minNoticeDays;
      }
    } catch (_) {}
    return slice.minNoticeDays;
  }

  Future<bool> shouldApplyEarlyWithdrawalPenalty({
    required String planId,
    required String participantId,
    required DateTime departureDate,
  }) async {
    return HousingWithdrawalPenaltyLedger(_db).shouldApplyPenalty(
      planId: planId,
      participantId: participantId,
      departureDate: departureDate,
    );
  }
}
