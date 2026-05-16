import 'dart:convert';

import '../../db/app_database.dart';

/// Blocking calendar intervals on **other** housing plans where this device
/// has a `planId:self` participant row, per `housing-plan-proposal-offer-flow`.
///
/// Uses **active** agreement dates when a package has an active revision;
/// otherwise the **open** pending revision's proposed agreement dates.
Future<List<({DateTime start, DateTime end})>> listBlockingAgreementDayRanges(
  AppDatabase db, {
  required String excludePlanId,
}) async {
  final ranges = <({DateTime start, DateTime end})>[];
  final housingPlans = await (db.select(db.plans)
        ..where((t) => t.type.equals('housing')))
      .get();

  for (final plan in housingPlans) {
    if (plan.id == excludePlanId) continue;
    final selfPid = '${plan.id}:self';
    final selfRow = await (db.select(db.participants)
          ..where((t) => t.id.equals(selfPid)))
        .getSingleOrNull();
    if (selfRow == null) continue;

    final hasActive = await db.planHasActiveAcceptedProposal(plan.id);
    if (hasActive) {
      final agr = await db.getAgreementForPlan(plan.id);
      if (agr != null) {
        ranges.add((start: agr.periodStart, end: agr.periodEnd));
      }
      continue;
    }

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals(plan.id)))
        .getSingleOrNull();
    final pendingId = pkg?.pendingRevisionId;
    if (pendingId == null) continue;

    final rev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(pendingId)))
        .getSingleOrNull();
    if (rev == null) continue;
    final mapFull = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    if (((mapFull['lifecycleState'] as String?) ?? 'open') != 'open') continue;

    final agrMap = mapFull['agreement'];
    if (agrMap is! Map<String, dynamic>) continue;
    final ps = agrMap['periodStart'];
    final pe = agrMap['periodEnd'];
    if (ps is! String || pe is! String) continue;
    ranges.add((start: DateTime.parse(ps), end: DateTime.parse(pe)));
  }
  return ranges;
}
