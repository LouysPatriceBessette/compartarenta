import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_diff.dart';
import '../../housing/agreement_rules_display.dart';
import '../../housing/amendment/agreement_rules_amendment_loader.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import 'housing_agreement_rules_read_only.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Group cards for a rules amendment (preview, pending, or settled journal).
class HousingAmendmentRulesChangeSection extends StatelessWidget {
  const HousingAmendmentRulesChangeSection({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    required this.comparison,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final AgreementRulesAmendmentComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstDay = prefs.resolvedFirstDayOfWeekIndex(
      Localizations.localeOf(context),
    );
    final groups = <AgreementRulesChangeCategory>[
      AgreementRulesChangeCategory.added,
      AgreementRulesChangeCategory.modified,
      AgreementRulesChangeCategory.removed,
      AgreementRulesChangeCategory.unchanged,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in groups)
          if (comparison.buckets.entriesFor(category).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RulesGroupCard(
                title: rulesChangeGroupTitle(l10n, category, comparison.buckets),
                onTap: () => _openGroup(
                  context,
                  category: category,
                  comparison: comparison,
                  firstDayOfWeekIndex: firstDay,
                ),
              ),
            ),
      ],
    );
  }

  void _openGroup(
    BuildContext context, {
    required AgreementRulesChangeCategory category,
    required AgreementRulesAmendmentComparison comparison,
    required int firstDayOfWeekIndex,
  }) {
    if (category == AgreementRulesChangeCategory.modified) {
      navigateToRoute<void>(context, 
        MaterialPageRoute<void>(
          builder: (_) => HousingAmendmentRulesModifiedGroupScreen(
            comparison: comparison,
            firstDayOfWeekIndex: firstDayOfWeekIndex,
          ),
        ),
      );
      return;
    }
    navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentRulesListGroupScreen(
          category: category,
          comparison: comparison,
          firstDayOfWeekIndex: firstDayOfWeekIndex,
        ),
      ),
    );
  }
}

String rulesChangeGroupTitle(
  AppLocalizations l10n,
  AgreementRulesChangeCategory category,
  AgreementRulesChangeBuckets buckets,
) {
  final count = buckets.entriesFor(category).length;
  return switch (category) {
    AgreementRulesChangeCategory.added =>
      l10n.housingAmendmentRulesGroupAdded(count),
    AgreementRulesChangeCategory.modified =>
      l10n.housingAmendmentRulesGroupModified(count),
    AgreementRulesChangeCategory.removed =>
      l10n.housingAmendmentRulesGroupRemoved(count),
    AgreementRulesChangeCategory.unchanged =>
      l10n.housingAmendmentRulesGroupUnchanged(count),
  };
}

class _RulesGroupCard extends StatelessWidget {
  const _RulesGroupCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of rules for added / removed / unchanged groups (accordion per rule).
class HousingAmendmentRulesListGroupScreen extends StatelessWidget {
  const HousingAmendmentRulesListGroupScreen({
    super.key,
    required this.category,
    required this.comparison,
    required this.firstDayOfWeekIndex,
  });

  final AgreementRulesChangeCategory category;
  final AgreementRulesAmendmentComparison comparison;
  final int firstDayOfWeekIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = comparison.buckets.entriesFor(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(rulesChangeGroupTitle(l10n, category, comparison.buckets)),
      ),
      body: ListView(
        padding: housingAmendmentScreenPadding(context),
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RuleAccordionTile(
                entry: entry,
                category: category,
                comparison: comparison,
                firstDayOfWeekIndex: firstDayOfWeekIndex,
              ),
            ),
        ],
      ),
    );
  }
}

/// Modified rules: Auparavant / Proposé labels + accordion cards per side.
class HousingAmendmentRulesModifiedGroupScreen extends StatelessWidget {
  const HousingAmendmentRulesModifiedGroupScreen({
    super.key,
    required this.comparison,
    required this.firstDayOfWeekIndex,
  });

  final AgreementRulesAmendmentComparison comparison;
  final int firstDayOfWeekIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = comparison.buckets.modified;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          rulesChangeGroupTitle(
            l10n,
            AgreementRulesChangeCategory.modified,
            comparison.buckets,
          ),
        ),
      ),
      body: ListView(
        padding: housingAmendmentScreenPadding(context),
        children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 40),
              Text(
                l10n.housingAmendmentRulesBeforeSubtitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _RuleDetailCard(
                entry: entries[i],
                useBefore: true,
                comparison: comparison,
                firstDayOfWeekIndex: firstDayOfWeekIndex,
                accordionOnlyRule: true,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.housingAmendmentRulesProposedSubtitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _RuleDetailCard(
                entry: entries[i],
                useBefore: false,
                comparison: comparison,
                firstDayOfWeekIndex: firstDayOfWeekIndex,
                accordionOnlyRule: true,
              ),
            ],
        ],
      ),
    );
  }
}

class _RuleAccordionTile extends StatelessWidget {
  const _RuleAccordionTile({
    required this.entry,
    required this.category,
    required this.comparison,
    required this.firstDayOfWeekIndex,
  });

  final AgreementRuleChangeEntry entry;
  final AgreementRulesChangeCategory category;
  final AgreementRulesAmendmentComparison comparison;
  final int firstDayOfWeekIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final useBefore = category == AgreementRulesChangeCategory.removed ||
        category == AgreementRulesChangeCategory.unchanged;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: agreementRuleCardTitleColumn(
            context: context,
            l10n: l10n,
            enabled: entry.enabledForCategory(category),
            title: entry.listTitle,
          ),
          children: [
            if (category == AgreementRulesChangeCategory.unchanged)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.housingAmendmentRulesUnchangedDetailHint,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            _RuleDetailCard(
              entry: entry,
              useBefore: useBefore,
              comparison: comparison,
              firstDayOfWeekIndex: firstDayOfWeekIndex,
              contentOnly: true,
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleDetailCard extends StatelessWidget {
  const _RuleDetailCard({
    required this.entry,
    required this.useBefore,
    required this.comparison,
    required this.firstDayOfWeekIndex,
    this.contentOnly = false,
    this.embedded = false,
    this.accordionOnlyRule = false,
  });

  final AgreementRuleChangeEntry entry;
  final bool useBefore;
  final AgreementRulesAmendmentComparison comparison;
  final int firstDayOfWeekIndex;
  final bool contentOnly;
  final bool embedded;
  final bool accordionOnlyRule;

  @override
  Widget build(BuildContext context) {
    final rules = useBefore ? entry.beforeRules : entry.afterRules;
    final agreement = useBefore ? entry.beforeAgreement : entry.afterAgreement;
    if (rules == null || agreement == null) return const SizedBox.shrink();

    return HousingAgreementRulesReadOnlyCard(
      rules: rules,
      agreementOverride: agreement,
      roster: comparison.roster,
      displayCurrency: comparison.displayCurrency,
      firstDayOfWeekIndex: firstDayOfWeekIndex,
      onlyRule: entry.identity,
      compact: true,
      contentOnly: contentOnly,
      embedded: embedded,
      accordionOnlyRule: accordionOnlyRule,
    );
  }
}
