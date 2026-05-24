import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../housing/amendment/housing_active_agreement_service.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_active_plan_read_only_screen.dart';
import 'housing_agreement_renewal_screen.dart';
import 'housing_amendment_request_screen.dart';
import 'housing_balances_screen.dart';
import 'housing_active_hub_placeholder_screen.dart';
import 'housing_monthly_expenses_screen.dart';
import 'housing_realized_expense_form_screen.dart';
import 'housing_realized_expense_review_list_screen.dart';
import 'housing_realized_expense_review_screen.dart';

/// Operational hub for an active housing agreement (menu of actions).
class HousingActivePlanScreen extends StatefulWidget {
  const HousingActivePlanScreen({
    super.key,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  @override
  State<HousingActivePlanScreen> createState() => _HousingActivePlanScreenState();
}

class _HousingActivePlanScreenState extends State<HousingActivePlanScreen> {
  Future<_HubHeader?>? _headerFuture;
  Future<int>? _pendingReviewFuture;
  Future<bool>? _pendingAmendmentFuture;
  Timer? _pendingAmendmentPollTimer;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingReviewIfAny());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
        _onSteadyInboxTick,
      );
      unawaited(_syncPendingAmendmentPoll());
    });
  }

  @override
  void dispose() {
    _pendingAmendmentPollTimer?.cancel();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  /// While an amendment is open, poll the relay frequently. Browsers throttle the
  /// global 10s orchestrator timer when the tab is idle; this keeps the proposer
  /// hub in sync when a co-participant responds.
  Future<void> _syncPendingAmendmentPoll() async {
    final transport = HousingProposalTransportService(AppDatabase.processScope);
    final hasPending = await transport.hasOpenPendingAmendment(widget.planId);
    if (!mounted) return;
    if (!hasPending) {
      _pendingAmendmentPollTimer?.cancel();
      _pendingAmendmentPollTimer = null;
      return;
    }
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null) {
      unawaited(
        orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
          debugPrint('housing hub pending poll: $e\n$st');
        }),
      );
    }
    if (_pendingAmendmentPollTimer != null) return;
    _pendingAmendmentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final pollOrch = HandshakeOrchestrator.maybeInstance;
      if (pollOrch == null) return;
      unawaited(
        pollOrch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
          debugPrint('housing hub pending poll: $e\n$st');
        }),
      );
    });
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload() {
    setState(() {
      _headerFuture = _loadHeader();
      _pendingReviewFuture = RealizedExpenseLedgerService(
        AppDatabase.processScope,
      ).countWaitingForYou(
        packageId: widget.packageId,
        planId: widget.planId,
      );
      _pendingAmendmentFuture = HousingProposalTransportService(
        AppDatabase.processScope,
      ).shouldShowPendingAmendmentHubBanner(widget.planId);
    });
    unawaited(_syncPendingAmendmentPoll());
  }

  /// Resolves pending amendment at tap time (not from a cached [FutureBuilder]).
  Future<void> _onAmendmentHubTap(BuildContext context) async {
    final db = AppDatabase.processScope;
    final transport = HousingProposalTransportService(db);
    final prefs = widget.prefs ?? await AppPreferences.load();
    final hasPending = await transport.hasOpenPendingAmendment(widget.planId);
    if (!context.mounted) return;

    if (hasPending) {
      final pendingId = await transport.pendingRevisionIdForPlan(widget.planId);
      if (!context.mounted) return;
      await openHousingPendingProposalOrAmendment(
        context,
        db: db,
        planId: widget.planId,
        prefs: prefs,
        revisionId: pendingId,
        isAmendment: true,
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => HousingAmendmentRequestScreen(
            planId: widget.planId,
            prefs: prefs,
          ),
        ),
      );
    }
    if (mounted) _reload();
  }

  Future<_HubHeader?> _loadHeader() async {
    final db = AppDatabase.processScope;
    final plan = await (db.select(db.plans)
          ..where((t) => t.id.equals(widget.planId)))
        .getSingleOrNull();
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (plan == null || agreement == null) return null;
    final prefs = widget.prefs ?? await AppPreferences.load();
    final dateFmt = effectiveDateFormat(prefs);
    final range =
        '${formatPreferenceDate(agreement.periodStart, dateFmt)}'
        ' – '
        '${formatPreferenceDate(agreement.periodEnd, dateFmt)}';
    final title = plan.title.trim().isEmpty ? plan.id : plan.title.trim();
    return _HubHeader(
      title: title,
      periodRange: range,
      currency: plan.currency.trim().isEmpty ? prefs.currency : plan.currency,
    );
  }

  void _openPendingReviewIfAny() {
    final expenseId = HousingNavigationIntent.takePendingReview();
    if (expenseId == null || !mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingRealizedExpenseReviewScreen(
          expenseId: expenseId,
          planId: widget.planId,
          packageId: widget.packageId,
          prefs: widget.prefs,
        ),
      ),
    ).then((_) {
      if (mounted) _reload();
    });
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingActiveHubPlaceholderScreen(title: title),
      ),
    );
  }

  Future<void> _openEnterExpense(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final open = await HousingActiveAgreementService(
      AppDatabase.processScope,
    ).isPlanAgreementPeriodOpen(widget.planId);
    if (!open) {
      if (!context.mounted) return;
      final goRenew = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.housingAgreementExpiredTitle),
          content: Text(l10n.housingAgreementExpiredBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.housingAgreementRenewalFork),
            ),
          ],
        ),
      );
      if (goRenew == true) {
        if (!context.mounted) return;
        final prefs = widget.prefs ?? await AppPreferences.load();
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HousingAgreementRenewalScreen(
              planId: widget.planId,
              prefs: prefs,
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingRealizedExpenseFormScreen(
          planId: widget.planId,
          packageId: widget.packageId,
          prefs: widget.prefs,
        ),
      ),
    );
    if (mounted) _reload();
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
          future: _headerFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final header = snap.data;
            return FutureBuilder<int>(
              future: _pendingReviewFuture,
              builder: (context, pendingSnap) {
                final pendingCount = pendingSnap.data ?? 0;
                return FutureBuilder<bool>(
                  future: _pendingAmendmentFuture,
                  builder: (context, amendmentSnap) {
                    final hasPendingAmendment = amendmentSnap.data ?? false;
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (hasPendingAmendment)
                      Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.edit_notifications_outlined),
                          title: Text(l10n.housingActiveHubPendingAmendment),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onAmendmentHubTap(context),
                        ),
                      ),
                    if (pendingCount > 0)
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.pending_actions),
                          title: Text(
                            l10n.housingActiveHubReviewPending(pendingCount),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    HousingRealizedExpenseReviewListScreen(
                                  planId: widget.planId,
                                  packageId: widget.packageId,
                                  prefs: widget.prefs,
                                ),
                              ),
                            );
                            if (mounted) _reload();
                          },
                        ),
                      ),
                    _HubTile(
                      icon: Icons.add_card_outlined,
                      label: l10n.housingActiveHubEnterExpense,
                      onTap: () => _openEnterExpense(context),
                    ),
                    _HubTile(
                      icon: Icons.calendar_month_outlined,
                      label: l10n.housingActiveHubMonthlyExpenses,
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => HousingMonthlyExpensesScreen(
                              packageId: widget.packageId,
                              planId: widget.planId,
                              prefs: widget.prefs,
                            ),
                          ),
                        );
                      },
                    ),
                    _HubTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.housingActiveHubBalances,
                      onTap: () {
                        if (header == null) return;
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => HousingBalancesScreen(
                              planId: widget.planId,
                              currency: header.currency,
                            ),
                          ),
                        );
                      },
                    ),
                    _HubTile(
                      icon: Icons.description_outlined,
                      label: l10n.housingActiveHubViewPlan,
                      onTap: () async {
                        final prefs = widget.prefs ?? await AppPreferences.load();
                        if (!context.mounted) return;
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => HousingActivePlanReadOnlyScreen(
                              planId: widget.planId,
                              prefs: prefs,
                            ),
                          ),
                        );
                      },
                    ),
                    _HubTile(
                      icon: Icons.edit_note_outlined,
                      label: hasPendingAmendment
                          ? l10n.housingActiveHubViewPendingAmendment
                          : l10n.housingActiveHubRequestAmendment,
                      onTap: () => _onAmendmentHubTap(context),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HubHeader {
  const _HubHeader({
    required this.title,
    required this.periodRange,
    required this.currency,
  });

  final String title;
  final String periodRange;
  final String currency;
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
