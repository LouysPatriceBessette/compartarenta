import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../../entitlement/entitlement_coordinator.dart';
import '../../entitlement/housing_trial_consumption_store.dart';
import '../../entitlement/housing_trial_eligibility.dart';
import '../agreement_rules_json.dart';
import '../housing_plan_id.dart';
import 'housing_agreement_overlap_withdrawal_exception.dart';
import '../amendment/housing_agreement_start_date_policy.dart';
import 'housing_agreement_period_conflict.dart';
import 'housing_proposal_revision_state.dart';
import 'housing_proposal_transport_service.dart';

/// Local-only proposal / renegotiation support (sync layer TBD).
///
/// Persists self-contained proposal package revisions (payload JSON),
/// per-participant responses, and activates a revision only on unanimity.
class PlanAgreementProposalService {
  PlanAgreementProposalService(this._db);
  final AppDatabase _db;

  static const String kind = 'expensePlanAgreementProposal';

  Future<String> ensurePackageForPlan(String planId) async {
    final existing = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (existing != null) return existing.id;

    final id = 'pkg:$planId';
    await _db
        .into(_db.proposalPackages)
        .insert(
          ProposalPackagesCompanion.insert(
            id: id,
            planId: planId,
            createdAt: DateTime.now().toUtc(),
            activeRevisionId: const drift.Value.absent(),
            pendingRevisionId: const drift.Value.absent(),
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );
    return id;
  }

  /// In-memory proposal payload mirroring live plan tables (no revision row).
  Future<Map<String, Object?>> buildSnapshotPayloadForPlan(String planId) async {
    final packageId = await ensurePackageForPlan(planId);
    final plan = await (_db.select(
      _db.plans,
    )..where((t) => t.id.equals(planId))).getSingle();
    final agreement = await _db.getAgreementForPlan(planId);
    if (agreement == null) {
      throw StateError('No agreement found for plan $planId');
    }
    final lines = await _db.listPlanLines(planId);
    final ratioTemplates = await _db.listPlanRatioTemplates(planId);
    final ratios = await (_db.select(
      _db.planRatios,
    )..where((t) => t.planId.equals(planId))).get();
    final groups = await (_db.select(
      _db.planGroups,
    )..where((t) => t.planId.equals(planId))).get();
    final participants = (await _db.listParticipants())
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .toList(growable: false);

    return {
      'kind': kind,
      'packageId': packageId,
      'entitlementPlanId': entitlementPlanIdForLocalPlan(planId),
      'participantSourceIds': {for (final p in participants) p.id: p.id},
      'plan': {
        'type': plan.type,
        'title': plan.title,
        'defaultCurrency': plan.currency,
        'groups': [
          for (final g in groups) {'id': g.id, 'title': g.title},
        ],
        'lines': [
          for (final l in lines)
            {
              'id': l.id,
              'title': l.title,
              'description': l.description,
              'currency': l.currency,
              'isRecurring': l.isRecurring,
              'amountUsesRange': l.amountUsesRange,
              'amountIsBudgetCap': l.amountIsBudgetCap,
              'amountMinor': l.amountMinor,
              'minAmountMinor': l.minAmountMinor,
              'maxAmountMinor': l.maxAmountMinor,
              'cadence': l.cadence,
              'recurrenceDayOfMonth': l.recurrenceDayOfMonth,
              if (l.recurrenceSpecJson.isNotEmpty)
                'recurrenceSpecJson': l.recurrenceSpecJson,
              if (l.paymentResponsibleParticipantId != null)
                'paymentResponsibleParticipantId':
                    l.paymentResponsibleParticipantId,
              if (l.ratioTemplateId != null) 'ratioTemplateId': l.ratioTemplateId,
              if (l.groupId != null) 'groupId': l.groupId,
            },
        ],
        'ratios': [
          for (final r in ratios)
            {
              'participantId': r.participantId,
              if (r.lineId != null) 'lineId': r.lineId,
              if (r.groupId != null) 'groupId': r.groupId,
              'weight': r.weight,
            },
        ],
        'ratioTemplates': [
          for (final t in ratioTemplates)
            {
              'id': t.id,
              'displayTitle': t.displayTitle,
              'weightsJson': t.weightsJson,
            },
        ],
      },
      'agreement': {
        'version': agreement.version,
        'periodStart': agreement.periodStart.toIso8601String(),
        'periodEnd': agreement.periodEnd.toIso8601String(),
        'minNoticeDays': agreement.minNoticeDays,
        'penalty': {
          'currency': plan.currency,
          'amountMinor': agreement.penaltyMinor,
        },
        'clauses': agreement.clauses,
        'withdrawalSameForAll': agreement.withdrawalSameForAll,
        'withdrawalPerParticipantJson': agreement.withdrawalPerParticipantJson,
        'agreementRulesJson': sanitizeAgreementRulesJsonForBindingSubmission(
          agreement.agreementRulesJson,
          clausesFallback: agreement.clauses,
        ),
      },
    };
  }

  Future<String> createRevisionFromCurrentDraft({
    required String planId,
    required String proposerParticipantId,
    DateTime? responseExpiresAt,
    String? forkedFromPackageId,
    String? forkedFromRevisionId,
  }) async {
    final packageId = await ensurePackageForPlan(planId);
    final participants = (await _db.listParticipants())
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .toList(growable: false);

    final revisionId = 'rev:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final createdAt = DateTime.now().toUtc();

    final payload = <String, Object?>{
      ...await buildSnapshotPayloadForPlan(planId),
      'packageId': packageId,
      'revisionId': revisionId,
      'sourcePackageId': packageId,
      'sourceRevisionId': revisionId,
      'contentHash': 'local:$revisionId',
      'createdAt': createdAt.toIso8601String(),
      'proposerParticipantId': proposerParticipantId,
      'responseExpiresAt': responseExpiresAt?.toIso8601String(),
      'lifecycleState': 'open',
      'responseMessages': <String, String>{},
      ?forkedFromPackageId: forkedFromPackageId,
      ?forkedFromRevisionId: forkedFromRevisionId,
    };

    await _db.transaction(() async {
      await _db
          .into(_db.proposalRevisions)
          .insert(
            ProposalRevisionsCompanion.insert(
              id: revisionId,
              packageId: packageId,
              contentHash: 'local:$revisionId',
              proposerParticipantId: proposerParticipantId,
              payloadJson: jsonEncode(payload),
              createdAt: createdAt,
            ),
          );

      await (_db.update(
        _db.proposalPackages,
      )..where((t) => t.id.equals(packageId))).write(
        ProposalPackagesCompanion(pendingRevisionId: drift.Value(revisionId)),
      );

      await recordResponse(
        revisionId: revisionId,
        participantId: proposerParticipantId,
        status: ProposalResponseStatus.accepted,
      );
      for (final participant in participants) {
        if (participant.id == proposerParticipantId) continue;
        await _db
            .into(_db.proposalResponses)
            .insertOnConflictUpdate(
              ProposalResponsesCompanion.insert(
                id: 'resp:$revisionId:${participant.id}',
                revisionId: revisionId,
                participantId: participant.id,
                status: ProposalResponseStatus.pending.name,
                respondedAt: const drift.Value.absent(),
              ),
            );
      }
    });

    return revisionId;
  }

  /// Clears [pendingRevisionId] and removes the pending revision and its responses.
  /// Used when relay transport failed before any invitee received the proposal.
  Future<bool> abandonPendingRevision(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    final pendingId = pkg?.pendingRevisionId;
    if (pkg == null || pendingId == null) return false;

    await _db.transaction(() async {
      await (_db.delete(
        _db.proposalResponses,
      )..where((t) => t.revisionId.equals(pendingId))).go();
      await (_db.delete(
        _db.proposalRevisions,
      )..where((t) => t.id.equals(pendingId))).go();
      await (_db.update(
        _db.proposalPackages,
      )..where((t) => t.id.equals(pkg.id))).write(
        const ProposalPackagesCompanion(
          pendingRevisionId: drift.Value.absent(),
        ),
      );
    });
    return true;
  }

  Future<void> recordResponse({
    required String revisionId,
    required String participantId,
    required ProposalResponseStatus status,
    String? message,
  }) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final state = HousingProposalRevisionState.fromJson(rev.payloadJson);
    if (!state.isOpen || state.isExpiredByClock) return;

    final id = 'resp:$revisionId:$participantId';
    await _db
        .into(_db.proposalResponses)
        .insertOnConflictUpdate(
          ProposalResponsesCompanion.insert(
            id: id,
            revisionId: revisionId,
            participantId: participantId,
            status: status.name,
            respondedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
    await _recordResponseMessage(
      revisionId: revisionId,
      participantId: participantId,
      message: message,
    );
  }

  Future<void> _recordResponseMessage({
    required String revisionId,
    required String participantId,
    String? message,
  }) async {
    final trimmed = message?.trim() ?? '';
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    final messages = Map<String, dynamic>.from(
      (payload['responseMessages'] as Map?) ?? const <String, dynamic>{},
    );
    if (trimmed.isEmpty) {
      messages.remove(participantId);
    } else {
      messages[participantId] = trimmed;
    }
    payload['responseMessages'] = messages;
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
  }

  Future<ProposalActivationOutcome> tryActivateIfUnanimous({
    required String planId,
    required String revisionId,
    required List<String> participantIds,
  }) async {
    final responses = await (_db.select(
      _db.proposalResponses,
    )..where((t) => t.revisionId.equals(revisionId))).get();

    final byParticipant = {
      for (final r in responses) r.participantId: r.status,
    };

    final unanimous =
        participantIds.isNotEmpty &&
        participantIds.every(
          (p) => byParticipant[p] == ProposalResponseStatus.accepted.name,
        );

    if (!unanimous) return ProposalActivationOutcome.notUnanimous;

    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) {
      return ProposalActivationOutcome.notUnanimous;
    }

    final payload = await loadRevisionPayload(revisionId);
    final period = _agreementPeriodFromRevisionPayload(payload);
    if (period == null) {
      return ProposalActivationOutcome.missingAgreementPeriodInRevision;
    }

    final existingAgreement = await _db.getAgreementForPlan(planId);
    if (await blocksAgreementStartDateChange(
      db: _db,
      planId: planId,
      existingStart: existingAgreement?.periodStart,
      proposedStart: period.start,
    )) {
      return ProposalActivationOutcome.blockedAgreementStartDateChange;
    }

    final blocking = await listBlockingAgreementDayRangesWithPlanIds(
      _db,
      excludePlanId: planId,
    );
    if (await candidateConflictsWithBlockingRangesAfterWithdrawalException(
      db: _db,
      candidateStart: period.start,
      candidateEnd: period.end,
      blocking: [
        for (final entry in blocking)
          (start: entry.start, end: entry.end, planId: entry.planId),
      ],
    )) {
      return ProposalActivationOutcome.blockedByOverlappingAgreementPeriod;
    }

    final packageId = rev.packageId;

    await _db.transaction(() async {
      final closedPayload =
          jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      closedPayload['lifecycleState'] = 'archived';
      await (_db.update(
        _db.proposalRevisions,
      )..where((t) => t.id.equals(revisionId))).write(
        ProposalRevisionsCompanion(
          payloadJson: drift.Value(jsonEncode(closedPayload)),
        ),
      );
      await (_db.update(_db.proposalPackages)
            ..where((t) => t.id.equals(packageId)))
          .write(
        ProposalPackagesCompanion(
          activeRevisionId: drift.Value(revisionId),
          pendingRevisionId: const drift.Value(null),
        ),
      );
      // Keep every package row for this plan aligned (legacy import duplicates).
      final siblingPackages = await (_db.select(_db.proposalPackages)
            ..where((t) => t.planId.equals(planId)))
          .get();
      for (final sibling in siblingPackages) {
        if (sibling.id == packageId) continue;
        await (_db.update(_db.proposalPackages)
              ..where((t) => t.id.equals(sibling.id)))
            .write(
          ProposalPackagesCompanion(
            activeRevisionId: drift.Value(revisionId),
            pendingRevisionId: const drift.Value(null),
          ),
        );
      }
    });
    await HousingProposalTransportService(_db).applyActiveRevisionPayloadToPlan(
      planId: planId,
      revisionId: revisionId,
    );
    assert(() {
      () async {
        final agr = await _db.getAgreementForPlan(planId);
        debugPrint(
          'housing: activated revision=$revisionId plan=$planId '
          'agreementEnd=${agr?.periodEnd.toIso8601String()}',
        );
      }();
      return true;
    }());
    await HousingProposalTransportService(_db).reconcileStalePackagePending(
      planId,
    );
    try {
      final trialStore = await HousingTrialConsumptionStore.load();
      final trialEligible = await housingRosterMayReceiveTrial(
        planId: planId,
        participantIds: participantIds,
        trialStore: trialStore,
      );
      await trialStore.setPlanTrialEligible(planId, trialEligible);
    } on Object catch (e, st) {
      debugPrint('housing: trial eligibility evaluation skipped: $e\n$st');
    }
    final coordinator = EntitlementCoordinator.maybeInstance;
    if (coordinator != null) {
      await coordinator.reportRosterIfComplete(
        planId: planId,
        revisionId: revisionId,
        participantIds: participantIds,
      );
    }
    return ProposalActivationOutcome.activated;
  }

  /// Parsed [agreement.periodStart] / [periodEnd] from a revision payload, or null.
  ({DateTime start, DateTime end})? _agreementPeriodFromRevisionPayload(
    Map<String, Object?> payload,
  ) {
    final agr = payload['agreement'];
    if (agr is! Map) return null;
    final ps = agr['periodStart'];
    final pe = agr['periodEnd'];
    if (ps is! String || pe is! String) return null;
    return (start: DateTime.parse(ps), end: DateTime.parse(pe));
  }

  Future<Map<String, Object?>> loadRevisionPayload(String revisionId) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingle();
    return jsonDecode(rev.payloadJson) as Map<String, Object?>;
  }
}

enum ProposalResponseStatus { pending, accepted, rejected, negotiate }

/// Result of [PlanAgreementProposalService.tryActivateIfUnanimous].
enum ProposalActivationOutcome {
  /// Package now references this revision as active; pending cleared.
  activated,

  /// At least one [participantIds] entry is missing or not `accepted`.
  notUnanimous,

  /// Revision payload had no parseable `agreement.periodStart` / `periodEnd`.
  missingAgreementPeriodInRevision,

  /// Would overlap another housing plan on this device by the day rule (≥2 shared days).
  blockedByOverlappingAgreementPeriod,

  /// Agreement start date cannot change after published realized expenses exist.
  blockedAgreementStartDateChange,
}
