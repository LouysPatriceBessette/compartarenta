import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import 'agreement_period_day_overlap.dart';
import 'housing_plan_period_gate.dart';

/// Local-only proposal / renegotiation support (sync layer TBD).
///
/// Persists self-contained proposal package revisions (payload JSON),
/// per-participant responses, and activates a revision only on unanimity.
class PlanAgreementProposalService {
  PlanAgreementProposalService(this._db);
  final AppDatabase _db;

  static const String kind = 'expensePlanAgreementProposal';

  Future<String> ensurePackageForPlan(String planId) async {
    final existing = await (_db.select(_db.proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = 'pkg:$planId';
    await _db.into(_db.proposalPackages).insert(
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

  Future<String> createRevisionFromCurrentDraft({
    required String planId,
    required String proposerParticipantId,
    DateTime? responseExpiresAt,
    String? forkedFromPackageId,
    String? forkedFromRevisionId,
  }) async {
    final packageId = await ensurePackageForPlan(planId);

    final plan = await (_db.select(_db.plans)..where((t) => t.id.equals(planId)))
        .getSingle();
    final agreement = await _db.getAgreementForPlan(planId);
    if (agreement == null) {
      throw StateError('No agreement found for plan $planId');
    }
    final lines = await _db.listPlanLines(planId);
    final ratios = await (_db.select(_db.planRatios)
          ..where((t) => t.planId.equals(planId)))
        .get();
    final groups = await (_db.select(_db.planGroups)
          ..where((t) => t.planId.equals(planId)))
        .get();

    final revisionId = 'rev:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final createdAt = DateTime.now().toUtc();

    final payload = <String, Object?>{
      'kind': kind,
      'packageId': packageId,
      'revisionId': revisionId,
      'contentHash': 'local:$revisionId',
      'createdAt': createdAt.toIso8601String(),
      'proposerParticipantId': proposerParticipantId,
      'plan': {
        'type': plan.type,
        'title': plan.title,
        'defaultCurrency': plan.currency,
        'groups': [
          for (final g in groups) {'id': g.id, 'title': g.title}
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
              'amountMinor': l.amountMinor,
              'minAmountMinor': l.minAmountMinor,
              'maxAmountMinor': l.maxAmountMinor,
              'cadence': l.cadence,
              'recurrenceDayOfMonth': l.recurrenceDayOfMonth,
              if (l.groupId != null) 'groupId': l.groupId,
            }
        ],
        'ratios': [
          for (final r in ratios)
            {
              'participantId': r.participantId,
              if (r.lineId != null) 'lineId': r.lineId,
              if (r.groupId != null) 'groupId': r.groupId,
              'weight': r.weight,
            }
        ],
      },
      'agreement': {
        'version': agreement.version,
        'periodStart': agreement.periodStart.toIso8601String(),
        'periodEnd': agreement.periodEnd.toIso8601String(),
        'minNoticeDays': agreement.minNoticeDays,
        'penalty': {'currency': plan.currency, 'amountMinor': agreement.penaltyMinor},
        'clauses': agreement.clauses,
        'withdrawalSameForAll': agreement.withdrawalSameForAll,
        'withdrawalPerParticipantJson': agreement.withdrawalPerParticipantJson,
      },
      'responseExpiresAt': responseExpiresAt?.toIso8601String(),
      'lifecycleState': 'open',
      ?forkedFromPackageId: forkedFromPackageId,
      ?forkedFromRevisionId: forkedFromRevisionId,
    };

    await _db.transaction(() async {
      await _db.into(_db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: revisionId,
              packageId: packageId,
              contentHash: 'local:$revisionId',
              proposerParticipantId: proposerParticipantId,
              payloadJson: jsonEncode(payload),
              createdAt: createdAt,
            ),
          );

      await (_db.update(_db.proposalPackages)
            ..where((t) => t.id.equals(packageId)))
          .write(ProposalPackagesCompanion(
            pendingRevisionId: drift.Value(revisionId),
          ));

      await recordResponse(
        revisionId: revisionId,
        participantId: proposerParticipantId,
        status: ProposalResponseStatus.accepted,
      );
    });

    return revisionId;
  }

  Future<void> recordResponse({
    required String revisionId,
    required String participantId,
    required ProposalResponseStatus status,
  }) async {
    final id = 'resp:$revisionId:$participantId';
    await _db.into(_db.proposalResponses).insertOnConflictUpdate(
          ProposalResponsesCompanion.insert(
            id: id,
            revisionId: revisionId,
            participantId: participantId,
            status: status.name,
            respondedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<ProposalActivationOutcome> tryActivateIfUnanimous({
    required String planId,
    required String revisionId,
    required List<String> participantIds,
  }) async {
    final packageId = await ensurePackageForPlan(planId);

    final responses = await (_db.select(_db.proposalResponses)
          ..where((t) => t.revisionId.equals(revisionId)))
        .get();

    final byParticipant = {
      for (final r in responses) r.participantId: r.status,
    };

    final unanimous = participantIds.isNotEmpty &&
        participantIds.every((p) => byParticipant[p] == ProposalResponseStatus.accepted.name);

    if (!unanimous) return ProposalActivationOutcome.notUnanimous;

    final payload = await loadRevisionPayload(revisionId);
    final period = _agreementPeriodFromRevisionPayload(payload);
    if (period == null) {
      return ProposalActivationOutcome.missingAgreementPeriodInRevision;
    }

    final blocking =
        await listBlockingAgreementDayRanges(_db, excludePlanId: planId);
    if (candidateConflictsWithAnyBlockingRange(
          period.start,
          period.end,
          blocking,
        )) {
      return ProposalActivationOutcome.blockedByOverlappingAgreementPeriod;
    }

    await _db.transaction(() async {
      await (_db.update(_db.proposalPackages)
            ..where((t) => t.id.equals(packageId)))
          .write(
        ProposalPackagesCompanion(
          activeRevisionId: drift.Value(revisionId),
          pendingRevisionId: const drift.Value.absent(),
        ),
      );
    });
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
    final rev = await (_db.select(_db.proposalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingle();
    return jsonDecode(rev.payloadJson) as Map<String, Object?>;
  }
}

enum ProposalResponseStatus {
  pending,
  accepted,
  rejected,
  negotiate,
}

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
}
