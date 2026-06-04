import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../housing/amendment/housing_amendment_ui_gates.dart';
import '../../housing/amendment/housing_active_agreement_service.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/housing_module_exit.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/participation/housing_participation_hub_gates.dart';
import '../../housing/participation/housing_participation_membership_service.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_active_plan_read_only_screen.dart';
import 'housing_agreement_renewal_screen.dart';
import 'housing_amendment_request_screen.dart';
import 'housing_participation_change_detail_screen.dart';
import 'housing_balances_screen.dart';
import 'housing_active_hub_placeholder_screen.dart';
import 'housing_monthly_expenses_screen.dart';
import 'housing_realized_expense_form_screen.dart';
import 'housing_realized_expense_review_list_screen.dart';
import 'housing_realized_expense_review_screen.dart';
import 'widgets/housing_participation_change_banner.dart';

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
  State<HousingActivePlanScreen> createState() =>
      _HousingActivePlanScreenState();
}

class _HousingActivePlanScreenState extends State<HousingActivePlanScreen>
    with WidgetsBindingObserver {
  Future<_HubHeader?>? _headerFuture;
  _HubHeader? _cachedHeader;
  Future<RealizedExpensePendingSummary>? _pendingExpenseFuture;
  Future<bool>? _pendingAmendmentFuture;
  Future<HousingParticipationHubGates>? _hubGatesFuture;
  /// Last resolved banner value; only updated when [_amendmentBannerGeneration] matches.
  bool _hubShowsPendingAmendment = false;
  int _amendmentBannerGeneration = 0;
  bool _openingPendingReview = false;
  bool _openingPendingAmendment = false;
  bool _openingSettledAmendment = false;
  bool _openingParticipationChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingReviewIfAny();
      _openPendingAmendmentFromNotificationIfAny();
      _openSettledAmendmentFromNotificationIfAny();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
        _onSteadyInboxTick,
      );
      HousingNavigationIntent.reviewRequestTick.addListener(
        _onPendingReviewIntent,
      );
      HousingNavigationIntent.openAmendmentTick.addListener(
        _onOpenAmendmentIntent,
      );
      HousingNavigationIntent.openSettledAmendmentTick.addListener(
        _onOpenSettledAmendmentIntent,
      );
      HousingNavigationIntent.openParticipationChangeTick.addListener(
        _onOpenParticipationChangeIntent,
      );
      unawaited(_pollHubInboxOnce());
      unawaited(_syncPendingExpenseInboxOnce());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    HousingNavigationIntent.reviewRequestTick.removeListener(
      _onPendingReviewIntent,
    );
    HousingNavigationIntent.openAmendmentTick.removeListener(
      _onOpenAmendmentIntent,
    );
    HousingNavigationIntent.openSettledAmendmentTick.removeListener(
      _onOpenSettledAmendmentIntent,
    );
    HousingNavigationIntent.openParticipationChangeTick.removeListener(
      _onOpenParticipationChangeIntent,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingReviewIfAny();
      _openPendingAmendmentFromNotificationIfAny();
      _openSettledAmendmentFromNotificationIfAny();
    });
  }

  void _onOpenSettledAmendmentIntent() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSettledAmendmentFromNotificationIfAny();
      _openParticipationChangeFromNotificationIfAny();
    });
  }

  void _onOpenParticipationChangeIntent() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openParticipationChangeFromNotificationIfAny();
    });
  }

  Future<void> _openParticipationChangeFromNotificationIfAny() async {
    if (_openingParticipationChange) return;
    final pending = HousingNavigationIntent.takePendingOpenParticipationChange();
    if (pending == null || pending.planId != widget.planId || !mounted) return;
    _openingParticipationChange = true;
    try {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder:
              (_) => HousingParticipationChangeDetailScreen(
                changeId: pending.changeId,
                planId: widget.planId,
                packageId: widget.packageId,
                prefs: widget.prefs,
              ),
        ),
      );
    } finally {
      _openingParticipationChange = false;
      if (mounted) _reload();
    }
  }

  /// One-shot relay poll when the hub opens (web may throttle background delivery).
  Future<void> _pollHubInboxOnce() async {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null) {
      await orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing hub inbox poll: $e\n$st');
      });
    }
    if (mounted) _refreshPendingBanners();
  }

  /// One-shot inbox poll when there are pending realized expenses to settle.
  Future<void> _syncPendingExpenseInboxOnce() async {
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);
    final pending = await ledger.pendingSummary(
      packageId: widget.packageId,
      planId: widget.planId,
    );
    if (!mounted) return;
    if (pending.totalPendingCount == 0) return;
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    await orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
      debugPrint('housing hub realized-expense poll: $e\n$st');
    });
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshPendingBanners();
      unawaited(_syncPendingExpenseInboxOnce());
    });
  }

  void _onPendingReviewIntent() {
    if (!mounted) return;
    _refreshPendingBanners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingReviewIfAny();
    });
  }

  void _onOpenAmendmentIntent() {
    if (!mounted) return;
    _refreshPendingBanners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingAmendmentFromNotificationIfAny();
    });
  }

  void _reload() {
    setState(() {
      _headerFuture = _loadHeader().then((header) {
        _cachedHeader = header;
        return header;
      });
    });
    _refreshPendingBanners();
    unawaited(_pollHubInboxOnce());
    unawaited(_syncPendingExpenseInboxOnce());
  }

  /// Updates amendment / expense banners only — does not reset the hub header.
  void _refreshPendingBanners() {
    setState(() {
      _pendingExpenseFuture = RealizedExpenseLedgerService(
        AppDatabase.processScope,
      ).pendingSummary(packageId: widget.packageId, planId: widget.planId);
      final generation = ++_amendmentBannerGeneration;
      final amendmentBannerFuture = HousingProposalTransportService(
        AppDatabase.processScope,
      ).shouldShowPendingAmendmentHubBanner(widget.planId);
      _pendingAmendmentFuture = amendmentBannerFuture;
      _hubGatesFuture = _loadHubGates();
      unawaited(
        amendmentBannerFuture.then((show) {
          if (!mounted || generation != _amendmentBannerGeneration) return;
          setState(() => _hubShowsPendingAmendment = show);
        }),
      );
    });
  }

  Future<HousingParticipationHubGates> _loadHubGates() async {
    final prefs = widget.prefs ?? await AppPreferences.load();
    final lang = prefs.languageCode ?? 'en';
    final l10n = lookupAppLocalizations(Locale(lang));
    final dateFmt = effectiveDateFormat(prefs);
    return HousingParticipationHubGates.compute(
      db: AppDatabase.processScope,
      planId: widget.planId,
      selfParticipantId: selfParticipantIdForPlan(widget.planId),
      ejectionCandidateSubtitle: l10n.housingParticipationChangeEjectionHubSubtitle,
      bannerTextBuilder:
          ({
            required String initiatorName,
            required String? targetName,
            required DateTime? departureDate,
          }) {
            final pending = targetName;
            if (departureDate != null) {
              return l10n.housingParticipationChangeBannerWithdrawal(
                formatPreferenceDate(departureDate.toLocal(), dateFmt),
              );
            }
            if (pending != null && pending.isNotEmpty) {
              return l10n.housingParticipationChangeBannerEjection(
                initiatorName,
                pending,
              );
            }
            return l10n.housingParticipationChangeBannerTermination(
              initiatorName,
            );
          },
    );
  }

  Future<void> _openParticipationChangeDetail(
    BuildContext context,
    String changeId,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => HousingParticipationChangeDetailScreen(
              changeId: changeId,
              planId: widget.planId,
              packageId: widget.packageId,
              prefs: widget.prefs,
            ),
      ),
    );
    if (mounted) _reload();
  }

  /// Resolves pending amendment at tap time (not from a cached [FutureBuilder]).
  Future<void> _openMajorChange(BuildContext context) async {
    final prefs = widget.prefs ?? await AppPreferences.load();
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => HousingAgreementRenewalScreen(
              planId: widget.planId,
              packageId: widget.packageId,
              prefs: prefs,
            ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _onAmendmentHubTap(BuildContext context) async {
    final db = AppDatabase.processScope;
    final transport = HousingProposalTransportService(db);
    final prefs = widget.prefs ?? await AppPreferences.load();
    final hasPending =
        await transport.hasPendingAmendmentForUi(widget.planId);
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

  Future<void> _openAmendmentJournal(BuildContext context) async {
    final prefs = widget.prefs ?? await AppPreferences.load();
    if (!context.mounted) return;
    await openHousingAmendmentJournal(
      context,
      planId: widget.planId,
      prefs: prefs,
    );
    if (mounted) _reload();
  }

  Future<_HubHeader?> _loadHeader() async {
    final db = AppDatabase.processScope;
    final plan = await (db.select(
      db.plans,
    )..where((t) => t.id.equals(widget.planId))).getSingleOrNull();
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (plan == null || agreement == null) return null;
    final prefs = widget.prefs ?? await AppPreferences.load();
    final lang = prefs.languageCode ?? 'en';
    final l10n = lookupAppLocalizations(Locale(lang));
    final dateFmt = effectiveDateFormat(prefs);
    final selfId = selfParticipantIdForPlan(widget.planId);
    final titleParts = await HousingParticipationMembershipService(
      db,
    ).hubTitleParts(
      planId: widget.planId,
      selfParticipantId: selfId,
      activeHubTitleL10n: l10n.housingActiveHubTitle,
      pastHubTitleL10n: l10n.housingPastHubTitle,
      formatDate: (d) => formatPreferenceDate(d, dateFmt),
    );
    return _HubHeader(
      titlePrefix: titleParts.titlePrefix,
      periodRange: titleParts.periodRange,
      currency: plan.currency.trim().isEmpty ? prefs.currency : plan.currency,
    );
  }

  Future<void> _openPendingAmendmentFromNotificationIfAny() async {
    if (_openingPendingAmendment) return;
    final planId = HousingNavigationIntent.takePendingOpenAmendmentPlanId();
    if (planId == null || planId != widget.planId || !mounted) return;
    _openingPendingAmendment = true;
    try {
      final db = AppDatabase.processScope;
      final prefs = widget.prefs ?? await AppPreferences.load();
      final transport = HousingProposalTransportService(db);
      if (!await transport.hasPendingAmendmentForUi(widget.planId)) {
        return;
      }
      if (!mounted) return;
      await openHousingPendingProposalOrAmendment(
        context,
        db: db,
        planId: widget.planId,
        prefs: prefs,
        isAmendment: true,
      );
    } finally {
      _openingPendingAmendment = false;
      if (mounted) _reload();
    }
  }

  Future<void> _openSettledAmendmentFromNotificationIfAny() async {
    if (_openingSettledAmendment) return;
    final pending = HousingNavigationIntent.takePendingOpenSettledAmendment();
    if (pending == null || pending.planId != widget.planId || !mounted) return;
    _openingSettledAmendment = true;
    try {
      final db = AppDatabase.processScope;
      final prefs = widget.prefs ?? await AppPreferences.load();
      if (!mounted) return;
      await openHousingSettledAmendmentDetail(
        context,
        db: db,
        planId: widget.planId,
        prefs: prefs,
        revisionId: pending.revisionId,
      );
    } finally {
      _openingSettledAmendment = false;
      if (mounted) _reload();
    }
  }

  void _openPendingReviewIfAny() {
    if (_openingPendingReview) return;
    final expenseId = HousingNavigationIntent.takePendingReview();
    if (expenseId == null || !mounted) return;
    _openingPendingReview = true;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HousingRealizedExpenseReviewScreen(
              expenseId: expenseId,
              planId: widget.planId,
              packageId: widget.packageId,
              prefs: widget.prefs,
            ),
          ),
        )
        .then((_) {
          _openingPendingReview = false;
          if (mounted) _reload();
        })
        .catchError((_) {
          _openingPendingReview = false;
        });
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingActiveHubPlaceholderScreen(title: title),
      ),
    );
  }

  Future<void> _openReviewList(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingRealizedExpenseReviewListScreen(
          planId: widget.planId,
          packageId: widget.packageId,
          prefs: widget.prefs,
        ),
      ),
    );
    if (mounted) _reload();
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
            builder:
                (_) => HousingAgreementRenewalScreen(
                  planId: widget.planId,
                  packageId: widget.packageId,
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

  void _handleHubBack(BuildContext context) => exitHousingModule(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleHubBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleHubBack(context)),
          title: FutureBuilder<_HubHeader?>(
            future: _headerFuture,
            builder: (context, snap) {
              final header = snap.data;
              final title = header == null
                  ? l10n.housingActiveHubTitle
                  : '${header.titlePrefix}: ${header.periodRange}';
              return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
            },
          ),
        ),
        body: FutureBuilder<_HubHeader?>(
          future: _headerFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done &&
                _cachedHeader == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final header = snap.data ?? _cachedHeader;
            return FutureBuilder<RealizedExpensePendingSummary>(
              future: _pendingExpenseFuture,
              builder: (context, pendingSnap) {
                final pending =
                    pendingSnap.data ??
                    const RealizedExpensePendingSummary(
                      waitingForYouCount: 0,
                      waitingForOthersCount: 0,
                    );
                return FutureBuilder<bool>(
                  future: _pendingAmendmentFuture,
                  builder: (context, amendmentSnap) {
                    final hasPendingAmendment =
                        amendmentSnap.connectionState == ConnectionState.done
                            ? amendmentSnap.data == true
                            : _hubShowsPendingAmendment;
                    return FutureBuilder<HousingParticipationHubGates>(
                      future: _hubGatesFuture,
                      builder: (context, gatesSnap) {
                        final gates =
                            gatesSnap.data ??
                            const HousingParticipationHubGates(
                              showParticipationBanner: false,
                              enterExpenseEnabled: true,
                              requestAmendmentEnabled: true,
                              majorChangeEnabled: true,
                              isPastAgreementForSelf: false,
                              pendingChangeId: null,
                              isEjectionCandidate: false,
                            );
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (hasPendingAmendment)
                              Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiaryContainer,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.edit_notifications_outlined,
                                  ),
                                  title: Text(
                                    l10n.housingActiveHubPendingAmendment,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _onAmendmentHubTap(context),
                                ),
                              ),
                            if (gates.showParticipationBanner &&
                                gates.participationBannerText != null)
                              HousingParticipationChangeBanner(
                                text: gates.participationBannerText!,
                                onTap:
                                    gates.pendingChangeId == null
                                        ? null
                                        : () => _openParticipationChangeDetail(
                                          context,
                                          gates.pendingChangeId!,
                                        ),
                              ),
                            if (pending.totalPendingCount > 0)
                              Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  leading: const Icon(Icons.pending_actions),
                                  title: Text(
                                    l10n.housingActiveHubReviewPending(
                                      pending.totalPendingCount,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openReviewList(context),
                                ),
                              ),
                            _HubTile(
                              icon: Icons.description_outlined,
                              label: l10n.housingActiveHubViewPlan,
                              onTap: () async {
                                final prefs =
                                    widget.prefs ?? await AppPreferences.load();
                                if (!context.mounted) return;
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => HousingActivePlanReadOnlyScreen(
                                          planId: widget.planId,
                                          prefs: prefs,
                                        ),
                                  ),
                                );
                              },
                            ),
                            const _HubSectionDivider(),
                            _HubTile(
                              icon: Icons.add_card_outlined,
                              label: l10n.housingActiveHubEnterExpense,
                              enabled: gates.enterExpenseEnabled,
                              onTap: () => _openEnterExpense(context),
                            ),
                            const _HubSectionDivider(),
                            _HubTile(
                              icon: Icons.calendar_month_outlined,
                              label: l10n.housingActiveHubMonthlyExpenses,
                              onTap: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => HousingMonthlyExpensesScreen(
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
                                    builder:
                                        (_) => HousingBalancesScreen(
                                          planId: widget.planId,
                                          currency: header.currency,
                                        ),
                                  ),
                                );
                              },
                            ),
                            const _HubSectionDivider(),
                            _HubTile(
                              icon: Icons.edit_note_outlined,
                              label:
                                  hasPendingAmendment
                                      ? l10n.housingActiveHubViewPendingAmendment
                                      : l10n.housingActiveHubRequestAmendment,
                              enabled: gates.requestAmendmentEnabled,
                              onTap: () => _onAmendmentHubTap(context),
                            ),
                            _HubTile(
                              icon: Icons.groups_outlined,
                              label: l10n.housingAmendmentRosterChangeTitle,
                              enabled:
                                  HousingAmendmentUiGates.rosterChangeEnabled &&
                                  gates.majorChangeEnabled,
                              subtitle: gates.majorChangeSubtitle,
                              subtitleColor: Colors.red.shade700,
                              onTap: () => _openMajorChange(context),
                            ),
                            _HubTile(
                              icon: Icons.history,
                              label: l10n.housingAmendmentJournalTitle,
                              onTap: () => _openAmendmentJournal(context),
                            ),
                            const _HubSectionDivider(),
                            _HubTile(
                              icon: Icons.import_export_outlined,
                              label: l10n.housingActiveHubExportImport,
                              onTap:
                                  () => _openPlaceholder(
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
            );
          },
        ),
      ),
    );
  }
}

class _HubHeader {
  const _HubHeader({
    required this.titlePrefix,
    required this.periodRange,
    required this.currency,
  });

  final String titlePrefix;
  final String periodRange;
  final String currency;
}

class _HubSectionDivider extends StatelessWidget {
  const _HubSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle:
            subtitle == null
                ? null
                : Text(
                  subtitle!,
                  style: TextStyle(color: subtitleColor),
                ),
        trailing: const Icon(Icons.chevron_right),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
