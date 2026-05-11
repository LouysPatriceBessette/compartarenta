import 'dart:convert';

/// Built-in suggestion panels (user may dismiss until a binding proposal exists).
const String kAgreementSuggestionCommonCleanliness = 'suggestion:common_cleanliness';
const String kAgreementSuggestionFridgeManagement = 'suggestion:fridge_management';

class AgreementCustomRule {
  AgreementCustomRule({
    required this.id,
    required this.title,
    required this.body,
    required this.enabled,
  });

  final String id;
  String title;
  String body;
  bool enabled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'enabled': enabled,
      };

  factory AgreementCustomRule.fromJson(Map<String, dynamic> m) {
    return AgreementCustomRule(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      enabled: m['enabled'] as bool? ?? true,
    );
  }
}

/// v1 JSON stored in [Agreements.agreementRulesJson].
class AgreementRulesDraft {
  AgreementRulesDraft({
    this.curfewEnabled = false,
    this.curfewNotes = '',
    this.earlyWithdrawalEnabled = true,
    this.buildingRulesEnabled = false,
    this.buildingRulesText = '',
    List<String>? dismissedSuggestionIds,
    List<AgreementCustomRule>? customRules,
  })  : dismissedSuggestionIds = List<String>.from(dismissedSuggestionIds ?? const []),
        customRules = List<AgreementCustomRule>.from(customRules ?? const []);

  bool curfewEnabled;
  /// Optional notes for the quiet-hours rule (placeholder UI until a calendar exists).
  String curfewNotes;
  bool earlyWithdrawalEnabled;
  bool buildingRulesEnabled;
  String buildingRulesText;
  final List<String> dismissedSuggestionIds;
  final List<AgreementCustomRule> customRules;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'curfewEnabled': curfewEnabled,
        'curfewNotes': curfewNotes,
        'earlyWithdrawalEnabled': earlyWithdrawalEnabled,
        'buildingRulesEnabled': buildingRulesEnabled,
        'buildingRulesText': buildingRulesText,
        'dismissedSuggestionIds': dismissedSuggestionIds,
        'customRules': customRules.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory AgreementRulesDraft.fromJson(Map<String, dynamic> m) {
    final dismissed = (m['dismissedSuggestionIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final rules = <AgreementCustomRule>[];
    final rawRules = m['customRules'] as List<dynamic>?;
    if (rawRules != null) {
      for (final r in rawRules) {
        if (r is Map<String, dynamic>) {
          rules.add(AgreementCustomRule.fromJson(r));
        }
      }
    }
    return AgreementRulesDraft(
      curfewEnabled: m['curfewEnabled'] as bool? ?? false,
      curfewNotes: m['curfewNotes'] as String? ?? '',
      earlyWithdrawalEnabled: m['earlyWithdrawalEnabled'] as bool? ?? true,
      buildingRulesEnabled: m['buildingRulesEnabled'] as bool? ?? false,
      buildingRulesText: m['buildingRulesText'] as String? ?? '',
      dismissedSuggestionIds: dismissed,
      customRules: rules,
    );
  }

  /// Parse stored JSON; merge legacy [clauses] text into building rules when JSON is empty.
  static AgreementRulesDraft parseStored({
    required String agreementRulesJson,
    required String clausesFallback,
  }) {
    final trimmed = agreementRulesJson.trim();
    if (trimmed.isEmpty || trimmed == '{}') {
      final fb = clausesFallback.trim();
      return AgreementRulesDraft(
        buildingRulesEnabled: fb.isNotEmpty,
        buildingRulesText: fb,
      );
    }
    try {
      final m = jsonDecode(trimmed) as Map<String, dynamic>;
      final draft = AgreementRulesDraft.fromJson(m);
      if (draft.buildingRulesText.trim().isEmpty && clausesFallback.trim().isNotEmpty) {
        return AgreementRulesDraft(
          curfewEnabled: draft.curfewEnabled,
          curfewNotes: draft.curfewNotes,
          earlyWithdrawalEnabled: draft.earlyWithdrawalEnabled,
          buildingRulesEnabled: true,
          buildingRulesText: clausesFallback,
          dismissedSuggestionIds: draft.dismissedSuggestionIds,
          customRules: draft.customRules,
        );
      }
      return draft;
    } catch (_) {
      final fb = clausesFallback.trim();
      return AgreementRulesDraft(
        buildingRulesEnabled: fb.isNotEmpty,
        buildingRulesText: fb,
      );
    }
  }
}
