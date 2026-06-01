import 'dart:convert';

import '../agreement_rules_json.dart';

/// In-memory proposed agreement rules for a plan-change flow (not yet submitted).
class HousingRulesAmendmentPending {
  const HousingRulesAmendmentPending({
    required this.agreementRulesJson,
    required this.clauses,
    required this.minNoticeDays,
    required this.penaltyMinor,
    required this.withdrawalSameForAll,
    required this.withdrawalPerParticipantJson,
    this.baselineAgreementRulesJson,
  });

  final String agreementRulesJson;
  final String clauses;
  final int minNoticeDays;
  final int penaltyMinor;
  final String withdrawalSameForAll;
  final String withdrawalPerParticipantJson;

  /// Active revision rules JSON used to retain disabled existing optional rules.
  final String? baselineAgreementRulesJson;

  void applyToAgreementMap(
    Map<String, dynamic> agr, {
    AgreementSuggestionDefaults suggestionDefaults = const {},
  }) {
    agr['agreementRulesJson'] = sanitizeAgreementRulesJsonForBindingSubmission(
      agreementRulesJson,
      clausesFallback: clauses,
      baselineAgreementRulesJson: baselineAgreementRulesJson,
      suggestionDefaults: suggestionDefaults,
    );
    agr['clauses'] = clauses;
    agr['minNoticeDays'] = minNoticeDays;
    agr['penalty'] = {'amountMinor': penaltyMinor};
    agr['withdrawalSameForAll'] = withdrawalSameForAll;
    agr['withdrawalPerParticipantJson'] = withdrawalPerParticipantJson;
  }
}

/// Holds proposed rules between the editor, preview, and relay submit steps.
class HousingRulesAmendmentPendingStore {
  HousingRulesAmendmentPendingStore._();

  static final Map<String, HousingRulesAmendmentPending> _byPlan = {};

  static HousingRulesAmendmentPending? get(String planId) => _byPlan[planId];

  static void set(String planId, HousingRulesAmendmentPending pending) {
    _byPlan[planId] = pending;
  }

  static void clear(String planId) => _byPlan.remove(planId);

  /// Merges [pending] agreement fields into a forked revision payload.
  static void applyToPayload(
    String planId,
    Map<String, dynamic> payload, {
    AgreementSuggestionDefaults suggestionDefaults = const {},
  }) {
    final pending = get(planId);
    if (pending == null) return;
    final agr = payload['agreement'];
    if (agr is Map) {
      pending.applyToAgreementMap(
        agr.cast<String, dynamic>(),
        suggestionDefaults: suggestionDefaults,
      );
    }
  }

  /// Returns [baselinePayload] with agreement replaced by [pending] when present.
  static Map<String, dynamic> proposedPayloadFromBaseline({
    required String planId,
    required Map<String, dynamic> baselinePayload,
  }) {
    final pending = get(planId);
    if (pending == null) return baselinePayload;
    final proposed =
        jsonDecode(jsonEncode(baselinePayload)) as Map<String, dynamic>;
    final agr = proposed['agreement'];
    if (agr is Map) {
      pending.applyToAgreementMap(agr.cast<String, dynamic>());
    }
    return proposed;
  }
}
