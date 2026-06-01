import 'dart:convert';

import 'quiet_hours_week_grid.dart';

/// Built-in suggestion panels (user may dismiss until a binding proposal exists).
const String kAgreementSuggestionCommonCleanliness = 'suggestion:common_cleanliness';
const String kAgreementSuggestionFridgeManagement = 'suggestion:fridge_management';

const List<String> kBuiltInAgreementSuggestionIds = [
  kAgreementSuggestionCommonCleanliness,
  kAgreementSuggestionFridgeManagement,
];

/// Stable custom-rule id for a rule that originated as a built-in suggestion.
String agreementCustomRuleIdForSuggestion(String suggestionId) =>
    'rule:$suggestionId';

/// Default copy for built-in suggestions (draft wizard and materialization).
typedef AgreementSuggestionDefaults = Map<String, ({String title, String body})>;

AgreementSuggestionDefaults agreementSuggestionDefaultsFromLabels({
  required String cleanlinessTitle,
  required String cleanlinessBody,
  required String fridgeTitle,
  required String fridgeBody,
}) =>
    {
      kAgreementSuggestionCommonCleanliness: (
        title: cleanlinessTitle,
        body: cleanlinessBody,
      ),
      kAgreementSuggestionFridgeManagement: (
        title: fridgeTitle,
        body: fridgeBody,
      ),
    };

/// True when the author saved custom copy that differs from the built-in default.
bool agreementSuggestionWasEdited(
  AgreementRulesDraft draft,
  String suggestionId, {
  required String defaultTitle,
  required String defaultBody,
}) {
  final edit = draft.suggestionEdits[suggestionId];
  if (edit == null) return false;
  return edit.title.trim() != defaultTitle.trim() ||
      edit.body.trim() != defaultBody.trim();
}

/// Built-in suggestions included in the agreement (checkbox on).
bool agreementSuggestionIsEnabled(
  AgreementRulesDraft draft,
  String suggestionId,
) =>
    draft.enabledSuggestionIds.contains(suggestionId);

/// Suggestion that is part of an in-force / accepted plan (enabled, not dismissed).
bool agreementSuggestionIsInForce(
  AgreementRulesDraft draft,
  String suggestionId,
) =>
    !draft.dismissedSuggestionIds.contains(suggestionId) &&
    agreementSuggestionIsEnabled(draft, suggestionId);

/// User-edited copy of a built-in suggestion (stored in [AgreementRulesDraft] JSON).
class AgreementSuggestionEdit {
  AgreementSuggestionEdit({required this.title, required this.body});

  String title;
  String body;

  Map<String, dynamic> toJson() => {'title': title, 'body': body};

  factory AgreementSuggestionEdit.fromJson(Map<String, dynamic> m) {
    return AgreementSuggestionEdit(
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
    );
  }
}

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
    Set<String>? enabledSuggestionIds,
    List<AgreementCustomRule>? customRules,
    List<List<int>>? quietHalfHours,
    Map<String, AgreementSuggestionEdit>? suggestionEdits,
  })  : dismissedSuggestionIds = List<String>.from(dismissedSuggestionIds ?? const []),
        enabledSuggestionIds = Set<String>.from(enabledSuggestionIds ?? const {}),
        customRules = List<AgreementCustomRule>.from(customRules ?? const []),
        quietHalfHours = quietHoursDeepCopy(
          quietHalfHours ?? quietHoursEmptyGrid(),
        ),
        suggestionEdits = Map<String, AgreementSuggestionEdit>.from(
          suggestionEdits ?? const {},
        );

  bool curfewEnabled;
  /// Legacy text field; kept for decode compatibility.
  String curfewNotes;
  bool earlyWithdrawalEnabled;
  bool buildingRulesEnabled;
  String buildingRulesText;
  final List<String> dismissedSuggestionIds;
  final Set<String> enabledSuggestionIds;
  final List<AgreementCustomRule> customRules;
  final Map<String, AgreementSuggestionEdit> suggestionEdits;

  /// 7 UI columns (first column = [MaterialLocalizations.firstDayOfWeek]) × 48 half-hours.
  /// Values: 0 = none, 1 = absolute quiet, 2 = moderate quiet.
  List<List<int>> quietHalfHours;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'curfewEnabled': curfewEnabled,
        'curfewNotes': curfewNotes,
        'earlyWithdrawalEnabled': earlyWithdrawalEnabled,
        'buildingRulesEnabled': buildingRulesEnabled,
        'buildingRulesText': buildingRulesText,
        'dismissedSuggestionIds': dismissedSuggestionIds,
        'enabledSuggestionIds': enabledSuggestionIds.toList(),
        'customRules': customRules.map((e) => e.toJson()).toList(),
        'quietHalfHours': quietHalfHours.map((e) => List<int>.from(e)).toList(),
        'suggestionEdits': {
          for (final e in suggestionEdits.entries) e.key: e.value.toJson(),
        },
      };

  String encode() => jsonEncode(toJson());

  /// Converts in-force built-in suggestions into [customRules] and clears all
  /// suggestion state. Draft-only suggestions are dropped.
  AgreementRulesDraft materializeInForceSuggestions({
    required AgreementSuggestionDefaults defaults,
  }) {
    final custom = [
      for (final r in customRules)
        AgreementCustomRule(
          id: r.id,
          title: r.title,
          body: r.body,
          enabled: r.enabled,
        ),
    ];
    final customIds = custom.map((r) => r.id).toSet();

    for (final suggestionId in kBuiltInAgreementSuggestionIds) {
      if (!agreementSuggestionIsInForce(this, suggestionId)) continue;
      final customId = agreementCustomRuleIdForSuggestion(suggestionId);
      if (customIds.contains(customId)) continue;
      final def = defaults[suggestionId];
      final edit = suggestionEdits[suggestionId];
      final title = edit?.title.trim().isNotEmpty == true
          ? edit!.title.trim()
          : (def?.title ?? suggestionId);
      final body = edit?.body.trim().isNotEmpty == true
          ? edit!.body.trim()
          : (def?.body ?? '');
      custom.add(
        AgreementCustomRule(
          id: customId,
          title: title,
          body: body,
          enabled: true,
        ),
      );
      customIds.add(customId);
    }

    return AgreementRulesDraft(
      curfewEnabled: curfewEnabled,
      curfewNotes: curfewNotes,
      earlyWithdrawalEnabled: earlyWithdrawalEnabled,
      buildingRulesEnabled: buildingRulesEnabled,
      buildingRulesText: buildingRulesText,
      quietHalfHours: quietHoursDeepCopy(quietHalfHours),
      customRules: custom,
    );
  }

  /// Custom rule ids in this draft, including legacy in-force suggestions.
  Set<String> optionalRuleIdsInForce() {
    final ids = customRules.map((r) => r.id).toSet();
    for (final suggestionId in kBuiltInAgreementSuggestionIds) {
      if (agreementSuggestionIsInForce(this, suggestionId)) {
        ids.add(agreementCustomRuleIdForSuggestion(suggestionId));
      }
    }
    return ids;
  }

  /// Optional rules (custom + suggestions) not activated are omitted; built-in
  /// slots (curfew, early withdrawal, building) are always kept.
  ///
  /// When [retainOptionalRuleIds] is set (rules amendment), disabled rules whose
  /// id was in the baseline are kept; newly added disabled rules are dropped.
  AgreementRulesDraft forBindingSubmission({Set<String>? retainOptionalRuleIds}) {
    final retain = retainOptionalRuleIds ?? const <String>{};
    final enabledIds = Set<String>.from(enabledSuggestionIds);
    return AgreementRulesDraft(
      curfewEnabled: curfewEnabled,
      curfewNotes: curfewNotes,
      earlyWithdrawalEnabled: earlyWithdrawalEnabled,
      buildingRulesEnabled: buildingRulesEnabled,
      buildingRulesText: buildingRulesText,
      quietHalfHours: quietHoursDeepCopy(quietHalfHours),
      enabledSuggestionIds: enabledIds,
      customRules: [
        for (final r in customRules)
          if (r.enabled || retain.contains(r.id))
            AgreementCustomRule(
              id: r.id,
              title: r.title,
              body: r.body,
              enabled: r.enabled,
            ),
      ],
      suggestionEdits: {
        for (final e in suggestionEdits.entries)
          if (enabledIds.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// Materializes suggestions then applies [forBindingSubmission].
  AgreementRulesDraft prepareForBindingSubmission({
    required AgreementSuggestionDefaults suggestionDefaults,
    Set<String>? retainOptionalRuleIds,
  }) =>
      materializeInForceSuggestions(defaults: suggestionDefaults)
          .forBindingSubmission(retainOptionalRuleIds: retainOptionalRuleIds);

  factory AgreementRulesDraft.fromJson(Map<String, dynamic> m) {
    final dismissed = (m['dismissedSuggestionIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final enabled = (m['enabledSuggestionIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};
    final rules = <AgreementCustomRule>[];
    final rawRules = m['customRules'] as List<dynamic>?;
    if (rawRules != null) {
      for (final r in rawRules) {
        if (r is Map<String, dynamic>) {
          rules.add(AgreementCustomRule.fromJson(r));
        }
      }
    }
    final qh = quietHoursParseFromJson(m['quietHalfHours']) ?? quietHoursEmptyGrid();
    final suggestionEdits = <String, AgreementSuggestionEdit>{};
    final rawEdits = m['suggestionEdits'];
    if (rawEdits is Map) {
      for (final entry in rawEdits.entries) {
        if (entry.value is Map<String, dynamic>) {
          suggestionEdits[entry.key.toString()] = AgreementSuggestionEdit.fromJson(
            entry.value as Map<String, dynamic>,
          );
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
      enabledSuggestionIds: enabled,
      customRules: rules,
      quietHalfHours: qh,
      suggestionEdits: suggestionEdits,
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
          enabledSuggestionIds: draft.enabledSuggestionIds,
          customRules: draft.customRules,
          quietHalfHours: quietHoursDeepCopy(draft.quietHalfHours),
          suggestionEdits: draft.suggestionEdits,
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

/// Parses stored rules JSON and drops optional inactive rules for binding payloads.
String sanitizeAgreementRulesJsonForBindingSubmission(
  String agreementRulesJson, {
  String clausesFallback = '',
  String? baselineAgreementRulesJson,
  AgreementSuggestionDefaults suggestionDefaults = const {},
}) {
  final draft = AgreementRulesDraft.parseStored(
    agreementRulesJson: agreementRulesJson,
    clausesFallback: clausesFallback,
  );
  Set<String>? retainIds;
  if (baselineAgreementRulesJson != null) {
    final baseline = AgreementRulesDraft.parseStored(
      agreementRulesJson: baselineAgreementRulesJson,
      clausesFallback: clausesFallback,
    );
    retainIds = baseline
        .materializeInForceSuggestions(defaults: suggestionDefaults)
        .customRules
        .map((r) => r.id)
        .toSet();
  }
  return draft
      .prepareForBindingSubmission(
        suggestionDefaults: suggestionDefaults,
        retainOptionalRuleIds: retainIds,
      )
      .encode();
}

/// Sanitizes [agreementRulesJson] on a revision/agreement map in place.
void sanitizeAgreementRulesMapForBindingSubmission(
  Map<String, dynamic> agr, {
  String? baselineAgreementRulesJson,
  AgreementSuggestionDefaults suggestionDefaults = const {},
}) {
  agr['agreementRulesJson'] = sanitizeAgreementRulesJsonForBindingSubmission(
    agr['agreementRulesJson']?.toString() ?? '',
    clausesFallback: agr['clauses']?.toString() ?? '',
    baselineAgreementRulesJson: baselineAgreementRulesJson,
    suggestionDefaults: suggestionDefaults,
  );
}
