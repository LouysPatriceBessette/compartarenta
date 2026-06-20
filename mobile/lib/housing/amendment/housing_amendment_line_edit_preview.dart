import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../prefs/regional_unit_choices.dart';
import '../../util/display_date.dart';
import '../expense_form/expense_plan_line_view_data.dart';
import '../expense_form/housing_expense_line_presentation_card.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_amendment_expense_preview.dart';
import 'housing_amendment_line_edit_highlight.dart';
import 'housing_amendment_screen_padding.dart';
import 'housing_amendment_settlement.dart';
import 'housing_amendment_summary.dart';
import 'housing_amendment_type.dart';
import 'housing_line_add_amendment_pending.dart';
import 'housing_line_edit_amendment_pending.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

class LineEditAmendmentPreviewPair {
  const LineEditAmendmentPreviewPair({
    required this.baseline,
    required this.proposed,
  });

  final ExpensePlanLineViewData baseline;
  final ExpensePlanLineViewData proposed;
}

Future<LineEditAmendmentPreviewPair?> loadLineEditAmendmentPreviewPair({
  required AppDatabase db,
  required String planId,
  required HousingAmendmentSummary summary,
  required AppLocalizations l10n,
  required String dateFormat,
  required String defaultCurrency,
}) async {
  if (summary.type != HousingAmendmentType.lineEdit) return null;
  final lineId = summary.targetLineId;
  if (lineId == null || lineId.isEmpty) return null;

  final roster = await participantsForPlan(db, planId);
  final participantIds = [for (final p in roster) p.id];
  final participantNames = [for (final p in roster) p.displayName];

  Map<String, dynamic>? baselineLineMap;
  List<Map<String, dynamic>> baselineRatios = const [];
  Map<String, dynamic>? proposedLineMap;
  List<Map<String, dynamic>> proposedRatios = const [];
  Map<String, dynamic>? baselinePayload;
  Map<String, dynamic>? proposedPayload;

  if (summary.revisionId == 'preview') {
    baselinePayload = await activeRevisionPayload(db, planId);
    if (baselinePayload == null) return null;
    baselineLineMap = lineMapInPayload(baselinePayload, planId, lineId);
    baselineRatios = ratioMapsForLineInPayload(baselinePayload, planId, lineId);

    final pending = HousingLineEditAmendmentPendingStore.get(planId);
    if (pending == null) return null;
    proposedLineMap = pending.lineMap;
    proposedRatios = pending.ratioMaps;
  } else {
    proposedPayload = await _revisionPayloadForAmendment(db, summary.revisionId);
    if (proposedPayload == null) return null;

    final transport = HousingProposalTransportService(db);
    final activeRevisionId =
        await transport.resolveActiveRevisionIdForPlan(planId);
    final baselineId = amendmentBaselineRevisionId(
      revisionPayload: proposedPayload,
      revisionId: summary.revisionId,
      packageActiveRevisionId: activeRevisionId,
      isArchived: (proposedPayload['lifecycleState'] as String?) == 'archived',
    );
    baselinePayload = baselineId == null
        ? proposedPayload
        : await _revisionPayloadForAmendment(db, baselineId);
    if (baselinePayload == null) return null;

    baselineLineMap = lineMapInPayload(baselinePayload, planId, lineId);
    proposedLineMap = lineMapInPayload(proposedPayload, planId, lineId);
    baselineRatios = ratioMapsForLineInPayload(baselinePayload, planId, lineId);
    proposedRatios = ratioMapsForLineInPayload(proposedPayload, planId, lineId);
  }

  if (baselineLineMap == null || proposedLineMap == null) return null;

  final baselineView = await buildExpenseLineViewDataFromPayloadLine(
    db: db,
    planId: planId,
    lineMap: baselineLineMap,
    ratioMaps: baselineRatios,
    participantIds: participantIds,
    participantNames: participantNames,
    l10n: l10n,
    dateFormat: dateFormat,
    defaultCurrency: defaultCurrency,
    revisionPayload: baselinePayload,
  );
  final proposedView = await buildExpenseLineViewDataFromPayloadLine(
    db: db,
    planId: planId,
    lineMap: proposedLineMap,
    ratioMaps: proposedRatios,
    participantIds: participantIds,
    participantNames: participantNames,
    l10n: l10n,
    dateFormat: dateFormat,
    defaultCurrency: defaultCurrency,
    revisionPayload: proposedPayload ?? baselinePayload,
  );
  if (baselineView == null || proposedView == null) return null;

  return LineEditAmendmentPreviewPair(
    baseline: baselineView,
    proposed: proposedView,
  );
}

Future<Map<String, dynamic>?> _revisionPayloadForAmendment(
  AppDatabase db,
  String revisionId,
) async {
  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(revisionId)))
      .getSingleOrNull();
  if (rev == null) return null;
  try {
    return jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Summary cards (title · amount) for line-edit amendments; opens detail on tap.
class HousingAmendmentLineEditComparisonSection extends StatelessWidget {
  const HousingAmendmentLineEditComparisonSection({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    required this.summary,
    required this.currentLabel,
    required this.proposedLabel,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final HousingAmendmentSummary summary;
  final String currentLabel;
  final String proposedLabel;

  void _openDetail(
    BuildContext context,
    LineEditAmendmentPreviewPair pair, {
    required bool showProposed,
  }) {
    navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentLineEditDetailScreen(
          planId: planId,
          prefs: prefs,
          summary: summary,
          pair: pair,
          showProposed: showProposed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(prefs);
    return FutureBuilder<LineEditAmendmentPreviewPair?>(
      future: () async {
        final row = await (db.select(db.plans)
              ..where((t) => t.id.equals(planId)))
            .getSingleOrNull();
        final currency = row?.currency.trim().isNotEmpty == true
            ? row!.currency.trim()
            : kDefaultCurrencyCode;
        return loadLineEditAmendmentPreviewPair(
          db: db,
          planId: planId,
          summary: summary,
          l10n: l10n,
          dateFormat: dateFmt,
          defaultCurrency: currency,
        );
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final pair = snapshot.data;
        if (pair == null) {
          return _LineEditTextComparisonFallback(
            currentLabel: currentLabel,
            currentValue: summary.currentText,
            proposedLabel: proposedLabel,
            proposedValue: summary.proposedText,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LineEditSummaryCard(
              label: currentLabel,
              value: summary.currentText,
              onTap: () => _openDetail(context, pair, showProposed: false),
            ),
            const SizedBox(height: 12),
            _LineEditSummaryCard(
              label: proposedLabel,
              value: summary.proposedText,
              emphasized: true,
              onTap: () => _openDetail(context, pair, showProposed: true),
            ),
          ],
        );
      },
    );
  }
}

class HousingAmendmentLineEditDetailScreen extends StatelessWidget {
  const HousingAmendmentLineEditDetailScreen({
    super.key,
    required this.planId,
    required this.prefs,
    required this.summary,
    required this.pair,
    required this.showProposed,
  });

  final String planId;
  final AppPreferences prefs;
  final HousingAmendmentSummary summary;
  final LineEditAmendmentPreviewPair pair;
  final bool showProposed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = showProposed
        ? l10n.housingAmendmentDetailProposed
        : l10n.housingAmendmentDetailCurrent;
    final view = showProposed ? pair.proposed : pair.baseline;
    final highlights = diffLineEditHighlightFields(
      baseline: pair.baseline,
      proposed: pair.proposed,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: housingAmendmentScreenPadding(context),
        children: [
          HousingExpenseLinePresentationCard(
            viewData: view,
            highlightFields: highlights,
          ),
        ],
      ),
    );
  }
}

class _LineEditTextComparisonFallback extends StatelessWidget {
  const _LineEditTextComparisonFallback({
    required this.currentLabel,
    required this.currentValue,
    required this.proposedLabel,
    required this.proposedValue,
  });

  final String currentLabel;
  final String currentValue;
  final String proposedLabel;
  final String proposedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LineEditSummaryCard(label: currentLabel, value: currentValue),
        const SizedBox(height: 12),
        _LineEditSummaryCard(
          label: proposedLabel,
          value: proposedValue,
          emphasized: true,
        ),
      ],
    );
  }
}

class _LineEditSummaryCard extends StatelessWidget {
  const _LineEditSummaryCard({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: emphasized
                      ? theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    return Card(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content,
            ),
    );
  }
}
