import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../expense_form/expense_recurrence_spec.dart';
import '../expense_form/expense_split_grid_logic.dart';
import '../proposals/housing_proposal_transport_service.dart';

/// Draft line-edit amendment (not written to live plan tables until submit).
class HousingLineEditAmendmentPending {
  const HousingLineEditAmendmentPending({
    required this.lineId,
    required this.lineMap,
    required this.ratioMaps,
  });

  final String lineId;
  final Map<String, dynamic> lineMap;
  final List<Map<String, dynamic>> ratioMaps;
}

/// In-memory draft between the line editor, preview, and relay submit steps.
class HousingLineEditAmendmentPendingStore {
  HousingLineEditAmendmentPendingStore._();

  static final Map<String, HousingLineEditAmendmentPending> _byPlan = {};

  static HousingLineEditAmendmentPending? get(String planId) => _byPlan[planId];

  static void set(String planId, HousingLineEditAmendmentPending pending) {
    _byPlan[planId] = pending;
  }

  static void clear(String planId) => _byPlan.remove(planId);

  static void applyToPayload(String planId, Map<String, dynamic> payload) {
    final pending = get(planId);
    if (pending == null) return;
    applyLineEditToRevisionPayload(
      payload: payload,
      planId: planId,
      lineId: pending.lineId,
      lineMap: pending.lineMap,
      ratioMaps: pending.ratioMaps,
    );
  }

  static HousingLineEditAmendmentPending buildFromForm({
    required String planId,
    required String lineId,
    required String title,
    required String description,
    required String currency,
    required bool isRecurring,
    required ExpenseRecurrenceSpec? recurrenceSpec,
    required int amountMinor,
    required bool amountIsBudgetCap,
    required String? paymentResponsibleParticipantId,
    required int sortOrder,
    required String? ratioTemplateId,
    required ExpenseSplitGridState split,
  }) {
    final specJson = recurrenceSpec == null
        ? ''
        : ExpenseRecurrenceSpec.encode(recurrenceSpec);
    final lineMap = <String, dynamic>{
      'id': lineId,
      'title': title.trim(),
      'description': description.trim(),
      'currency': currency,
      'isRecurring': isRecurring,
      'amountUsesRange': false,
      'amountIsBudgetCap': amountIsBudgetCap,
      'amountMinor': amountMinor,
      'minAmountMinor': null,
      'maxAmountMinor': null,
      'cadence': 'monthly',
      'recurrenceDayOfMonth': null,
      if (specJson.isNotEmpty) 'recurrenceSpecJson': specJson,
      if (paymentResponsibleParticipantId != null &&
          paymentResponsibleParticipantId.isNotEmpty)
        'paymentResponsibleParticipantId': paymentResponsibleParticipantId,
      if (ratioTemplateId != null && ratioTemplateId.isNotEmpty)
        'ratioTemplateId': ratioTemplateId,
      'sortOrder': sortOrder,
    };
    final ratioMaps = [
      for (final row in split.rows)
        {
          'participantId': row.participantId,
          'lineId': lineId,
          'weight': row.weightBps,
        },
    ];
    return HousingLineEditAmendmentPending(
      lineId: lineId,
      lineMap: lineMap,
      ratioMaps: ratioMaps,
    );
  }
}

void applyLineEditToRevisionPayload({
  required Map<String, dynamic> payload,
  required String planId,
  required String lineId,
  required Map<String, dynamic> lineMap,
  required List<Map<String, dynamic>> ratioMaps,
}) {
  final plan = payload['plan'];
  if (plan is! Map) return;
  final lines = plan['lines'];
  if (lines is! List) return;

  var replaced = false;
  final nextLines = <Map<String, dynamic>>[];
  for (final entry in lines) {
    if (entry is! Map) continue;
    if (_lineIdMatches(lineId, planId, entry['id']?.toString() ?? '')) {
      if (!replaced) {
        nextLines.add(lineMap);
        replaced = true;
      }
    } else {
      nextLines.add(Map<String, dynamic>.from(entry));
    }
  }
  if (!replaced) nextLines.add(lineMap);
  plan['lines'] = jsonDecode(jsonEncode(nextLines));

  final ratios = plan['ratios'];
  final kept = <Map<String, dynamic>>[
    if (ratios is List)
      for (final entry in ratios)
        if (entry is Map &&
            !_lineIdMatches(
              lineId,
              planId,
              entry['lineId']?.toString() ?? '',
            ))
          Map<String, dynamic>.from(entry),
    ...ratioMaps,
  ];
  plan['ratios'] = jsonDecode(jsonEncode(kept));
}

bool _lineIdMatches(String targetLineId, String planId, String payloadLineId) {
  if (targetLineId.isEmpty || payloadLineId.isEmpty) return false;
  if (targetLineId == payloadLineId) return true;
  if (payloadLineId.endsWith(':$targetLineId')) return true;
  if (targetLineId.endsWith(':$payloadLineId')) return true;
  final targetTail = targetLineId.contains(':')
      ? targetLineId.split(':').last
      : targetLineId;
  final payloadTail = payloadLineId.contains(':')
      ? payloadLineId.split(':').last
      : payloadLineId;
  return targetTail == payloadTail;
}

/// Restores one plan line (and its ratios) from the active in-force revision.
Future<void> restoreInForcePlanLineFromActiveRevision(
  AppDatabase db,
  String planId,
  String lineId,
) async {
  final transport = HousingProposalTransportService(db);
  final baselineId = await transport.resolveActiveRevisionIdForPlan(planId);
  if (baselineId == null) return;

  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(baselineId)))
      .getSingleOrNull();
  if (rev == null) return;

  Map<String, dynamic> payload;
  try {
    payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  final plan = payload['plan'];
  if (plan is! Map) return;
  final planMap = plan.cast<String, dynamic>();
  final lines = planMap['lines'];
  if (lines is! List) return;

  Map<String, dynamic>? lineMap;
  for (final entry in lines) {
    if (entry is! Map) continue;
    if (_lineIdMatches(lineId, planId, entry['id']?.toString() ?? '')) {
      lineMap = entry.cast<String, dynamic>();
      break;
    }
  }
  if (lineMap == null) return;

  final resolvedLineId = lineMap['id']?.toString() ?? lineId;
  final paySource = lineMap['paymentResponsibleParticipantId']?.toString() ?? '';
  final payLocal = paySource.isEmpty
      ? null
      : paySource.contains(':')
          ? paySource
          : '$planId:$paySource';
  final now = DateTime.now().toUtc();
  final existing = await (db.select(db.planLines)
        ..where((t) => t.id.equals(resolvedLineId)))
      .getSingleOrNull();

  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: resolvedLineId,
      planId: planId,
      isRecurring: lineMap['isRecurring'] == true,
      title: (lineMap['title']?.toString() ?? resolvedLineId).trim(),
      currency: lineMap['currency']?.toString() ?? '',
      amountUsesRange: drift.Value(lineMap['amountUsesRange'] == true),
      amountMinor: drift.Value(_intValue(lineMap['amountMinor'])),
      minAmountMinor: drift.Value(_intValue(lineMap['minAmountMinor'])),
      maxAmountMinor: drift.Value(_intValue(lineMap['maxAmountMinor'])),
      description: drift.Value(lineMap['description']?.toString() ?? ''),
      cadence: drift.Value(lineMap['cadence']?.toString() ?? 'monthly'),
      recurrenceDayOfMonth: drift.Value(_intValue(lineMap['recurrenceDayOfMonth'])),
      sortOrder: drift.Value(
        _intValue(lineMap['sortOrder']) ?? existing?.sortOrder ?? 0,
      ),
      groupId: const drift.Value.absent(),
      paymentResponsibleParticipantId: payLocal == null
          ? const drift.Value.absent()
          : drift.Value(payLocal),
      recurrenceSpecJson:
          drift.Value(lineMap['recurrenceSpecJson']?.toString() ?? ''),
      ratioTemplateId: drift.Value(lineMap['ratioTemplateId']?.toString()),
      amountIsBudgetCap: drift.Value(lineMap['amountIsBudgetCap'] == true),
      createdAt: existing?.createdAt ?? now,
    ),
  );

  await (db.delete(db.planRatios)..where((t) => t.lineId.equals(resolvedLineId)))
      .go();

  final ratios = planMap['ratios'];
  if (ratios is! List) return;
  for (final ratio in ratios) {
    if (ratio is! Map) continue;
    if (!_lineIdMatches(
      resolvedLineId,
      planId,
      ratio['lineId']?.toString() ?? '',
    )) {
      continue;
    }
    final participant = ratio['participantId']?.toString() ?? '';
    if (participant.isEmpty) continue;
    final participantId =
        participant.contains(':') ? participant : '$planId:$participant';
    final weight = ratio['weight'];
    if (weight is! num) continue;
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$planId:$resolvedLineId:$participantId',
        planId: planId,
        participantId: participantId,
        lineId: drift.Value(resolvedLineId),
        groupId: const drift.Value.absent(),
        weight: weight.toInt(),
        createdAt: now,
      ),
    );
  }
}

int? _intValue(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}
