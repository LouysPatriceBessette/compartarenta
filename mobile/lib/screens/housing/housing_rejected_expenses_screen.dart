import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_description_display.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_realized_expense_review_screen.dart';

class HousingRejectedExpensesScreen extends StatelessWidget {
  const HousingRejectedExpensesScreen({
    super.key,
    required this.packageId,
    required this.planId,
    required this.year,
    required this.month,
    this.prefs,
  });

  final String packageId;
  final String planId;
  final int year;
  final int month;
  final AppPreferences? prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingRejectedExpensesTitle)),
      body: FutureBuilder<List<RealizedExpense>>(
        future: ledger.listRejectedForMonth(
          packageId: packageId,
          planId: planId,
          year: year,
          month: month,
        ),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data ?? const [];
          if (rows.isEmpty) {
            return SafeArea(
              top: false,
              child: Center(child: Text(l10n.housingRejectedExpensesEmpty)),
            );
          }
          return FutureBuilder<AppPreferences>(
            future: prefs != null ? Future.value(prefs) : AppPreferences.load(),
            builder: (context, prefsSnap) {
              final loadedPrefs = prefsSnap.data;
              final dateFmt = loadedPrefs == null
                  ? null
                  : effectiveDateFormat(loadedPrefs);
              return ListView.separated(
                padding: screenBodyScrollPadding(
                  context,
                  content: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                ),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = rows[index];
                    final subtitleParts = <String>[];
                    if (dateFmt != null) {
                      subtitleParts.add(
                        formatPreferenceDate(expense.paymentDate, dateFmt),
                      );
                    }
                    final description = realizedExpenseDescriptionForList(
                      l10n,
                      expense,
                    );
                    if (description.isNotEmpty) {
                      subtitleParts.add(description);
                    }
                    return Card(
                      child: ListTile(
                        title: Text(
                          formatMinorAsMoney(
                            context,
                            expense.amountMinor,
                            expense.currency,
                          ),
                        ),
                        subtitle: subtitleParts.isEmpty
                            ? null
                            : Text(subtitleParts.join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  HousingRealizedExpenseReviewScreen(
                                    expenseId: expense.id,
                                    planId: planId,
                                    packageId: packageId,
                                    prefs: prefs,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
            },
          );
        },
      ),
    );
  }
}
