import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_expense_preview.dart';
import '../../housing/amendment/housing_amendment_proposal_flow.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../housing/amendment/housing_amendment_summary.dart';
import '../../housing/amendment/housing_amendment_type.dart';
import '../../housing/amendment/housing_rules_amendment_pending.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_amendment_detail_screen.dart';

/// Preview of a plan change before sending to the group (deadline asked on submit).
class HousingAmendmentSubmitPreviewScreen extends StatefulWidget {
  const HousingAmendmentSubmitPreviewScreen({
    super.key,
    required this.planId,
    required this.prefs,
    required this.type,
    this.targetLineId,
    this.proposedPeriodEnd,
    this.patchRevisionPayload,
  });

  final String planId;
  final AppPreferences prefs;
  final HousingAmendmentType type;
  final String? targetLineId;
  final DateTime? proposedPeriodEnd;
  final void Function(Map<String, dynamic> payload)? patchRevisionPayload;

  @override
  State<HousingAmendmentSubmitPreviewScreen> createState() =>
      _HousingAmendmentSubmitPreviewScreenState();
}

class _HousingAmendmentSubmitPreviewScreenState
    extends State<HousingAmendmentSubmitPreviewScreen> {
  HousingAmendmentSummary? _summary;
  bool _loading = true;
  bool _submitting = false;
  bool _submitEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  AppLocalizations _lookupL10n() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return switch (code) {
      'fr' => lookupAppLocalizations(const Locale('fr')),
      'es' => lookupAppLocalizations(const Locale('es')),
      _ => lookupAppLocalizations(const Locale('en')),
    };
  }

  Future<void> _load() async {
    try {
      final l10n = mounted ? AppLocalizations.of(context) : _lookupL10n();
      final dateFmt = effectiveDateFormat(widget.prefs);
      final summary = await buildAmendmentPreviewSummary(
        db: AppDatabase.processScope,
        planId: widget.planId,
        type: widget.type,
        targetLineId: widget.targetLineId,
        proposedPeriodEnd: widget.proposedPeriodEnd,
        l10n: l10n,
        dateFormat: dateFmt,
      );
      if (!mounted) return;
      final submitEnabled = summary != null &&
          await _amendmentAllowsSubmit(
            db: AppDatabase.processScope,
            summary: summary,
            l10n: l10n,
          );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _submitEnabled = submitEnabled;
      });
    } catch (e, st) {
      debugPrint('housing amendment preview load failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _amendmentAllowsSubmit({
    required AppDatabase db,
    required HousingAmendmentSummary summary,
    required AppLocalizations l10n,
  }) async {
    if (summary.type == HousingAmendmentType.ruleChange) {
      return amendmentRulesHasMeaningfulChange(
        db: db,
        planId: widget.planId,
        summary: summary,
        l10n: l10n,
      );
    }
    return amendmentSummaryHasMeaningfulChange(summary);
  }

  Future<void> _submit() async {
    if (_submitting || _summary == null) return;
    final l10n = AppLocalizations.of(context);
    final db = AppDatabase.processScope;
    final meaningful = _summary!.type == HousingAmendmentType.ruleChange
        ? await amendmentRulesHasMeaningfulChange(
            db: db,
            planId: widget.planId,
            summary: _summary!,
            l10n: l10n,
          )
        : amendmentSummaryHasMeaningfulChange(_summary!);
    if (!mounted) return;
    if (!meaningful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingAmendmentNoMeaningfulChange)),
      );
      return;
    }
    setState(() => _submitting = true);
    final sent = await HousingAmendmentProposalFlow(db).submitAmendment(
      context: context,
      planId: widget.planId,
      prefs: widget.prefs,
      amendmentType: widget.type,
      targetLineId: widget.targetLineId,
      patchRevisionPayload: widget.patchRevisionPayload,
      proposedPeriodEnd: widget.proposedPeriodEnd,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!sent) return;
    if (widget.type == HousingAmendmentType.ruleChange) {
      HousingRulesAmendmentPendingStore.clear(widget.planId);
    }
    final pendingId = await HousingProposalTransportService(db)
        .pendingRevisionIdForPlan(widget.planId);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentDetailScreen(
          db: db,
          planId: widget.planId,
          prefs: widget.prefs,
          revisionId: pendingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentPreviewTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? Center(child: Text(l10n.housingRealizedExpenseLoadFailed))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: housingAmendmentScreenPadding(context),
                        children: [
                          Text(
                            l10n.housingAmendmentPreviewIntro(
                              _summary!.subjectLabel(l10n),
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          HousingAmendmentComparisonSection(
                            db: AppDatabase.processScope,
                            planId: widget.planId,
                            prefs: widget.prefs,
                            summary: _summary!,
                            currentLabel: l10n.housingAmendmentDetailCurrent,
                            proposedLabel: l10n.housingAmendmentDetailProposed,
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: housingAmendmentScreenPadding(context)
                            .copyWith(top: 8),
                        child: FilledButton(
                          onPressed:
                              _submitting || !_submitEnabled ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.housingAmendmentSubmitToGroup),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
