import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';

class HousingMonthlyExpensesScreen extends StatefulWidget {
  const HousingMonthlyExpensesScreen({
    super.key,
    required this.packageId,
    required this.planId,
    this.prefs,
  });

  final String packageId;
  final String planId;
  final AppPreferences? prefs;

  @override
  State<HousingMonthlyExpensesScreen> createState() =>
      _HousingMonthlyExpensesScreenState();
}

class _HousingMonthlyExpensesScreenState
    extends State<HousingMonthlyExpensesScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);
    final year = _month.year;
    final month = _month.month;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingMonthlyExpensesTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    l10n.housingMonthlyExpensesMonthLabel(year, month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RealizedExpense>>(
              future: ledger.listPublishedForMonth(
                packageId: widget.packageId,
                year: year,
                month: month,
              ),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data ?? const [];
                if (rows.isEmpty) {
                  return Center(child: Text(l10n.housingMonthlyExpensesEmpty));
                }
                return FutureBuilder<AppPreferences>(
                  future: widget.prefs != null
                      ? Future.value(widget.prefs)
                      : AppPreferences.load(),
                  builder: (context, prefsSnap) {
                    final prefs = prefsSnap.data;
                    final dateFmt = prefs == null
                        ? null
                        : effectiveDateFormat(prefs);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final expense = rows[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              formatMinorAsMoney(
                                context,
                                expense.amountMinor,
                                expense.currency,
                              ),
                            ),
                            subtitle: dateFmt == null
                                ? null
                                : Text(
                                    formatPreferenceDate(
                                      expense.paymentDate,
                                      dateFmt,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
