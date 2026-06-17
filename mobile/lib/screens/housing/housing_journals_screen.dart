import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../widgets/balanced_text.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_amendment_journal_screen.dart';
import 'housing_monthly_expenses_screen.dart';
import 'housing_rejected_expenses_browse_screen.dart';

/// Hub submenu grouping expense and plan change journals.
class HousingJournalsScreen extends StatelessWidget {
  const HousingJournalsScreen({
    super.key,
    required this.packageId,
    required this.planId,
    required this.prefs,
  });

  final String packageId;
  final String planId;
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingJournalsTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          _JournalMenuTile(
            icon: Icons.check_circle_outline,
            label: l10n.housingMonthlyExpensesTitle,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HousingMonthlyExpensesScreen(
                    packageId: packageId,
                    planId: planId,
                    prefs: prefs,
                  ),
                ),
              );
            },
          ),
          _JournalMenuTile(
            icon: Icons.cancel_outlined,
            label: l10n.housingRejectedExpensesTitle,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HousingRejectedExpensesBrowseScreen(
                    packageId: packageId,
                    planId: planId,
                    prefs: prefs,
                  ),
                ),
              );
            },
          ),
          const _JournalSectionDivider(),
          _JournalMenuTile(
            icon: Icons.history,
            label: l10n.housingAmendmentJournalTitle,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HousingAmendmentJournalScreen(
                    planId: planId,
                    prefs: prefs,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JournalSectionDivider extends StatelessWidget {
  const _JournalSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }
}

class _JournalMenuTile extends StatelessWidget {
  const _JournalMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: BalancedText(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
