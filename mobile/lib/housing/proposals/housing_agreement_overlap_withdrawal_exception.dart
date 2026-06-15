import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../participation/housing_participation_change_kind.dart';
import '../participation/housing_participation_change_service.dart';
import 'agreement_period_day_overlap.dart';

/// Whether [conflictingPlanId] has a pending voluntary withdrawal whose
/// departure date is on or before [candidatePeriodStart] (local calendar),
/// satisfying the overlap-gate exception for accepting another plan.
Future<bool> qualifyingVoluntaryWithdrawalClearsOverlap({
  required AppDatabase db,
  required String conflictingPlanId,
  required DateTime candidatePeriodStart,
}) async {
  final pending = await HousingParticipationChangeService(db).pendingForPlan(
    conflictingPlanId,
  );
  if (pending == null) return false;
  final kind = HousingParticipationChangeKind.fromWire(pending.kind);
  if (kind != HousingParticipationChangeKind.voluntaryWithdrawal) return false;
  final departure = pending.departureDate;
  if (departure == null) return false;

  final departureLocal = DateUtils.dateOnly(departure.toLocal());
  final startLocal = DateUtils.dateOnly(candidatePeriodStart.toLocal());
  return !departureLocal.isAfter(startLocal);
}

/// Returns the first blocking overlap unless cleared by voluntary withdrawal.
Future<
    ({
      String planId,
      String planTitle,
      DateTime start,
      DateTime end,
    })?> findOverlapConflictRequiringWithdrawal({
  required AppDatabase db,
  required String excludePlanId,
  required DateTime candidateStart,
  required DateTime candidateEnd,
  required Future<
          ({
            String planId,
            String planTitle,
            DateTime start,
            DateTime end,
          })?>
      Function() findConflict,
}) async {
  final conflict = await findConflict();
  if (conflict == null) return null;

  final cleared = await qualifyingVoluntaryWithdrawalClearsOverlap(
    db: db,
    conflictingPlanId: conflict.planId,
    candidatePeriodStart: candidateStart,
  );
  if (cleared) return null;
  return conflict;
}

/// Like [candidateConflictsWithAnyBlockingRange] but skips ranges whose plan
/// has a qualifying voluntary withdrawal for [candidateStart].
Future<bool> candidateConflictsWithBlockingRangesAfterWithdrawalException({
  required AppDatabase db,
  required DateTime candidateStart,
  required DateTime candidateEnd,
  required List<({DateTime start, DateTime end, String planId})> blocking,
}) async {
  for (final entry in blocking) {
    if (!agreementPeriodsConflictByDayRule(
      candidateStart,
      candidateEnd,
      entry.start,
      entry.end,
    )) {
      continue;
    }
    final cleared = await qualifyingVoluntaryWithdrawalClearsOverlap(
      db: db,
      conflictingPlanId: entry.planId,
      candidatePeriodStart: candidateStart,
    );
    if (!cleared) return true;
  }
  return false;
}
