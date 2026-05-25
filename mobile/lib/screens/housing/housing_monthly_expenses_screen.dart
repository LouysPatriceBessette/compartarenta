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
  late Future<_MonthWindow?> _windowFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _windowFuture = _loadWindow();
  }

  Future<_MonthWindow?> _loadWindow() async {
    final agreement = await AppDatabase.processScope.getAgreementForPlan(
      widget.planId,
    );
    if (agreement == null) return null;
    final startMonth = DateTime(
      agreement.periodStart.year,
      agreement.periodStart.month,
    );
    final endMonth = DateTime(
      agreement.periodEnd.year,
      agreement.periodEnd.month,
    );
    final monthEnd = DateTime(
      agreement.periodEnd.year,
      agreement.periodEnd.month + 1,
      0,
    );
    final endDay = DateTime(
      agreement.periodEnd.year,
      agreement.periodEnd.month,
      agreement.periodEnd.day,
    );
    final extendToNextMonth =
        monthEnd.difference(endDay).inDays.abs() <= 5;
    final lastMonth = extendToNextMonth
        ? DateTime(agreement.periodEnd.year, agreement.periodEnd.month + 1)
        : endMonth;
    return _MonthWindow(firstMonth: startMonth, lastMonth: lastMonth);
  }

  void _shiftMonth(_MonthWindow window, int delta) {
    setState(() {
      final current = window.clamp(_month);
      _month = window.clamp(DateTime(current.year, current.month + delta));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingMonthlyExpensesTitle)),
      body: FutureBuilder<_MonthWindow?>(
        future: _windowFuture,
        builder: (context, windowSnap) {
          if (windowSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final window = windowSnap.data;
          if (window == null) {
            return Center(child: Text(l10n.housingRealizedExpenseLoadFailed));
          }
          final currentMonth = window.clamp(_month);
          final year = currentMonth.year;
          final month = currentMonth.month;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: currentMonth.isAfter(window.firstMonth)
                          ? () => _shiftMonth(window, -1)
                          : null,
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
                      onPressed: currentMonth.isBefore(window.lastMonth)
                          ? () => _shiftMonth(window, 1)
                          : null,
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
                      return Center(
                        child: Text(l10n.housingMonthlyExpensesEmpty),
                      );
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
                            final subtitleParts = <String>[];
                            if (dateFmt != null) {
                              subtitleParts.add(
                                formatPreferenceDate(
                                  expense.paymentDate,
                                  dateFmt,
                                ),
                              );
                            }
                            final description = (expense.description ?? '').trim();
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
          );
        },
      ),
    );
  }
}

class _MonthWindow {
  const _MonthWindow({
    required this.firstMonth,
    required this.lastMonth,
  });

  final DateTime firstMonth;
  final DateTime lastMonth;

  DateTime clamp(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (normalized.isBefore(firstMonth)) return firstMonth;
    if (normalized.isAfter(lastMonth)) return lastMonth;
    return normalized;
  }
}
