import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_active_hub_placeholder_screen.dart';
import 'housing_realized_expense_form_screen.dart';

/// Operational hub for an active housing agreement (menu of actions).
class HousingActivePlanScreen extends StatelessWidget {
  const HousingActivePlanScreen({
    super.key,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  Future<_HubHeader?> _loadHeader() async {
    final db = AppDatabase.processScope;
    final plan = await (db.select(db.plans)
          ..where((t) => t.id.equals(planId)))
        .getSingleOrNull();
    final agreement = await db.getAgreementForPlan(planId);
    if (plan == null || agreement == null) return null;
    final prefs = this.prefs ?? await AppPreferences.load();
    final dateFmt = effectiveDateFormat(prefs);
    final range =
        '${formatPreferenceDate(agreement.periodStart, dateFmt)}'
        ' – '
        '${formatPreferenceDate(agreement.periodEnd, dateFmt)}';
    final title = plan.title.trim().isEmpty ? plan.id : plan.title.trim();
    return _HubHeader(title: title, periodRange: range);
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingActiveHubPlaceholderScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.housingActiveHubTitle)),
        body: FutureBuilder<_HubHeader?>(
          future: _loadHeader(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final header = snap.data;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (header != null) ...[
                  Text(
                    header.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.housingActiveHubPeriod(header.periodRange),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
                _HubTile(
                  icon: Icons.add_card_outlined,
                  label: l10n.housingActiveHubEnterExpense,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => HousingRealizedExpenseFormScreen(
                          planId: planId,
                          packageId: packageId,
                          prefs: prefs,
                        ),
                      ),
                    );
                  },
                ),
                _HubTile(
                  icon: Icons.calendar_month_outlined,
                  label: l10n.housingActiveHubMonthlyExpenses,
                  onTap: () => _openPlaceholder(
                    context,
                    l10n.housingActiveHubMonthlyExpenses,
                  ),
                ),
                _HubTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.housingActiveHubBalances,
                  onTap: () => _openPlaceholder(
                    context,
                    l10n.housingActiveHubBalances,
                  ),
                ),
                _HubTile(
                  icon: Icons.description_outlined,
                  label: l10n.housingActiveHubViewPlan,
                  onTap: () => _openPlaceholder(
                    context,
                    l10n.housingActiveHubViewPlan,
                  ),
                ),
                _HubTile(
                  icon: Icons.edit_note_outlined,
                  label: l10n.housingActiveHubRequestAmendment,
                  onTap: () => _openPlaceholder(
                    context,
                    l10n.housingActiveHubRequestAmendment,
                  ),
                ),
                _HubTile(
                  icon: Icons.import_export_outlined,
                  label: l10n.housingActiveHubExportImport,
                  onTap: () => _openPlaceholder(
                    context,
                    l10n.housingActiveHubExportImport,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HubHeader {
  const _HubHeader({required this.title, required this.periodRange});

  final String title;
  final String periodRange;
}

class _HubTile extends StatelessWidget {
  const _HubTile({
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
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
