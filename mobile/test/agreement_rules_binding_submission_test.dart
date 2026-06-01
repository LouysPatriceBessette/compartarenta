import 'package:compartarenta/housing/agreement_rules_diff.dart';
import 'package:compartarenta/housing/agreement_rules_json.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  final defaults = agreementSuggestionDefaultsFromL10n(l10n);

  test('forBindingSubmission drops inactive suggestions and custom rules', () {
    const suggestionId = kAgreementSuggestionCommonCleanliness;
    final draft = AgreementRulesDraft(
      curfewEnabled: false,
      earlyWithdrawalEnabled: false,
      buildingRulesEnabled: true,
      buildingRulesText: 'Règlement',
      dismissedSuggestionIds: [kAgreementSuggestionFridgeManagement],
      enabledSuggestionIds: {suggestionId},
      suggestionEdits: {
        suggestionId: AgreementSuggestionEdit(
          title: 'Propreté',
          body: 'Corps activé',
        ),
        kAgreementSuggestionFridgeManagement: AgreementSuggestionEdit(
          title: 'Frigo',
          body: 'Ne doit pas partir',
        ),
      },
      customRules: [
        AgreementCustomRule(
          id: 'on',
          title: 'Active',
          body: 'Oui',
          enabled: true,
        ),
        AgreementCustomRule(
          id: 'off',
          title: 'Inactive',
          body: 'Non',
          enabled: false,
        ),
      ],
    );

    final clean = draft
        .materializeInForceSuggestions(defaults: defaults)
        .forBindingSubmission();

    expect(clean.curfewEnabled, isFalse);
    expect(clean.earlyWithdrawalEnabled, isFalse);
    expect(clean.buildingRulesEnabled, isTrue);
    expect(clean.buildingRulesText, 'Règlement');
    expect(clean.dismissedSuggestionIds, isEmpty);
    expect(clean.enabledSuggestionIds, isEmpty);
    expect(clean.suggestionEdits, isEmpty);
    expect(
      clean.customRules.map((r) => r.id),
      contains(agreementCustomRuleIdForSuggestion(suggestionId)),
    );
    expect(clean.customRules.map((r) => r.id), isNot(contains('off')));
  });

  test('forBindingSubmission retains disabled existing optional rules', () {
    const existingId = 'rule:existing';
    final draft = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: existingId,
          title: 'Ancienne',
          body: 'Corps',
          enabled: false,
        ),
        AgreementCustomRule(
          id: 'rule:new',
          title: 'Nouvelle',
          body: '',
          enabled: false,
        ),
      ],
    );

    final clean = draft.forBindingSubmission(
      retainOptionalRuleIds: {existingId},
    );

    expect(clean.customRules, hasLength(1));
    expect(clean.customRules.single.id, existingId);
    expect(clean.customRules.single.enabled, isFalse);
  });

  test('sanitizeAgreementRulesJsonForBindingSubmission materializes suggestions', () {
    final raw = AgreementRulesDraft(
      enabledSuggestionIds: {kAgreementSuggestionCommonCleanliness},
      suggestionEdits: {
        kAgreementSuggestionCommonCleanliness: AgreementSuggestionEdit(
          title: 'Propreté perso',
          body: 'Texte',
        ),
      },
    ).encode();

    final sanitized = sanitizeAgreementRulesJsonForBindingSubmission(
      raw,
      suggestionDefaults: defaults,
    );
    final parsed = AgreementRulesDraft.parseStored(
      agreementRulesJson: sanitized,
      clausesFallback: '',
    );

    expect(parsed.enabledSuggestionIds, isEmpty);
    expect(parsed.suggestionEdits, isEmpty);
    expect(
      parsed.customRules.map((r) => r.id),
      contains(
        agreementCustomRuleIdForSuggestion(
          kAgreementSuggestionCommonCleanliness,
        ),
      ),
    );
  });

  test('materialize converts in-force suggestion to custom rule', () {
    final draft = AgreementRulesDraft(
      enabledSuggestionIds: {kAgreementSuggestionFridgeManagement},
      suggestionEdits: {
        kAgreementSuggestionFridgeManagement: AgreementSuggestionEdit(
          title: 'Frigo maison',
          body: 'Corps',
        ),
      },
    );

    final materialized =
        draft.materializeInForceSuggestions(defaults: defaults);

    expect(materialized.enabledSuggestionIds, isEmpty);
    expect(
      materialized.customRules.single.id,
      agreementCustomRuleIdForSuggestion(kAgreementSuggestionFridgeManagement),
    );
    expect(materialized.customRules.single.title, 'Frigo maison');
  });
}
