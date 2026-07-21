import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../debug/qa_housing_proposal_semantics.dart';
import '../../housing/reminders/payment_reminder_journal_month.dart';
import '../../housing/settlement/housing_agreement_month_window.dart';
import '../../housing/realized_expense/realized_expense_description_display.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_realized_expense_review_screen.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

class HousingMonthlyExpensesScreen extends StatefulWidget {
  const HousingMonthlyExpensesScreen({
    super.key,
    required this.packageId,
    required this.planId,
    this.prefs,
    this.initialMonth,
  });

  final String packageId;
  final String planId;
  final AppPreferences? prefs;

  /// When set (e.g. notification tap), open on this calendar month instead of now.
  final DateTime? initialMonth;

  @override
  State<HousingMonthlyExpensesScreen> createState() =>
      _HousingMonthlyExpensesScreenState();
}

class _HousingMonthlyExpensesScreenState
    extends State<HousingMonthlyExpensesScreen> {
  late DateTime _month;
  late Future<HousingAgreementMonthWindow?> _windowFuture;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialMonth ?? DateTime.now();
    _month = DateTime(seed.year, seed.month);
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
        debugPrint('housing monthly expenses poll: $e\n$st');
      }),
    );
    unawaited(
      orch.pollHousingPaymentReminders().catchError((Object e, StackTrace st) {
        debugPrint('housing monthly expenses reminder poll: $e\n$st');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: kDebugMode ? kQaHousingMonthlyExpensesScreen : null,
          container: true,
          child: Text(l10n.housingMonthlyExpensesTitle),
        ),
      ),
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
                    Semantics(
                      identifier:
                          kDebugMode ? kQaHousingExpensesMonthPrev : null,
                      button: true,
                      onTap: currentMonth.isAfter(window.firstMonth)
                          ? () => _shiftMonth(window, -1)
                          : null,
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: currentMonth.isAfter(window.firstMonth)
                            ? () => _shiftMonth(window, -1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.housingMonthlyExpensesMonthLabel(year, month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Semantics(
                      identifier:
                          kDebugMode ? kQaHousingExpensesMonthNext : null,
                      button: true,
                      onTap: currentMonth.isBefore(window.lastMonth)
                          ? () => _shiftMonth(window, 1)
                          : null,
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: currentMonth.isBefore(window.lastMonth)
                            ? () => _shiftMonth(window, 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<_MonthExpenseLists>(
                  future: _loadMonthExpenseLists(
                    ledger: ledger,
                    packageId: widget.packageId,
                    planId: widget.planId,
                    year: year,
                      month: month,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lists = snap.data ?? const _MonthExpenseLists();
                      if (lists.published.isEmpty && lists.reminders.isEmpty) {
                        return SafeArea(
                          top: false,
                          child: Center(
                            child: Text(l10n.housingMonthlyExpensesEmpty),
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
                          final children = <Widget>[
                            for (final entry in lists.reminders)
                              _buildReminderJournalCard(
                                context,
                                entry: entry,
                                line: lists.lineById[entry.planLineId],
                                dateFmt: dateFmt,
                              ),
                            for (final expense in lists.published)
                              _buildPublishedExpenseCard(
                                context,
                                expense: expense,
                                dateFmt: dateFmt,
                              ),
                          ];
                          return ListView.separated(
                            padding: screenBodyScrollPadding(
                              context,
                              content: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                            ),
                            itemCount: children.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => children[index],
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

  Future<_MonthExpenseLists> _loadMonthExpenseLists({
    required RealizedExpenseLedgerService ledger,
    required String packageId,
    required String planId,
    required int year,
    required int month,
  }) async {
    final published = await ledger.listPublishedForMonth(
      packageId: packageId,
      year: year,
      month: month,
    );
    final db = AppDatabase.processScope;
    final reminderAll =
        await db.listHousingPaymentOverdueJournalForPlan(planId);
    final reminders = reminderAll.where((e) {
      final d = journalMonthForHousingPaymentReminder(e);
      return d.year == year && d.month == month;
    }).toList(growable: false);
    final lines = await db.listPlanLines(planId);
    final lineById = <String, PlanLine>{
      for (final line in lines) line.id: line,
    };
    return _MonthExpenseLists(
      published: published,
      reminders: reminders,
      lineById: lineById,
    );
  }

  Widget _buildReminderJournalCard(
    BuildContext context, {
    required HousingPaymentOverdueJournalEntry entry,
    required PlanLine? line,
    required String? dateFmt,
  }) {
    final l10n = AppLocalizations.of(context);
    final isBeforeDue = entry.reminderKind == 'before_due';
    final lineTitle = line?.title ?? entry.planLineId;
    if (isBeforeDue) {
      final dueDate = _formatJournalDate(entry.periodDueAt, dateFmt);
      final receivedDate = _formatJournalDate(entry.recordedAt, dateFmt);
      final amountMinor = line?.amountMinor ?? 0;
      final currency = line?.currency ?? 'CAD';
      final amount = formatMinorAsMoney(context, amountMinor, currency);
      final titleText = _isDueDayBeforeDueJournal(entry)
          ? l10n.housingDueDayJournalCardBody(lineTitle, amount)
          : l10n.housingBeforeDueJournalCardBody(
              dueDate,
              lineTitle,
              amount,
            );
      return Semantics(
        identifier: kDebugMode ? kQaHousingBeforeDueJournalCard : null,
        container: true,
        child: Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            enabled: false,
            title: Text(
              titleText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            subtitle: Text(receivedDate),
          ),
        ),
      );
    }

    final receivedDate = _formatJournalDate(entry.recordedAt, dateFmt);
    return Semantics(
      identifier: kDebugMode ? kQaHousingOverdueJournalCard : null,
      container: true,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          enabled: false,
          title: Text(
            l10n.housingOverdueJournalCardBody(lineTitle),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          subtitle: Text(receivedDate),
        ),
      ),
    );
  }

  String _formatJournalDate(DateTime at, String? dateFmt) {
    final local = at.toLocal();
    if (dateFmt == null) {
      return '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
    }
    return formatPreferenceDate(local, dateFmt);
  }

  /// Due-day (#10 on J) journal: reception local calendar day equals due date J.
  bool _isDueDayBeforeDueJournal(HousingPaymentOverdueJournalEntry entry) {
    final received = entry.recordedAt.toLocal();
    final due = entry.periodDueAt.toLocal();
    return received.year == due.year &&
        received.month == due.month &&
        received.day == due.day;
  }

  Widget _buildPublishedExpenseCard(
    BuildContext context, {
    required RealizedExpense expense,
    required String? dateFmt,
  }) {
    final l10n = AppLocalizations.of(context);
    final subtitleParts = <String>[];
    if (dateFmt != null) {
      subtitleParts.add(formatPreferenceDate(expense.paymentDate, dateFmt));
    }
    final description = realizedExpenseDescriptionForList(l10n, expense);
    if (description.isNotEmpty) {
      subtitleParts.add(description);
    }
    return Card(
      child: ListTile(
        title: Text(
          formatMinorAsMoney(context, expense.amountMinor, expense.currency),
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await navigateToRoute<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => HousingRealizedExpenseReviewScreen(
                expenseId: expense.id,
                planId: widget.planId,
                packageId: widget.packageId,
                prefs: widget.prefs,
              ),
            ),
          );
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

class _MonthExpenseLists {
  const _MonthExpenseLists({
    this.published = const [],
    this.reminders = const [],
    this.lineById = const {},
  });

  final List<RealizedExpense> published;
  final List<HousingPaymentOverdueJournalEntry> reminders;
  final Map<String, PlanLine> lineById;
}

