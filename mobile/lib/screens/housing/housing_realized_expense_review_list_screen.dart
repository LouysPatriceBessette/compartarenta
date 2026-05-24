import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/format_money.dart';
import 'housing_realized_expense_review_screen.dart';

class HousingRealizedExpenseReviewListScreen extends StatefulWidget {
  const HousingRealizedExpenseReviewListScreen({
    super.key,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  @override
  State<HousingRealizedExpenseReviewListScreen> createState() =>
      _HousingRealizedExpenseReviewListScreenState();
}

class _HousingRealizedExpenseReviewListScreenState
    extends State<HousingRealizedExpenseReviewListScreen> {
  late Future<List<RealizedExpenseReviewItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _itemsFuture = RealizedExpenseLedgerService(AppDatabase.processScope)
          .listReviewItems(
            packageId: widget.packageId,
            planId: widget.planId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingRealizedExpenseReviewListTitle)),
      body: FutureBuilder<List<RealizedExpenseReviewItem>>(
        future: _itemsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return Center(child: Text(l10n.housingRealizedExpenseReviewEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final expense = item.expense;
              return Card(
                child: ListTile(
                  title: Text(
                    formatMinorAsMoney(
                      context,
                      expense.amountMinor,
                      expense.currency,
                    ),
                  ),
                  subtitle: Text(_visibilityLabel(l10n, item.visibility)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => HousingRealizedExpenseReviewScreen(
                          expenseId: expense.id,
                          planId: widget.planId,
                          packageId: widget.packageId,
                          prefs: widget.prefs,
                        ),
                      ),
                    );
                    if (mounted) _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _visibilityLabel(
    AppLocalizations l10n,
    RealizedExpenseReviewVisibility visibility,
  ) {
    return switch (visibility) {
      RealizedExpenseReviewVisibility.waitingForYou =>
        l10n.housingRealizedExpenseReviewWaitingForYou,
      RealizedExpenseReviewVisibility.waitingForOthers =>
        l10n.housingRealizedExpenseReviewWaitingForOthers,
      RealizedExpenseReviewVisibility.published =>
        l10n.housingRealizedExpenseReviewPublished,
      RealizedExpenseReviewVisibility.rejected =>
        l10n.housingRealizedExpenseReviewRejected,
    };
  }
}
