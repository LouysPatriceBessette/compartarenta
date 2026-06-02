import 'dart:convert';

import '../../db/app_database.dart';
import '../proposals/housing_proposal_transport_service.dart';
import 'housing_line_edit_amendment_pending.dart';

/// In-memory draft for [HousingAmendmentType.lineAdd] (not written to live plan
/// tables until the amendment is accepted).
class HousingLineAddAmendmentPendingStore {
  HousingLineAddAmendmentPendingStore._();

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
}

/// Removes live plan lines that are not part of the active in-force revision
/// (e.g. abandoned add-amendment drafts written before submit).
Future<void> purgeNonInForcePlanLines(AppDatabase db, String planId) async {
  final inForceIds = await inForcePlanLineIds(db, planId);
  final lines = await db.listPlanLines(planId);
  for (final line in lines) {
    final kept = inForceIds.any(
      (id) => planLineIdsMatch(line.id, planId, id),
    );
    if (kept) continue;
    await (db.delete(db.planRatios)..where((t) => t.lineId.equals(line.id))).go();
    await (db.delete(db.planLines)..where((t) => t.id.equals(line.id))).go();
  }
}

/// Plan line ids from the active accepted revision payload.
Future<Set<String>> inForcePlanLineIds(
  AppDatabase db,
  String planId,
) async {
  final payload = await activeRevisionPayload(db, planId);
  if (payload == null) {
    return (await db.listPlanLines(planId)).map((l) => l.id).toSet();
  }
  final plan = payload['plan'];
  if (plan is! Map) return {};
  final lines = plan['lines'];
  if (lines is! List) return {};
  final out = <String>{};
  for (final entry in lines) {
    if (entry is! Map) continue;
    final id = entry['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    out.add(id.contains(':') ? id : '$planId:$id');
  }
  return out;
}

Future<List<PlanLine>> listInForcePlanLines(
  AppDatabase db,
  String planId,
) async {
  final inForceIds = await inForcePlanLineIds(db, planId);
  final lines = await db.listPlanLines(planId);
  return [
    for (final line in lines)
      if (inForceIds.any((id) => planLineIdsMatch(line.id, planId, id))) line,
  ];
}

Future<Map<String, dynamic>?> activeRevisionPayload(
  AppDatabase db,
  String planId,
) async {
  final transport = HousingProposalTransportService(db);
  final baselineId = await transport.resolveActiveRevisionIdForPlan(planId);
  if (baselineId == null) return null;
  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(baselineId)))
      .getSingleOrNull();
  if (rev == null) return null;
  try {
    return jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

bool planLineIdsMatch(String targetLineId, String planId, String payloadLineId) {
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
