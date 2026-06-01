import 'dart:convert';

import '../l10n/app_localizations.dart';
import 'agreement_rules_json.dart';
import 'quiet_hours_week_grid.dart';

/// Built-in agreement rule slots (fixed display titles from l10n).
enum AgreementRuleBuiltinKind {
  curfew,
  earlyWithdrawal,
  building,
}

/// Identifies one agreement rule in preview / journal UI.
sealed class AgreementRuleIdentity {
  const AgreementRuleIdentity();

  const factory AgreementRuleIdentity.builtin(AgreementRuleBuiltinKind kind) =
      AgreementRuleBuiltinIdentity;

  const factory AgreementRuleIdentity.suggestion(String suggestionId) =
      AgreementRuleSuggestionIdentity;

  const factory AgreementRuleIdentity.custom(String ruleId) =
      AgreementRuleCustomIdentity;
}

final class AgreementRuleBuiltinIdentity extends AgreementRuleIdentity {
  const AgreementRuleBuiltinIdentity(this.kind);

  final AgreementRuleBuiltinKind kind;
}

final class AgreementRuleSuggestionIdentity extends AgreementRuleIdentity {
  const AgreementRuleSuggestionIdentity(this.suggestionId);

  final String suggestionId;
}

final class AgreementRuleCustomIdentity extends AgreementRuleIdentity {
  const AgreementRuleCustomIdentity(this.ruleId);

  final String ruleId;
}

/// Agreement fields needed to render early-withdrawal read-only UI.
class AgreementRulesAgreementSlice {
  const AgreementRulesAgreementSlice({
    required this.clauses,
    required this.minNoticeDays,
    required this.penaltyMinor,
    required this.withdrawalSameForAll,
    required this.withdrawalPerParticipantJson,
  });

  final String clauses;
  final int minNoticeDays;
  final int penaltyMinor;
  final String withdrawalSameForAll;
  final String withdrawalPerParticipantJson;
}

/// One rule before/after in a rules amendment.
class AgreementRuleChangeEntry {
  const AgreementRuleChangeEntry({
    required this.listTitle,
    required this.identity,
    this.beforeRules,
    this.beforeAgreement,
    this.afterRules,
    this.afterAgreement,
  });

  final String listTitle;
  final AgreementRuleIdentity identity;
  final AgreementRulesDraft? beforeRules;
  final AgreementRulesAgreementSlice? beforeAgreement;
  final AgreementRulesDraft? afterRules;
  final AgreementRulesAgreementSlice? afterAgreement;

  /// Rules draft for list/detail cards in a change group.
  AgreementRulesDraft? rulesForCategory(AgreementRulesChangeCategory category) {
    final useBefore = category == AgreementRulesChangeCategory.removed ||
        category == AgreementRulesChangeCategory.unchanged;
    return useBefore ? beforeRules : afterRules;
  }

  bool enabledForCategory(AgreementRulesChangeCategory category) {
    final rules = rulesForCategory(category);
    if (rules == null) return false;
    return isAgreementRuleEnabled(rules, identity);
  }

  bool enabledForAmendmentSide({required bool useBefore}) {
    final rules = useBefore ? beforeRules : afterRules;
    if (rules == null) return false;
    return isAgreementRuleEnabled(rules, identity);
  }
}

/// Whether this rule slot is turned on in [rules].
bool isAgreementRuleEnabled(
  AgreementRulesDraft rules,
  AgreementRuleIdentity identity,
) {
  return switch (identity) {
    AgreementRuleBuiltinIdentity(:final kind) => switch (kind) {
      AgreementRuleBuiltinKind.curfew => rules.curfewEnabled,
      AgreementRuleBuiltinKind.earlyWithdrawal => rules.earlyWithdrawalEnabled,
      AgreementRuleBuiltinKind.building => rules.buildingRulesEnabled,
    },
    AgreementRuleSuggestionIdentity(:final suggestionId) =>
      agreementSuggestionIsEnabled(rules, suggestionId),
    AgreementRuleCustomIdentity(:final ruleId) => () {
      for (final r in rules.customRules) {
        if (r.id == ruleId) return r.enabled;
      }
      return false;
    }(),
  };
}

enum AgreementRulesChangeCategory {
  added,
  modified,
  removed,
  unchanged,
}

/// Partition of all rules touched by a rules amendment.
class AgreementRulesChangeBuckets {
  const AgreementRulesChangeBuckets({
    required this.added,
    required this.modified,
    required this.removed,
    required this.unchanged,
  });

  final List<AgreementRuleChangeEntry> added;
  final List<AgreementRuleChangeEntry> modified;
  final List<AgreementRuleChangeEntry> removed;
  final List<AgreementRuleChangeEntry> unchanged;

  bool get hasMeaningfulChange =>
      added.isNotEmpty || modified.isNotEmpty || removed.isNotEmpty;

  List<AgreementRuleChangeEntry> entriesFor(AgreementRulesChangeCategory category) =>
      switch (category) {
        AgreementRulesChangeCategory.added => added,
        AgreementRulesChangeCategory.modified => modified,
        AgreementRulesChangeCategory.removed => removed,
        AgreementRulesChangeCategory.unchanged => unchanged,
      };
}

AgreementRulesAgreementSlice agreementSliceFromPayloadMap(
  Map<String, dynamic> agrMap,
) {
  final penalty = agrMap['penalty'];
  var penaltyMinor = 0;
  if (penalty is Map) {
    penaltyMinor = (penalty['amountMinor'] as num?)?.toInt() ?? 0;
  } else {
    penaltyMinor = (agrMap['penaltyMinor'] as num?)?.toInt() ?? 0;
  }
  return AgreementRulesAgreementSlice(
    clauses: agrMap['clauses']?.toString() ?? '',
    minNoticeDays: (agrMap['minNoticeDays'] as num?)?.toInt() ?? 0,
    penaltyMinor: penaltyMinor,
    withdrawalSameForAll:
        agrMap['withdrawalSameForAll']?.toString() ?? 'true',
    withdrawalPerParticipantJson:
        agrMap['withdrawalPerParticipantJson']?.toString() ?? '{}',
  );
}

AgreementRulesDraft rulesDraftFromPayloadMap(Map<String, dynamic> agrMap) {
  return AgreementRulesDraft.parseStored(
    agreementRulesJson: agrMap['agreementRulesJson']?.toString() ?? '',
    clausesFallback: agrMap['clauses']?.toString() ?? '',
  );
}

/// Normalizes rules for amendment diff / preview (suggestions → custom rules).
AgreementRulesDraft normalizeAgreementRulesForComparison(
  AgreementRulesDraft draft,
  AppLocalizations l10n,
) =>
    draft.materializeInForceSuggestions(
      defaults: agreementSuggestionDefaultsFromL10n(l10n),
    );

AgreementSuggestionDefaults agreementSuggestionDefaultsFromL10n(
  AppLocalizations l10n,
) =>
    agreementSuggestionDefaultsFromLabels(
      cleanlinessTitle: l10n.housingAgreementSuggestionCleanlinessTitle,
      cleanlinessBody: l10n.housingAgreementSuggestionCleanlinessBody,
      fridgeTitle: l10n.housingAgreementSuggestionFridgeTitle,
      fridgeBody: l10n.housingAgreementSuggestionFridgeBody,
    );

/// Classifies every rule into exactly one bucket.
///
/// Rules with user-editable titles ([AgreementCustomRule] and in-force
/// suggestions) are paired by trimmed display title. Built-in slots pair by
/// [AgreementRuleBuiltinKind].
AgreementRulesChangeBuckets computeAgreementRulesChangeBuckets({
  required AgreementRulesDraft baselineRules,
  required AgreementRulesAgreementSlice baselineAgreement,
  required AgreementRulesDraft proposedRules,
  required AgreementRulesAgreementSlice proposedAgreement,
  required AppLocalizations l10n,
}) {
  final added = <AgreementRuleChangeEntry>[];
  final modified = <AgreementRuleChangeEntry>[];
  final removed = <AgreementRuleChangeEntry>[];
  final unchanged = <AgreementRuleChangeEntry>[];

  void classifyBuiltin(AgreementRuleBuiltinKind kind) {
    final title = _builtinTitle(l10n, kind);
    final identity = AgreementRuleIdentity.builtin(kind);
    final beforeEqual = _builtinStatesEqual(
      kind: kind,
      rules: baselineRules,
      agreement: baselineAgreement,
      otherRules: proposedRules,
      otherAgreement: proposedAgreement,
    );
    if (beforeEqual) {
      unchanged.add(
        AgreementRuleChangeEntry(
          listTitle: title,
          identity: identity,
          beforeRules: baselineRules,
          beforeAgreement: baselineAgreement,
          afterRules: proposedRules,
          afterAgreement: proposedAgreement,
        ),
      );
      return;
    }
    modified.add(
      AgreementRuleChangeEntry(
        listTitle: title,
        identity: identity,
        beforeRules: baselineRules,
        beforeAgreement: baselineAgreement,
        afterRules: proposedRules,
        afterAgreement: proposedAgreement,
      ),
    );
  }

  for (final kind in AgreementRuleBuiltinKind.values) {
    classifyBuiltin(kind);
  }

  final baselineTitleRules = _titleMatchedRules(
    baselineRules,
    l10n,
  );
  final proposedTitleRules = _titleMatchedRules(
    proposedRules,
    l10n,
  );

  final allTitles = <String>{
    ...baselineTitleRules.keys,
    ...proposedTitleRules.keys,
  };

  for (final titleKey in allTitles) {
    final before = baselineTitleRules[titleKey];
    final after = proposedTitleRules[titleKey];
    final listTitle = before?.displayTitle ?? after?.displayTitle ?? titleKey;

    if (before == null && after != null) {
      added.add(
        AgreementRuleChangeEntry(
          listTitle: listTitle,
          identity: after.identity,
          afterRules: proposedRules,
          afterAgreement: proposedAgreement,
        ),
      );
    } else if (before != null && after == null) {
      removed.add(
        AgreementRuleChangeEntry(
          listTitle: listTitle,
          identity: before.identity,
          beforeRules: baselineRules,
          beforeAgreement: baselineAgreement,
        ),
      );
    } else if (before != null && after != null) {
      if (_titleMatchedRuleStatesEqual(before, after)) {
        unchanged.add(
          AgreementRuleChangeEntry(
            listTitle: listTitle,
            identity: after.identity,
            beforeRules: baselineRules,
            beforeAgreement: baselineAgreement,
            afterRules: proposedRules,
            afterAgreement: proposedAgreement,
          ),
        );
      } else {
        modified.add(
          AgreementRuleChangeEntry(
            listTitle: listTitle,
            identity: after.identity,
            beforeRules: baselineRules,
            beforeAgreement: baselineAgreement,
            afterRules: proposedRules,
            afterAgreement: proposedAgreement,
          ),
        );
      }
    }
  }

  return AgreementRulesChangeBuckets(
    added: added,
    modified: modified,
    removed: removed,
    unchanged: unchanged,
  );
}

class _TitleMatchedRule {
  const _TitleMatchedRule({
    required this.titleKey,
    required this.displayTitle,
    required this.identity,
    required this.stateJson,
  });

  final String titleKey;
  final String displayTitle;
  final AgreementRuleIdentity identity;
  final String stateJson;
}

String _builtinTitle(AppLocalizations l10n, AgreementRuleBuiltinKind kind) =>
    switch (kind) {
      AgreementRuleBuiltinKind.curfew =>
        l10n.housingAgreementRuleCurfewTitle,
      AgreementRuleBuiltinKind.earlyWithdrawal =>
        l10n.housingAgreementRuleEarlyWithdrawalTitle,
      AgreementRuleBuiltinKind.building =>
        l10n.housingAgreementRuleBuildingTitle,
    };

bool _builtinStatesEqual({
  required AgreementRuleBuiltinKind kind,
  required AgreementRulesDraft rules,
  required AgreementRulesAgreementSlice agreement,
  required AgreementRulesDraft otherRules,
  required AgreementRulesAgreementSlice otherAgreement,
}) {
  return switch (kind) {
    AgreementRuleBuiltinKind.curfew =>
      rules.curfewEnabled == otherRules.curfewEnabled &&
          quietHoursGridsEqual(rules.quietHalfHours, otherRules.quietHalfHours),
    AgreementRuleBuiltinKind.earlyWithdrawal =>
      rules.earlyWithdrawalEnabled == otherRules.earlyWithdrawalEnabled &&
          agreement.minNoticeDays == otherAgreement.minNoticeDays &&
          agreement.penaltyMinor == otherAgreement.penaltyMinor &&
          agreement.withdrawalSameForAll == otherAgreement.withdrawalSameForAll &&
          agreement.withdrawalPerParticipantJson ==
              otherAgreement.withdrawalPerParticipantJson,
    AgreementRuleBuiltinKind.building =>
      rules.buildingRulesEnabled == otherRules.buildingRulesEnabled &&
          _normalizedBuildingText(rules, agreement) ==
              _normalizedBuildingText(otherRules, otherAgreement),
  };
}

String _normalizedBuildingText(
  AgreementRulesDraft rules,
  AgreementRulesAgreementSlice agreement,
) {
  final text = rules.buildingRulesText.trim();
  if (text.isNotEmpty) return text;
  return agreement.clauses.trim();
}

Map<String, _TitleMatchedRule> _titleMatchedRules(
  AgreementRulesDraft rules,
  AppLocalizations l10n,
) {
  final out = <String, _TitleMatchedRule>{};

  for (final r in rules.customRules) {
    final displayTitle = r.title.trim().isEmpty
        ? l10n.housingAgreementRuleCustomTitleLabel
        : r.title.trim();
    final titleKey = displayTitle;
    out[titleKey] = _TitleMatchedRule(
      titleKey: titleKey,
      displayTitle: displayTitle,
      identity: AgreementRuleIdentity.custom(r.id),
      stateJson: jsonEncode({
        'enabled': r.enabled,
        'body': r.body,
        'id': r.id,
      }),
    );
  }

  void addSuggestion({
    required String suggestionId,
    required String defaultTitle,
    required String defaultBody,
  }) {
    if (!agreementSuggestionIsInForce(rules, suggestionId)) return;
    final edit = rules.suggestionEdits[suggestionId];
    final edited = agreementSuggestionWasEdited(
      rules,
      suggestionId,
      defaultTitle: defaultTitle,
      defaultBody: defaultBody,
    );
    final displayTitle = edit?.title.trim().isNotEmpty == true
        ? edit!.title.trim()
        : defaultTitle.trim();
    final titleKey = displayTitle;
    out[titleKey] = _TitleMatchedRule(
      titleKey: titleKey,
      displayTitle: displayTitle,
      identity: AgreementRuleIdentity.suggestion(suggestionId),
      stateJson: jsonEncode({
        'enabled': true,
        'title': edit?.title ?? '',
        'body': edit?.body ?? '',
        'edited': edited,
        'dismissed': false,
      }),
    );
  }

  addSuggestion(
    suggestionId: kAgreementSuggestionCommonCleanliness,
    defaultTitle: l10n.housingAgreementSuggestionCleanlinessTitle,
    defaultBody: l10n.housingAgreementSuggestionCleanlinessBody,
  );
  addSuggestion(
    suggestionId: kAgreementSuggestionFridgeManagement,
    defaultTitle: l10n.housingAgreementSuggestionFridgeTitle,
    defaultBody: l10n.housingAgreementSuggestionFridgeBody,
  );

  return out;
}

bool _titleMatchedRuleStatesEqual(_TitleMatchedRule a, _TitleMatchedRule b) =>
    a.stateJson == b.stateJson;
