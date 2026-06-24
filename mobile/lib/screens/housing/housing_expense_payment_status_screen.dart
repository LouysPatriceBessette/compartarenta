import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/settlement/housing_agreement_month_window.dart';
import '../../housing/realized_expense/expense_payment_status.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_body_padding.dart';
import 'widgets/expense_payment_status_graph.dart';
import 'widgets/housing_chart_palette.dart';

class HousingExpensePaymentStatusScreen extends StatefulWidget {
  const HousingExpensePaymentStatusScreen({
    super.key,
    required this.packageId,
    required this.planId,
    this.prefs,
  });

  final String packageId;
  final String planId;
  final AppPreferences? prefs;

  @override
  State<HousingExpensePaymentStatusScreen> createState() =>
      _HousingExpensePaymentStatusScreenState();
}

class _HousingExpensePaymentStatusScreenState
    extends State<HousingExpensePaymentStatusScreen> {
  late DateTime _month;
  late Future<HousingAgreementMonthWindow?> _windowFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _windowFuture = _loadWindow();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    _pollInboxOnce();
  }

  @override
  void dispose() {
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _pollInboxOnce() {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    unawaited(
      orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing expense payment status poll: $e\n$st');
      }),
    );
  }

  Future<HousingAgreementMonthWindow?> _loadWindow() =>
      HousingAgreementMonthWindow.forPlan(
        AppDatabase.processScope,
        widget.planId,
      );

  void _shiftMonth(HousingAgreementMonthWindow window, int delta) {
    setState(() {
      final current = window.clamp(_month);
      _month = window.clamp(DateTime(current.year, current.month + delta));
    });
  }

  Future<void> _showPaymentDetails({
    required ExpensePaymentStatusBar bar,
    required String? dateFmt,
    required String currency,
  }) async {
    final l10n = AppLocalizations.of(context);
    await showAppDialog<void>(
      context: context,
      guardKey: 'expensePaymentStatus.details',
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.housingExpensePaymentStatusDetailsTitle(bar.title)),
          content: bar.payments.isEmpty
              ? Text(l10n.housingExpensePaymentStatusDetailsEmpty)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final payment in bar.payments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.housingExpensePaymentStatusDetailsLine(
                              formatMinorAsMoney(
                                dialogContext,
                                payment.amountMinor,
                                currency,
                              ),
                              dateFmt == null
                                  ? payment.paymentDate.toIso8601String()
                                  : formatPreferenceDate(
                                      payment.paymentDate,
                                      dateFmt,
                                    ),
                              payment.payerDisplayName,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonDone),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingExpensePaymentStatusTitle)),
      body: FutureBuilder<HousingAgreementMonthWindow?>(
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
                child: FutureBuilder<ExpensePaymentStatusData>(
                  future: loadExpensePaymentStatusData(
                    db: AppDatabase.processScope,
                    ledger: ledger,
                    planId: widget.planId,
                    packageId: widget.packageId,
                    year: year,
                    month: month,
                    palette: housingBalancesChartPalette,
                    fallbackTitle: l10n.housingPlanSplitNoCategory,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snap.data;
                    if (data == null || data.bars.isEmpty) {
                      return SafeArea(
                        top: false,
                        child: Center(
                          child: Text(l10n.housingExpensePaymentStatusEmpty),
                        ),
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

                        return ListView(
                          padding: screenBodyScrollPadding(context),
                          children: [
                            ExpensePaymentStatusGraph(bars: data.bars),
                            const SizedBox(height: 24),
                            Text(
                              l10n.housingBalancesLegendTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < data.bars.length; i++) ...[
                              _LegendRow(
                                bar: data.bars[i],
                                currency: data.currency,
                                onTap: () => _showPaymentDetails(
                                  bar: data.bars[i],
                                  dateFmt: dateFmt,
                                  currency: data.currency,
                                ),
                              ),
                              if (i != data.bars.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.bar,
    required this.currency,
    required this.onTap,
  });

  final ExpensePaymentStatusBar bar;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: bar.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bar.letter} - ${bar.title} - '
                  '${formatMinorAsMoney(context, bar.paidMinor, currency)}/'
                  '${formatMinorAsMoney(context, bar.totalMinor, currency)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
