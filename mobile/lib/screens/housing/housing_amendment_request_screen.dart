import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/app_dialog.dart';
import '../../widgets/balanced_text.dart';
import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/agreement_rules_diff.dart';
import '../../housing/amendment/housing_rules_amendment_pending.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../housing/amendment/housing_amendment_summary.dart'
    show removeLineFromRevisionPayload;
import '../../housing/amendment/housing_amendment_type.dart';
import '../../housing/amendment/housing_line_add_amendment_pending.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../housing/expense_form/expense_plan_line_form_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_amendment_submit_preview_screen.dart';
import 'housing_plan_screen.dart';

sealed class _AmendmentMenuEntry {
  const _AmendmentMenuEntry();
}

class _AmendmentMenuSeparator extends _AmendmentMenuEntry {
  const _AmendmentMenuSeparator();
}

class _AmendmentMenuOption extends _AmendmentMenuEntry {
  const _AmendmentMenuOption({
    this.type,
    required this.title,
  });

  final HousingAmendmentType? type;
  final String title;
}

/// Picker for a single in-force plan modification (pass 4).
class HousingAmendmentRequestScreen extends StatefulWidget {
  const HousingAmendmentRequestScreen({
    super.key,
    required this.planId,
    required this.prefs,
  });

  final String planId;
  final AppPreferences prefs;

  @override
  State<HousingAmendmentRequestScreen> createState() =>
      _HousingAmendmentRequestScreenState();
}

class _HousingAmendmentRequestScreenState extends State<HousingAmendmentRequestScreen>
    with WidgetsBindingObserver {
  bool _redirectedToPending = false;
  bool _openingPendingFromBanner = false;
  Future<bool>? _pendingFuture;
  int _pendingGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPendingBanner();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
        _onSteadyInboxTick,
      );
      unawaited(_openPendingAmendmentIfAwaitingLocal());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshPendingBanner();
    }
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    _refreshPendingBanner();
  }

  void _refreshPendingBanner() {
    final generation = ++_pendingGeneration;
    final future = HousingProposalTransportService(AppDatabase.processScope)
        .hasPendingAmendmentForUi(widget.planId);
    setState(() {
      _pendingFuture = future;
    });
    unawaited(
      future.then((_) {
        if (!mounted || generation != _pendingGeneration) return;
        setState(() {});
      }),
    );
  }

  Future<void> _openPendingAmendmentIfAwaitingLocal() async {
    if (_redirectedToPending || !mounted) return;
    final transport = HousingProposalTransportService(AppDatabase.processScope);
    if (!await transport.hasOpenPendingAmendmentAwaitingLocalResponse(
      widget.planId,
    )) {
      return;
    }
    _redirectedToPending = true;
    if (!mounted) return;
    await openHousingPendingProposalOrAmendment(
      context,
      db: AppDatabase.processScope,
      planId: widget.planId,
      prefs: widget.prefs,
      isAmendment: true,
    );
  }

  List<_AmendmentMenuEntry> _menuEntries(AppLocalizations l10n) => [
        _AmendmentMenuOption(
          type: HousingAmendmentType.lineAdd,
          title: l10n.housingAmendmentTypeLineAdd,
        ),
        _AmendmentMenuOption(
          type: HousingAmendmentType.lineEdit,
          title: l10n.housingAmendmentTypeLineEdit,
        ),
        _AmendmentMenuOption(
          type: HousingAmendmentType.lineRemove,
          title: l10n.housingAmendmentTypeLineRemove,
        ),
        const _AmendmentMenuSeparator(),
        _AmendmentMenuOption(
          type: HousingAmendmentType.agreementEnd,
          title: l10n.housingAmendmentTypeAgreementEnd,
        ),
        _AmendmentMenuOption(
          type: HousingAmendmentType.ruleChange,
          title: l10n.housingAmendmentTypeRuleChange,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = _menuEntries(l10n);
    final db = AppDatabase.processScope;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentRequestTitle)),
      body: FutureBuilder<bool>(
        future: _pendingFuture,
        builder: (context, pendingSnap) {
          if (pendingSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasPending = pendingSnap.data ?? false;
          return ListView(
            padding: housingAmendmentScreenPadding(context),
            children: [
              if (hasPending) ...[
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.edit_notifications_outlined),
                    title: Text(l10n.housingActiveHubPendingAmendment),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (_openingPendingFromBanner) return;
                      _openingPendingFromBanner = true;
                      try {
                        final pendingId =
                            await HousingProposalTransportService(db)
                                .pendingRevisionIdForPlan(widget.planId);
                        if (!context.mounted || pendingId == null) return;
                        await openHousingPendingProposalOrAmendment(
                          context,
                          db: db,
                          planId: widget.planId,
                          prefs: widget.prefs,
                          revisionId: pendingId,
                          isAmendment: true,
                        );
                      } finally {
                        _openingPendingFromBanner = false;
                        if (mounted) _refreshPendingBanner();
                      }
                    },
                  ),
                ),
                Text(
                  l10n.housingAmendmentPendingBlocks,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 16),
              ] else
                for (final entry in entries)
                  switch (entry) {
                    _AmendmentMenuSeparator() => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                    final _AmendmentMenuOption opt => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: BalancedText(opt.title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onOptionTap(
                            context,
                            opt,
                            widget.planId,
                            widget.prefs,
                          ),
                        ),
                      ),
                  },
            ],
          );
        },
      ),
    );
  }

  Future<void> _onOptionTap(
    BuildContext context,
    _AmendmentMenuOption opt,
    String planId,
    AppPreferences prefs,
  ) async {
    final db = AppDatabase.processScope;
    if (await HousingProposalTransportService(db).hasPendingAmendmentForUi(
      planId,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).housingAmendmentPendingBlocks)),
      );
      return;
    }
    if (!context.mounted) return;

    final type = opt.type;
    if (type == null) return;

    if (type == HousingAmendmentType.agreementEnd) {
      await _amendAgreementEnd(context);
      return;
    }
    if (!context.mounted) return;
    if (type == HousingAmendmentType.ruleChange) {
      await _amendRules(context);
      return;
    }
    if (!context.mounted) return;
    if (type == HousingAmendmentType.lineAdd) {
      await _amendLineAdd(context);
      return;
    }
    if (!context.mounted) return;
    if (type.requiresLinePicker) {
      await _amendExistingLine(context, type);
    }
  }

  Future<_LinePickerContext?> _lineContext() async {
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (agreement == null) return null;
    await purgeNonInForcePlanLines(db, widget.planId);
    final lines = await listInForcePlanLines(db, widget.planId);
    final participants = sortParticipantsForPlan(
      widget.planId,
      await participantsForPlan(db, widget.planId),
    );
    final plan = await (db.select(db.plans)
          ..where((t) => t.id.equals(widget.planId)))
        .getSingleOrNull();
    final currency = plan?.currency.trim().isEmpty ?? true
        ? widget.prefs.currency
        : plan!.currency.trim();
    return _LinePickerContext(
      agreement: agreement,
      lines: lines,
      participantIds: participants.map((p) => p.id).toList(growable: false),
      participantNames:
          participants.map((p) => p.displayName).toList(growable: false),
      currency: currency,
      dateFormat: effectiveDateFormat(widget.prefs),
    );
  }

  Future<void> _openPreview(
    BuildContext context, {
    required HousingAmendmentType type,
    String? targetLineId,
    DateTime? proposedPeriodEnd,
    void Function(Map<String, dynamic> payload)? patchRevisionPayload,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentSubmitPreviewScreen(
          planId: widget.planId,
          prefs: widget.prefs,
          type: type,
          targetLineId: targetLineId,
          proposedPeriodEnd: proposedPeriodEnd,
          patchRevisionPayload: patchRevisionPayload,
        ),
      ),
    );
    if (!mounted) return;
    _refreshPendingBanner();
  }

  Future<void> _amendExistingLine(
    BuildContext context,
    HousingAmendmentType type,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ctx = await _lineContext();
    if (ctx == null || !context.mounted) return;
    if (ctx.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingRealizedExpenseNoPlanLines)),
      );
      return;
    }

    final lineId = await showAppDialog<String>(
      context: context,
      guardKey: 'housingAmendmentRequest.pickLine',
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.housingAmendmentPickLine),
        children: [
          for (final line in ctx.lines)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, line.id),
              child: Text(
                line.title.trim().isEmpty ? line.id : line.title.trim(),
              ),
            ),
        ],
      ),
    );
    if (lineId == null || !context.mounted) return;

    if (type == HousingAmendmentType.lineRemove) {
      final ok = await showAppDialog<bool>(
        context: context,
        guardKey: 'housingAmendmentRequest.removeLineConfirm',
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.housingAmendmentTypeLineRemove),
          content: Text(l10n.housingAmendmentLineRemoveConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.housingAmendmentLineRemoveConfirmAction),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      await _openPreview(
        context,
        type: type,
        targetLineId: lineId,
        patchRevisionPayload: (payload) {
          removeLineFromRevisionPayload(payload, lineId, widget.planId);
        },
      );
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ExpensePlanLineFormScreen(
          planId: widget.planId,
          participantIds: ctx.participantIds,
          participantNames: ctx.participantNames,
          periodStart: ctx.agreement.periodStart,
          periodEnd: ctx.agreement.periodEnd,
          defaultCurrency: ctx.currency,
          dateFormat: ctx.dateFormat,
          prefs: widget.prefs,
          existingLineId: lineId,
          amendmentSubmitToGroup: true,
        ),
      ),
    );
  }

  Future<void> _amendLineAdd(BuildContext context) async {
    final ctx = await _lineContext();
    if (ctx == null || !context.mounted) return;
    final sortOrder = ctx.lines.isEmpty
        ? 0
        : ctx.lines.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ExpensePlanLineFormScreen(
          planId: widget.planId,
          participantIds: ctx.participantIds,
          participantNames: ctx.participantNames,
          periodStart: ctx.agreement.periodStart,
          periodEnd: ctx.agreement.periodEnd,
          defaultCurrency: ctx.currency,
          dateFormat: ctx.dateFormat,
          prefs: widget.prefs,
          initialSortOrder: sortOrder,
          amendmentSubmitToGroup: true,
        ),
      ),
    );
  }

  Future<void> _amendAgreementEnd(BuildContext context) async {
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (agreement == null || !context.mounted) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstDate = agreement.periodStart.isAfter(todayDate)
        ? agreement.periodStart
        : todayDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: agreement.periodEnd.isBefore(firstDate)
          ? firstDate
          : agreement.periodEnd,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;

    await _openPreview(
      context,
      type: HousingAmendmentType.agreementEnd,
      proposedPeriodEnd: picked,
    );
  }

  Future<void> _amendRules(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HousingPlanScreen(
          prefs: widget.prefs,
          planId: widget.planId,
          openEditorInitially: true,
          amendmentRulesOnly: true,
          amendmentSubmitToGroup: true,
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    await _openPreview(
      context,
      type: HousingAmendmentType.ruleChange,
      patchRevisionPayload: (payload) {
        final l10n = AppLocalizations.of(context);
        HousingRulesAmendmentPendingStore.applyToPayload(
          widget.planId,
          payload,
          suggestionDefaults: agreementSuggestionDefaultsFromL10n(l10n),
        );
      },
    );
  }
}


class _LinePickerContext {
  const _LinePickerContext({
    required this.agreement,
    required this.lines,
    required this.participantIds,
    required this.participantNames,
    required this.currency,
    required this.dateFormat,
  });

  final Agreement agreement;
  final List<PlanLine> lines;
  final List<String> participantIds;
  final List<String> participantNames;
  final String currency;
  final String dateFormat;
}
