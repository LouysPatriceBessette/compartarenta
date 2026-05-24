import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/amendment/housing_amendment_proposal_flow.dart';
import '../../housing/amendment/housing_amendment_summary.dart'
    show removeLineFromRevisionPayload;
import '../../housing/amendment/housing_amendment_type.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/expense_form/expense_plan_line_form_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_agreement_renewal_screen.dart';
import 'housing_plan_screen.dart';

class _AmendmentOption {
  const _AmendmentOption({
    this.type,
    required this.title,
    required this.subtitle,
    this.isRosterRedirect = false,
  });

  final HousingAmendmentType? type;
  final String title;
  final String subtitle;
  final bool isRosterRedirect;
}

/// Picker for a single in-force plan modification (pass 4).
class HousingAmendmentRequestScreen extends StatelessWidget {
  const HousingAmendmentRequestScreen({
    super.key,
    required this.planId,
    required this.prefs,
  });

  final String planId;
  final AppPreferences prefs;

  List<_AmendmentOption> _options(AppLocalizations l10n) => [
        _AmendmentOption(
          type: HousingAmendmentType.lineAmount,
          title: l10n.housingAmendmentTypeLineAmount,
          subtitle: l10n.housingAmendmentTypeLineAmountHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.lineRecurrence,
          title: l10n.housingAmendmentTypeLineRecurrence,
          subtitle: l10n.housingAmendmentTypeLineRecurrenceHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.linePayer,
          title: l10n.housingAmendmentTypeLinePayer,
          subtitle: l10n.housingAmendmentTypeLinePayerHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.lineAdd,
          title: l10n.housingAmendmentTypeLineAdd,
          subtitle: l10n.housingAmendmentTypeLineAddHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.lineRemove,
          title: l10n.housingAmendmentTypeLineRemove,
          subtitle: l10n.housingAmendmentTypeLineRemoveHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.agreementEnd,
          title: l10n.housingAmendmentTypeAgreementEnd,
          subtitle: l10n.housingAmendmentTypeAgreementEndHint,
        ),
        _AmendmentOption(
          type: HousingAmendmentType.ruleChange,
          title: l10n.housingAmendmentTypeRuleChange,
          subtitle: l10n.housingAmendmentTypeRuleChangeHint,
        ),
        _AmendmentOption(
          isRosterRedirect: true,
          title: l10n.housingAmendmentRosterChangeTitle,
          subtitle: l10n.housingAmendmentRosterChangeHint,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _options(l10n);
    final db = AppDatabase.processScope;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentRequestTitle)),
      body: FutureBuilder<bool>(
        future: HousingProposalTransportService(db).hasOpenPendingAmendment(planId),
        builder: (context, pendingSnap) {
          final hasPending = pendingSnap.data ?? false;
          return ListView(
            padding: const EdgeInsets.all(16),
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
                      await openHousingPendingProposalOrAmendment(
                        context,
                        db: db,
                        planId: planId,
                        prefs: prefs,
                        isAmendment: true,
                      );
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
              ] else ...[
                Text(
                  l10n.housingAmendmentRequestIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final opt in options)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(opt.title),
                      subtitle: Text(opt.subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _onOptionTap(context, opt),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _onOptionTap(BuildContext context, _AmendmentOption opt) async {
    final db = AppDatabase.processScope;
    if (await HousingProposalTransportService(db).hasOpenPendingAmendment(planId)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).housingAmendmentPendingBlocks)),
      );
      return;
    }
    if (opt.isRosterRedirect) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => HousingAgreementRenewalScreen(
            planId: planId,
            prefs: prefs,
            rosterChangeOnly: true,
          ),
        ),
      );
      return;
    }
    final type = opt.type;
    if (type == null) return;

    if (type == HousingAmendmentType.agreementEnd) {
      await _amendAgreementEnd(context);
      return;
    }
    if (type == HousingAmendmentType.ruleChange) {
      await _amendRules(context);
      return;
    }
    if (type == HousingAmendmentType.lineAdd) {
      await _amendLineAdd(context);
      return;
    }
    if (type.requiresLinePicker) {
      await _amendExistingLine(context, type);
    }
  }

  Future<_LinePickerContext?> _lineContext() async {
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(planId);
    if (agreement == null) return null;
    final lines = await db.listPlanLines(planId);
    final participants = (await db.listParticipants())
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .toList(growable: false);
    final plan = await (db.select(db.plans)
          ..where((t) => t.id.equals(planId)))
        .getSingleOrNull();
    final currency = plan?.currency.trim().isEmpty ?? true
        ? prefs.currency
        : plan!.currency.trim();
    return _LinePickerContext(
      agreement: agreement,
      lines: lines,
      participantIds: participants.map((p) => p.id).toList(growable: false),
      participantNames:
          participants.map((p) => p.displayName).toList(growable: false),
      currency: currency,
      dateFormat: effectiveDateFormat(prefs),
    );
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

    final lineId = await showDialog<String>(
      context: context,
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
      final ok = await showDialog<bool>(
        context: context,
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
      await HousingAmendmentProposalFlow(AppDatabase.processScope).submitAmendment(
        context: context,
        planId: planId,
        prefs: prefs,
        amendmentType: type,
        targetLineId: lineId,
        patchRevisionPayload: (payload) {
          removeLineFromRevisionPayload(payload, lineId, planId);
        },
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExpensePlanLineFormScreen(
          planId: planId,
          participantIds: ctx.participantIds,
          participantNames: ctx.participantNames,
          periodStart: ctx.agreement.periodStart,
          periodEnd: ctx.agreement.periodEnd,
          defaultCurrency: ctx.currency,
          dateFormat: ctx.dateFormat,
          prefs: prefs,
          existingLineId: lineId,
        ),
      ),
    );
    if (!context.mounted) return;
    await HousingAmendmentProposalFlow(AppDatabase.processScope).submitAmendment(
      context: context,
      planId: planId,
      prefs: prefs,
      amendmentType: type,
      targetLineId: lineId,
    );
  }

  Future<void> _amendLineAdd(BuildContext context) async {
    final ctx = await _lineContext();
    if (ctx == null || !context.mounted) return;
    final sortOrder = ctx.lines.isEmpty
        ? 0
        : ctx.lines.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExpensePlanLineFormScreen(
          planId: planId,
          participantIds: ctx.participantIds,
          participantNames: ctx.participantNames,
          periodStart: ctx.agreement.periodStart,
          periodEnd: ctx.agreement.periodEnd,
          defaultCurrency: ctx.currency,
          dateFormat: ctx.dateFormat,
          prefs: prefs,
          initialSortOrder: sortOrder,
        ),
      ),
    );
    if (!context.mounted) return;
    await HousingAmendmentProposalFlow(AppDatabase.processScope).submitAmendment(
      context: context,
      planId: planId,
      prefs: prefs,
      amendmentType: HousingAmendmentType.lineAdd,
    );
  }

  Future<void> _amendAgreementEnd(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(planId);
    if (agreement == null || !context.mounted) return;
    final dateFmt = effectiveDateFormat(prefs);
    DateTime selected = agreement.periodEnd;

    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: agreement.periodStart,
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;
    final pickedEnd = picked;

    final sent = await HousingAmendmentProposalFlow(db).submitAmendment(
      context: context,
      planId: planId,
      prefs: prefs,
      amendmentType: HousingAmendmentType.agreementEnd,
      patchRevisionPayload: (payload) {
        final agr = payload['agreement'];
        if (agr is Map) {
          agr['periodEnd'] = pickedEnd.toIso8601String();
        }
      },
    );
    if (!context.mounted || !sent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.housingAmendmentEndDateSet(formatPreferenceDate(pickedEnd, dateFmt)),
        ),
      ),
    );
  }

  Future<void> _amendRules(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingPlanScreen(
          prefs: prefs,
          planId: planId,
          openEditorInitially: true,
          amendmentRulesOnly: true,
        ),
      ),
    );
    if (!context.mounted) return;
    await HousingAmendmentProposalFlow(AppDatabase.processScope).submitAmendment(
      context: context,
      planId: planId,
      prefs: prefs,
      amendmentType: HousingAmendmentType.ruleChange,
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
