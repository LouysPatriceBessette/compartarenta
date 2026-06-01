import 'package:compartarenta/housing/agreement_rules_diff.dart';
import 'package:compartarenta/housing/agreement_rules_json.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  final emptyAgreement = AgreementRulesAgreementSlice(
    clauses: '',
    minNoticeDays: 30,
    penaltyMinor: 0,
    withdrawalSameForAll: 'true',
    withdrawalPerParticipantJson: '{}',
  );

  test('custom rule same title different id is modified not add+remove', () {
    final baseline = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'a',
          title: 'Animaux',
          body: 'Interdits',
          enabled: true,
        ),
      ],
    );
    final proposed = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'b',
          title: 'Animaux',
          body: 'Chats seulement',
          enabled: true,
        ),
      ],
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: baseline,
      baselineAgreement: emptyAgreement,
      proposedRules: proposed,
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    expect(buckets.added, isEmpty);
    expect(buckets.removed, isEmpty);
    expect(buckets.modified.map((e) => e.listTitle), contains('Animaux'));
    expect(buckets.unchanged.length, greaterThan(0));
  });

  test('custom rule title change is removed and added', () {
    final baseline = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'a',
          title: 'Ancien titre',
          body: 'Corps',
          enabled: true,
        ),
      ],
    );
    final proposed = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'a',
          title: 'Nouveau titre',
          body: 'Corps',
          enabled: true,
        ),
      ],
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: baseline,
      baselineAgreement: emptyAgreement,
      proposedRules: proposed,
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    expect(buckets.modified.map((e) => e.listTitle), isNot(contains('Ancien titre')));
    expect(buckets.removed.map((e) => e.listTitle), contains('Ancien titre'));
    expect(buckets.added.map((e) => e.listTitle), contains('Nouveau titre'));
  });

  test('inactive edited suggestion is not in any bucket', () {
    final draft = AgreementRulesDraft(
      suggestionEdits: {
        kAgreementSuggestionCommonCleanliness: AgreementSuggestionEdit(
          title: 'Propreté perso',
          body: 'Texte modifié',
        ),
      },
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: draft,
      baselineAgreement: emptyAgreement,
      proposedRules: draft,
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    final suggestionTitles = [
      ...buckets.added,
      ...buckets.modified,
      ...buckets.removed,
      ...buckets.unchanged,
    ]
        .where(
          (e) =>
              e.identity is AgreementRuleSuggestionIdentity &&
              (e.identity as AgreementRuleSuggestionIdentity).suggestionId ==
                  kAgreementSuggestionCommonCleanliness,
        )
        .map((e) => e.listTitle)
        .toList();
    expect(suggestionTitles, isEmpty);
  });

  test('enabling an edited suggestion is added vs inactive baseline', () {
    final baseline = AgreementRulesDraft(
      suggestionEdits: {
        kAgreementSuggestionCommonCleanliness: AgreementSuggestionEdit(
          title: 'Propreté perso',
          body: 'Texte modifié',
        ),
      },
    );
    final proposed = AgreementRulesDraft(
      enabledSuggestionIds: {kAgreementSuggestionCommonCleanliness},
      suggestionEdits: baseline.suggestionEdits,
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: baseline,
      baselineAgreement: emptyAgreement,
      proposedRules: proposed,
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    expect(buckets.added.map((e) => e.listTitle), contains('Propreté perso'));
    expect(buckets.removed, isEmpty);
  });

  test('disabled existing optional rule is modified not removed', () {
    final baseline = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'rule:a',
          title: 'Animaux',
          body: 'Interdits',
          enabled: true,
        ),
      ],
    );
    final proposed = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'rule:a',
          title: 'Animaux',
          body: 'Interdits',
          enabled: false,
        ),
      ],
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: normalizeAgreementRulesForComparison(baseline, l10n),
      baselineAgreement: emptyAgreement,
      proposedRules: normalizeAgreementRulesForComparison(proposed, l10n),
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    expect(buckets.removed, isEmpty);
    expect(buckets.modified.map((e) => e.listTitle), contains('Animaux'));
  });

  test('deleted optional rule is removed', () {
    final baseline = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'rule:a',
          title: 'Animaux',
          body: 'Interdits',
          enabled: true,
        ),
      ],
    );
    final proposed = AgreementRulesDraft();
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: normalizeAgreementRulesForComparison(baseline, l10n),
      baselineAgreement: emptyAgreement,
      proposedRules: normalizeAgreementRulesForComparison(proposed, l10n),
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    expect(buckets.removed.map((e) => e.listTitle), contains('Animaux'));
  });

  test('each rule appears in exactly one bucket', () {
    final baseline = AgreementRulesDraft();
    final proposed = AgreementRulesDraft(
      customRules: [
        AgreementCustomRule(
          id: 'n',
          title: 'Nouvelle',
          body: '',
          enabled: true,
        ),
      ],
    );
    final buckets = computeAgreementRulesChangeBuckets(
      baselineRules: baseline,
      baselineAgreement: emptyAgreement,
      proposedRules: proposed,
      proposedAgreement: emptyAgreement,
      l10n: l10n,
    );
    final all = [
      ...buckets.added,
      ...buckets.modified,
      ...buckets.removed,
      ...buckets.unchanged,
    ];
    final titles = all.map((e) => e.listTitle).toList();
    expect(titles.length, titles.toSet().length);
    expect(buckets.added, hasLength(1));
  });
}
