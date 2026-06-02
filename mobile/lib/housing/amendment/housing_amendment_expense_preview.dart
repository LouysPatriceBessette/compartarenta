import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../expense_form/expense_plan_line_view_data.dart';
import '../expense_form/housing_expense_line_presentation_card.dart';
import '../expense_form/plan_participant_dropdown_value.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../realized_expense/realized_expense_participants.dart';
import '../../screens/housing/housing_amendment_rules_change_ui.dart';
import 'agreement_rules_amendment_loader.dart';
import 'housing_amendment_settlement.dart';
import 'housing_amendment_summary.dart';
import 'housing_amendment_type.dart';
import 'housing_line_add_amendment_pending.dart';
import 'housing_amendment_line_edit_preview.dart';

bool housingAmendmentUsesExpenseLinePreview(HousingAmendmentType type) =>
    type == HousingAmendmentType.lineAdd;

bool _sameParticipantRef(String a, String b) {
  if (a == b) return true;
  if (a.endsWith(':$b') || b.endsWith(':$a')) return true;
  final tailA = a.contains(':') ? a.split(':').last : a;
  final tailB = b.contains(':') ? b.split(':').last : b;
  return tailA == tailB;
}

bool _lineIdMatches(String targetLineId, String planId, String payloadLineId) {
  if (payloadLineId.isEmpty) return false;
  if (payloadLineId == targetLineId) return true;
  if (payloadLineId.endsWith(':$targetLineId')) return true;
  if (targetLineId.endsWith(':$payloadLineId')) return true;
  final resolved = payloadLineId.contains(':')
      ? payloadLineId
      : '$planId:$payloadLineId';
  return resolved == targetLineId;
}

List<Map<String, dynamic>> _payloadLines(Map<String, dynamic> payload) {
  final plan = payload['plan'];
  if (plan is! Map) return const [];
  final lines = plan['lines'];
  if (lines is! List) return const [];
  return [
    for (final e in lines)
      if (e is Map) e.cast<String, dynamic>(),
  ];
}

List<Map<String, dynamic>> _payloadRatios(Map<String, dynamic> payload) {
  final plan = payload['plan'];
  if (plan is! Map) return const [];
  final ratios = plan['ratios'];
  if (ratios is! List) return const [];
  return [
    for (final e in ratios)
      if (e is Map) e.cast<String, dynamic>(),
  ];
}

Map<String, dynamic>? _lineById(
  List<Map<String, dynamic>> lines,
  String? lineId,
  String planId,
) {
  if (lineId == null || lineId.isEmpty) return null;
  for (final line in lines) {
    final id = line['id']?.toString() ?? '';
    if (_lineIdMatches(lineId, planId, id)) return line;
  }
  return null;
}

Map<String, dynamic>? _lineAddedRelativeToBaseline(
  List<Map<String, dynamic>> baselineLines,
  List<Map<String, dynamic>> proposedLines,
  String planId,
) {
  final baseIds = <String>{
    for (final line in baselineLines) line['id']?.toString() ?? '',
  };
  for (final line in proposedLines) {
    final id = line['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    if (!baseIds.contains(id) &&
        !baseIds.any((b) => _lineIdMatches(id, planId, b))) {
      return line;
    }
  }
  return proposedLines.isEmpty ? null : proposedLines.last;
}

Map<String, int> _splitWeightsForPayloadLine(
  String lineId,
  String planId,
  List<Map<String, dynamic>> ratioMaps,
) {
  final weights = <String, int>{};
  for (final r in ratioMaps) {
    final rid = r['lineId']?.toString() ?? '';
    if (!_lineIdMatches(lineId, planId, rid)) continue;
    final pid = r['participantId']?.toString() ?? '';
    final weight = r['weight'];
    if (pid.isNotEmpty && weight is num) {
      weights[pid] = weight.toInt();
    }
  }
  return weights;
}

/// Maps a payment-responsible id from a received revision to this device's roster.
String? paymentResponsibleIdForLocalPlan({
  required String? sourcePayId,
  required String planId,
  required Map<String, dynamic> revisionPayload,
  required List<String> participantIds,
}) {
  if (sourcePayId == null || sourcePayId.isEmpty) return null;
  final local = resolvePlanParticipantDropdownValue(sourcePayId, participantIds);
  if (local != null) return local;

  final sourceMap = revisionPayload['participantSourceIds'];
  if (sourceMap is Map) {
    for (final entry in sourceMap.entries) {
      final localId = entry.key.toString();
      final remoteId = entry.value?.toString() ?? '';
      if (_sameParticipantRef(remoteId, sourcePayId)) {
        final resolved =
            resolvePlanParticipantDropdownValue(localId, participantIds);
        if (resolved != null) return resolved;
      }
    }
  }
  return null;
}

PlanLine _planLineFromPayloadMap(
  String planId,
  Map<String, dynamic> line, {
  Map<String, dynamic>? revisionPayload,
  List<String>? participantIds,
}) {
  var payId = line['paymentResponsibleParticipantId']?.toString();
  if (payId != null &&
      payId.isNotEmpty &&
      revisionPayload != null &&
      participantIds != null) {
    payId = paymentResponsibleIdForLocalPlan(
          sourcePayId: payId,
          planId: planId,
          revisionPayload: revisionPayload,
          participantIds: participantIds,
        ) ??
        payId;
  }
  return PlanLine(
    id: line['id']?.toString() ?? '',
    planId: planId,
    isRecurring: line['isRecurring'] as bool? ?? false,
    title: line['title']?.toString() ?? '',
    currency: line['currency']?.toString() ?? '',
    amountUsesRange: line['amountUsesRange'] as bool? ?? false,
    amountMinor: (line['amountMinor'] as num?)?.toInt(),
    minAmountMinor: (line['minAmountMinor'] as num?)?.toInt(),
    maxAmountMinor: (line['maxAmountMinor'] as num?)?.toInt(),
    description: line['description']?.toString() ?? '',
    cadence: line['cadence']?.toString() ?? '',
    recurrenceDayOfMonth: (line['recurrenceDayOfMonth'] as num?)?.toInt(),
    sortOrder: (line['sortOrder'] as num?)?.toInt() ?? 0,
    groupId: line['groupId']?.toString(),
    amountIsBudgetCap: line['amountIsBudgetCap'] as bool? ?? false,
    paymentResponsibleParticipantId: payId,
    recurrenceSpecJson: line['recurrenceSpecJson']?.toString() ?? '',
    ratioTemplateId: line['ratioTemplateId']?.toString(),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

Future<Map<String, dynamic>?> _revisionPayload(
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

Future<Map<String, dynamic>?> _resolveLineMapForAmendment({
  required AppDatabase db,
  required String planId,
  required String revisionId,
  required HousingAmendmentType type,
  required String? targetLineId,
}) async {
  if (revisionId == 'preview') return null;
  final pendingPayload = await _revisionPayload(db, revisionId);
  if (pendingPayload == null) return null;

  final proposedLines = _payloadLines(pendingPayload);
  var line = _lineById(proposedLines, targetLineId, planId);
  if (line != null) return line;

  if (type != HousingAmendmentType.lineAdd) return null;

  final transport = HousingProposalTransportService(db);
  final activeRevisionId = await transport.resolveActiveRevisionIdForPlan(planId);
  final baselineId = amendmentBaselineRevisionId(
    revisionPayload: pendingPayload,
    revisionId: revisionId,
    packageActiveRevisionId: activeRevisionId,
    isArchived: (pendingPayload['lifecycleState'] as String?) == 'archived',
  );
  var baselinePayload = pendingPayload;
  if (baselineId != null) {
    final loaded = await _revisionPayload(db, baselineId);
    if (loaded != null) baselinePayload = loaded;
  }
  return _lineAddedRelativeToBaseline(
    _payloadLines(baselinePayload),
    proposedLines,
    planId,
  );
}

/// Builds [ExpensePlanLineViewData] from a revision payload line map + ratios.
Future<ExpensePlanLineViewData?> buildExpenseLineViewDataFromPayloadLine({
  required AppDatabase db,
  required String planId,
  required Map<String, dynamic> lineMap,
  required List<Map<String, dynamic>> ratioMaps,
  required List<String> participantIds,
  required List<String> participantNames,
  required AppLocalizations l10n,
  required String dateFormat,
  required String defaultCurrency,
  Map<String, dynamic>? revisionPayload,
}) async {
  final lineId = lineMap['id']?.toString() ?? '';
  if (lineId.isEmpty) return null;
  final planLine = _planLineFromPayloadMap(
    planId,
    lineMap,
    revisionPayload: revisionPayload,
    participantIds: participantIds,
  );
  final splitWeights = _splitWeightsForPayloadLine(lineId, planId, ratioMaps);
  return ExpensePlanLineViewData.load(
    db: db,
    planId: planId,
    line: planLine,
    participantIds: participantIds,
    participantNames: participantNames,
    l10n: l10n,
    dateFormat: dateFormat,
    defaultCurrency: defaultCurrency,
    splitWeightsByParticipant: splitWeights.isEmpty ? null : splitWeights,
  );
}

List<Map<String, dynamic>> ratioMapsForLineInPayload(
  Map<String, dynamic> payload,
  String planId,
  String lineId,
) {
  return [
    for (final ratio in _payloadRatios(payload))
      if (_lineIdMatches(lineId, planId, ratio['lineId']?.toString() ?? ''))
        ratio,
  ];
}

Map<String, dynamic>? lineMapInPayload(
  Map<String, dynamic> payload,
  String planId,
  String? lineId,
) {
  return _lineById(_payloadLines(payload), lineId, planId);
}

/// Loads expense card data from live tables, then from the amendment revision JSON.
Future<ExpensePlanLineViewData?> resolveAmendmentExpenseLinePreview({
  required AppDatabase db,
  required String planId,
  required HousingAmendmentSummary summary,
  required AppLocalizations l10n,
  required String dateFormat,
  required String defaultCurrency,
}) async {
  final roster = await participantsForPlan(db, planId);
  final participantIds = [for (final p in roster) p.id];
  final participantNames = [for (final p in roster) p.displayName];

  if (summary.targetLineId != null && summary.targetLineId!.isNotEmpty) {
    final line = await (db.select(db.planLines)
          ..where((t) => t.id.equals(summary.targetLineId!)))
        .getSingleOrNull();
    if (line != null) {
      return ExpensePlanLineViewData.load(
        db: db,
        planId: planId,
        line: line,
        participantIds: participantIds,
        participantNames: participantNames,
        l10n: l10n,
        dateFormat: dateFormat,
        defaultCurrency: defaultCurrency,
      );
    }

    if (summary.revisionId == 'preview' &&
        summary.type == HousingAmendmentType.lineAdd) {
      final pending = HousingLineAddAmendmentPendingStore.get(planId);
      if (pending != null &&
          planLineIdsMatch(summary.targetLineId!, planId, pending.lineId)) {
        final planLine = _planLineFromPayloadMap(
          planId,
          pending.lineMap,
          revisionPayload: null,
          participantIds: participantIds,
        );
        final splitWeights = _splitWeightsForPayloadLine(
          planLine.id,
          planId,
          pending.ratioMaps,
        );
        return ExpensePlanLineViewData.load(
          db: db,
          planId: planId,
          line: planLine,
          participantIds: participantIds,
          participantNames: participantNames,
          l10n: l10n,
          dateFormat: dateFormat,
          defaultCurrency: defaultCurrency,
          splitWeightsByParticipant: splitWeights.isEmpty ? null : splitWeights,
        );
      }
    }
  }

  final lineMap = await _resolveLineMapForAmendment(
    db: db,
    planId: planId,
    revisionId: summary.revisionId,
    type: summary.type,
    targetLineId: summary.targetLineId,
  );
  if (lineMap == null) return null;

  final pendingPayload = await _revisionPayload(db, summary.revisionId);
  final planLine = _planLineFromPayloadMap(
    planId,
    lineMap,
    revisionPayload: pendingPayload,
    participantIds: participantIds,
  );
  final splitWeights = pendingPayload == null
      ? null
      : _splitWeightsForPayloadLine(
          planLine.id,
          planId,
          _payloadRatios(pendingPayload),
        );

  return ExpensePlanLineViewData.load(
    db: db,
    planId: planId,
    line: planLine,
    participantIds: participantIds,
    participantNames: participantNames,
    l10n: l10n,
    dateFormat: dateFormat,
    defaultCurrency: defaultCurrency,
    splitWeightsByParticipant: splitWeights == null || splitWeights.isEmpty
        ? null
        : splitWeights,
  );
}

/// Single expense-line card for amendment previews (no before/after labels).
class HousingAmendmentExpenseLinePreview extends StatelessWidget {
  const HousingAmendmentExpenseLinePreview({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    required this.summary,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final HousingAmendmentSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!housingAmendmentUsesExpenseLinePreview(summary.type)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(prefs);
    return FutureBuilder<ExpensePlanLineViewData?>(
      future: () async {
        final row = await (db.select(db.plans)
              ..where((t) => t.id.equals(planId)))
            .getSingleOrNull();
        final currency = row?.currency.trim().isNotEmpty == true
            ? row!.currency.trim()
            : 'CAD';
        return resolveAmendmentExpenseLinePreview(
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
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final view = snapshot.data;
        if (view == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: HousingExpenseLinePresentationCard(viewData: view),
        );
      },
    );
  }
}

/// Before/after comparison for plan-change screens (expense card or text fallback).
class HousingAmendmentComparisonSection extends StatelessWidget {
  const HousingAmendmentComparisonSection({
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

  @override
  Widget build(BuildContext context) {
    if (summary.type == HousingAmendmentType.ruleChange) {
      final l10n = AppLocalizations.of(context);
      return FutureBuilder<AgreementRulesAmendmentComparison?>(
        future: loadAgreementRulesAmendmentComparison(
          db: db,
          planId: planId,
          l10n: l10n,
          revisionId:
              summary.revisionId == 'preview' ? null : summary.revisionId,
          previewSummary:
              summary.revisionId == 'preview' ? summary : null,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final comparison = snapshot.data;
          if (comparison == null) {
            return _TextComparison(
              currentLabel: currentLabel,
              currentValue: summary.currentText,
              proposedLabel: proposedLabel,
              proposedValue: summary.proposedText,
            );
          }
          return HousingAmendmentRulesChangeSection(
            db: db,
            planId: planId,
            prefs: prefs,
            comparison: comparison,
          );
        },
      );
    }

    if (summary.type == HousingAmendmentType.lineEdit) {
      return HousingAmendmentLineEditComparisonSection(
        db: db,
        planId: planId,
        prefs: prefs,
        summary: summary,
        currentLabel: currentLabel,
        proposedLabel: proposedLabel,
      );
    }

    if (!housingAmendmentUsesExpenseLinePreview(summary.type)) {
      return _TextComparison(
        currentLabel: currentLabel,
        currentValue: summary.currentText,
        proposedLabel: proposedLabel,
        proposedValue: summary.proposedText,
      );
    }

    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(prefs);
    return FutureBuilder<ExpensePlanLineViewData?>(
      future: () async {
        final row = await (db.select(db.plans)
              ..where((t) => t.id.equals(planId)))
            .getSingleOrNull();
        final currency = row?.currency.trim().isNotEmpty == true
            ? row!.currency.trim()
            : 'CAD';
        return resolveAmendmentExpenseLinePreview(
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
        final view = snapshot.data;
        if (view == null) {
          return _TextComparison(
            currentLabel: currentLabel,
            currentValue: summary.currentText,
            proposedLabel: proposedLabel,
            proposedValue: summary.proposedText,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel(label: proposedLabel),
            const SizedBox(height: 8),
            HousingExpenseLinePresentationCard(viewData: view),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TextComparison extends StatelessWidget {
  const _TextComparison({
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
        _AmendmentValueCard(label: currentLabel, value: currentValue),
        const SizedBox(height: 12),
        _AmendmentValueCard(
          label: proposedLabel,
          value: proposedValue,
          emphasized: true,
        ),
      ],
    );
  }
}

class _AmendmentValueCard extends StatelessWidget {
  const _AmendmentValueCard({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }
}
