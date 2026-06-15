import 'dart:convert';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/regional_unit_choices.dart';
import '../agreement_rules_diff.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../proposals/plan_agreement_proposal_service.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_amendment_settlement.dart';
import 'housing_amendment_summary.dart';
import 'housing_amendment_type.dart';
import 'housing_rules_amendment_pending.dart';

/// Loaded baseline vs proposed agreement rules for amendment UI.
class AgreementRulesAmendmentComparison {
  const AgreementRulesAmendmentComparison({
    required this.buckets,
    required this.roster,
    required this.displayCurrency,
    required this.firstDayOfWeekIndex,
  });

  final AgreementRulesChangeBuckets buckets;
  final List<Participant> roster;
  final String displayCurrency;
  final int firstDayOfWeekIndex;
}

Map<String, dynamic>? _agreementMapFromPayload(Map<String, dynamic> payload) {
  final agr = payload['agreement'];
  if (agr is Map) return agr.cast<String, dynamic>();
  return null;
}

/// Resolves baseline and proposed payloads for a preview or pending revision.
Future<AgreementRulesAmendmentComparison?> loadAgreementRulesAmendmentComparison({
  required AppDatabase db,
  required String planId,
  required AppLocalizations l10n,
  String? revisionId,
  HousingAmendmentSummary? previewSummary,
}) async {
  Map<String, dynamic> baselinePayload;
  Map<String, dynamic> proposedPayload;

  if (previewSummary != null &&
      previewSummary.type == HousingAmendmentType.ruleChange) {
    final transport = HousingProposalTransportService(db);
    final baselineId = await transport.resolveActiveRevisionIdForPlan(planId);
    if (baselineId != null) {
      final baselineRev = await (db.select(db.proposalRevisions)
            ..where((t) => t.id.equals(baselineId)))
          .getSingleOrNull();
      if (baselineRev == null) return null;
      try {
        baselinePayload =
            jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    } else {
      try {
        final snapshot = await PlanAgreementProposalService(db)
            .buildSnapshotPayloadForPlan(planId);
        baselinePayload = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    proposedPayload = await _proposedPayloadFromCurrentPlanForRules(
      db: db,
      planId: planId,
      baselinePayload: baselinePayload,
      l10n: l10n,
    );
    _applyPendingRulesAgreement(planId, proposedPayload, l10n);
  } else {
    final summary = previewSummary ??
        await loadHousingAmendmentSummary(
          db: db,
          planId: planId,
          revisionId: revisionId,
          l10n: l10n,
          dateFormat: 'YYYY-MM-DD',
        );
    if (summary == null || summary.type != HousingAmendmentType.ruleChange) {
      return null;
    }

    final transport = HousingProposalTransportService(db);
    final pendingId = revisionId ??
        await transport.pendingRevisionIdForPlan(planId) ??
        summary.revisionId;
    final activeRevisionId = await transport.resolveActiveRevisionIdForPlan(planId);

    final pendingRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(pendingId)))
        .getSingleOrNull();
    if (pendingRev == null) return null;

    try {
      proposedPayload =
          jsonDecode(pendingRev.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final isArchived =
        (proposedPayload['lifecycleState'] as String?) == 'archived';
    final baselineId = amendmentBaselineRevisionId(
      revisionPayload: proposedPayload,
      revisionId: pendingId,
      packageActiveRevisionId: activeRevisionId,
      isArchived: isArchived,
    );
    baselinePayload = proposedPayload;
    var resolvedBaselineId = baselineId;
    if (resolvedBaselineId != null) {
      var baselineRev = await (db.select(db.proposalRevisions)
            ..where((t) => t.id.equals(resolvedBaselineId!)))
          .getSingleOrNull();
      if (baselineRev == null &&
          activeRevisionId != null &&
          activeRevisionId != pendingId) {
        resolvedBaselineId = activeRevisionId;
        baselineRev = await (db.select(db.proposalRevisions)
              ..where((t) => t.id.equals(resolvedBaselineId!)))
            .getSingleOrNull();
      }
      if (baselineRev != null) {
        baselinePayload =
            jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
      }
    } else if (activeRevisionId != null &&
        activeRevisionId != pendingId &&
        !isArchived) {
      final baselineRev = await (db.select(db.proposalRevisions)
            ..where((t) => t.id.equals(activeRevisionId)))
          .getSingleOrNull();
      if (baselineRev != null) {
        baselinePayload =
            jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
      }
    }
  }

  final baselineAgr = _agreementMapFromPayload(baselinePayload);
  final proposedAgr = _agreementMapFromPayload(proposedPayload);
  if (baselineAgr == null || proposedAgr == null) return null;

  final baselineRules = normalizeAgreementRulesForComparison(
    rulesDraftFromPayloadMap(baselineAgr),
    l10n,
  );
  final proposedRules = normalizeAgreementRulesForComparison(
    rulesDraftFromPayloadMap(proposedAgr),
    l10n,
  );
  final buckets = computeAgreementRulesChangeBuckets(
    baselineRules: baselineRules,
    baselineAgreement: agreementSliceFromPayloadMap(baselineAgr),
    proposedRules: proposedRules,
    proposedAgreement: agreementSliceFromPayloadMap(proposedAgr),
    l10n: l10n,
  );

  final roster = await participantsForPlan(db, planId);
  final planRow = await (db.select(db.plans)..where((t) => t.id.equals(planId)))
      .getSingleOrNull();
  final currency = planRow?.currency.trim().isNotEmpty == true
      ? planRow!.currency.trim()
      : kDefaultCurrencyCode;

  return AgreementRulesAmendmentComparison(
    buckets: buckets,
    roster: roster,
    displayCurrency: currency,
    firstDayOfWeekIndex: 0,
  );
}

Future<Map<String, dynamic>> _proposedPayloadFromCurrentPlanForRules({
  required AppDatabase db,
  required String planId,
  required Map<String, dynamic> baselinePayload,
  required AppLocalizations l10n,
}) async {
  final proposed =
      jsonDecode(jsonEncode(baselinePayload)) as Map<String, dynamic>;
  if (HousingRulesAmendmentPendingStore.get(planId) != null) {
    _applyPendingRulesAgreement(planId, proposed, l10n);
    return proposed;
  }
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) return proposed;
  final agr = proposed['agreement'];
  if (agr is Map) {
    final agrMap = agr.cast<String, dynamic>();
    agrMap['agreementRulesJson'] = agreement.agreementRulesJson;
    agrMap['clauses'] = agreement.clauses;
    agrMap['withdrawalSameForAll'] = agreement.withdrawalSameForAll;
    agrMap['withdrawalPerParticipantJson'] =
        agreement.withdrawalPerParticipantJson;
    agrMap['minNoticeDays'] = agreement.minNoticeDays;
    agrMap['penalty'] = {
      'amountMinor': agreement.penaltyMinor,
    };
  }
  return proposed;
}

void _applyPendingRulesAgreement(
  String planId,
  Map<String, dynamic> proposedPayload,
  AppLocalizations l10n,
) {
  final pending = HousingRulesAmendmentPendingStore.get(planId);
  if (pending == null) return;
  final agr = proposedPayload['agreement'];
  if (agr is Map) {
    pending.applyToAgreementMap(
      agr.cast<String, dynamic>(),
      suggestionDefaults: agreementSuggestionDefaultsFromL10n(l10n),
    );
  }
}
