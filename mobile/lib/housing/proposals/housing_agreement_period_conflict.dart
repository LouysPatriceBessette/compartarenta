import 'dart:convert';

import '../../db/app_database.dart';
import 'agreement_period_day_overlap.dart';
import 'housing_plan_period_gate.dart';

/// First other housing plan whose agreement period blocks [candidate] (≥2 shared days).
Future<({String planId, String planTitle, DateTime start, DateTime end})?>
findFirstAgreementPeriodConflict({
  required AppDatabase db,
  required String excludePlanId,
  required DateTime candidateStart,
  required DateTime candidateEnd,
}) async {
  final blocking = await listBlockingAgreementDayRangesWithPlanIds(
    db,
    excludePlanId: excludePlanId,
  );
  for (final entry in blocking) {
    if (agreementPeriodsConflictByDayRule(
      candidateStart,
      candidateEnd,
      entry.start,
      entry.end,
    )) {
      return (
        planId: entry.planId,
        planTitle: entry.planTitle,
        start: entry.start,
        end: entry.end,
      );
    }
  }
  return null;
}

/// Like [listBlockingAgreementDayRanges] but includes plan id and title for UX.
Future<
    List<
        ({
          String planId,
          String planTitle,
          DateTime start,
          DateTime end,
        })>> listBlockingAgreementDayRangesWithPlanIds(
  AppDatabase db, {
  required String excludePlanId,
}) async {
  final ranges = <({
    String planId,
    String planTitle,
    DateTime start,
    DateTime end,
  })>[];
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

    final title = plan.title.trim().isEmpty ? plan.id : plan.title.trim();

    final hasActive = await db.planHasActiveAcceptedProposal(plan.id);
    if (hasActive) {
      final agr = await db.getAgreementForPlan(plan.id);
      if (agr != null) {
        ranges.add(
          (
            planId: plan.id,
            planTitle: title,
            start: agr.periodStart,
            end: agr.periodEnd,
          ),
        );
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
    if (((mapFull['lifecycleState'] as String?) ?? 'open') != 'open') {
      continue;
    }

    final agrMap = mapFull['agreement'];
    if (agrMap is! Map<String, dynamic>) continue;
    final ps = agrMap['periodStart'];
    final pe = agrMap['periodEnd'];
    if (ps is! String || pe is! String) continue;
    ranges.add(
      (
        planId: plan.id,
        planTitle: title,
        start: DateTime.parse(ps),
        end: DateTime.parse(pe),
      ),
    );
  }
  return ranges;
}
