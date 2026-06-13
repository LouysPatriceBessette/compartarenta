import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';

/// Tracks per-participant active/departed state and roster helpers.
class HousingParticipationMembershipService {
  HousingParticipationMembershipService(this._db);

  final AppDatabase _db;

  Future<void> ensureMembershipsForPlan(String planId) async {
    final roster = await participantsForPlan(_db, planId);
    for (final p in roster) {
      await _db.into(_db.housingPlanMemberships).insert(
        HousingPlanMembershipsCompanion.insert(
          planId: planId,
          participantId: p.id,
          status: HousingPlanMembershipStatus.active.wireValue,
        ),
        mode: drift.InsertMode.insertOrIgnore,
      );
    }
  }

  Future<bool> isActiveMember(String planId, String participantId) async {
    final inactiveGhost =
        await (_db.select(_db.housingInactiveParticipants)
              ..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.sourceParticipantId.equals(participantId) &
                    t.clearedAt.isNull(),
              ))
            .getSingleOrNull();
    if (inactiveGhost != null) return false;

    final row =
        await (_db.select(_db.housingPlanMemberships)
              ..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.participantId.equals(participantId),
              ))
            .getSingleOrNull();
    if (row == null) return true;
    return row.status == HousingPlanMembershipStatus.active.wireValue;
  }

  /// Repairs devices that recorded an effective participation change before
  /// departure side effects ran (e.g. effective notify inserted first).
  Future<void> reconcileEffectiveDepartures(String planId) async {
    final changes = await (_db.select(_db.housingParticipationChanges)
          ..where(
            (t) =>
                t.planId.equals(planId) &
                t.status.equals(
                  HousingParticipationChangeStatus.effective.wireValue,
                ),
          ))
        .get();
    for (final change in changes) {
      final kind = HousingParticipationChangeKind.fromWire(change.kind);
      if (kind == null || kind == HousingParticipationChangeKind.immediateTermination) {
        continue;
      }
      final target = kind == HousingParticipationChangeKind.ejection
          ? change.targetParticipantId
          : change.targetParticipantId ?? change.initiatorParticipantId;
      if (target == null || target.isEmpty) continue;
      if (!await isActiveMember(planId, target)) continue;
      await markDeparted(
        planId: planId,
        participantId: target,
        departureKind: kind,
        changeId: change.id,
        departedAt: change.departureDate ?? change.settledAt ?? DateTime.now().toUtc(),
      );
    }
  }

  Future<int> activeParticipantCount(String planId) async {
    final roster = await activeParticipantsForPlan(planId);
    return roster.length;
  }

  Future<List<Participant>> activeParticipantsForPlan(String planId) async {
    await reconcileEffectiveDepartures(planId);
    await ensureMembershipsForPlan(planId);
    final roster = sortParticipantsForPlan(
      planId,
      await participantsForPlan(_db, planId),
    );
    final out = <Participant>[];
    for (final p in roster) {
      if (await isActiveMember(planId, p.id)) {
        out.add(p);
      }
    }
    return out;
  }

  Future<void> markDeparted({
    required String planId,
    required String participantId,
    required HousingParticipationChangeKind departureKind,
    required String changeId,
    DateTime? departedAt,
  }) async {
    final when = departedAt ?? DateTime.now().toUtc();
    await _db
        .into(_db.housingPlanMemberships)
        .insertOnConflictUpdate(
          HousingPlanMembershipsCompanion(
            planId: drift.Value(planId),
            participantId: drift.Value(participantId),
            status: drift.Value(HousingPlanMembershipStatus.departed.wireValue),
            departedAt: drift.Value(when),
            departureKind: drift.Value(departureKind.wireValue),
            changeId: drift.Value(changeId),
          ),
        );
  }

  Future<void> markAllDeparted({
    required String planId,
    required HousingParticipationChangeKind departureKind,
    required String changeId,
  }) async {
    final roster = await participantsForPlan(_db, planId);
    final now = DateTime.now().toUtc();
    for (final p in roster) {
      await markDeparted(
        planId: planId,
        participantId: p.id,
        departureKind: departureKind,
        changeId: changeId,
        departedAt: now,
      );
    }
  }

  /// Hub title suffix: active range or past agreement with departure date.
  Future<({String titlePrefix, String periodRange})> hubTitleParts({
    required String planId,
    required String selfParticipantId,
    required String activeHubTitleL10n,
    required String pastHubTitleL10n,
    required String Function(DateTime) formatDate,
  }) async {
    final agreement = await _db.getAgreementForPlan(planId);
    if (agreement == null) {
      return (titlePrefix: activeHubTitleL10n, periodRange: '');
    }
    final start = formatDate(agreement.periodStart.toLocal());
    final end = formatDate(agreement.periodEnd.toLocal());
    final range = '$start - $end';

    final membership =
        await (_db.select(_db.housingPlanMemberships)
              ..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.participantId.equals(selfParticipantId),
              ))
            .getSingleOrNull();
    if (membership?.status == HousingPlanMembershipStatus.departed.wireValue) {
      final departedAt = membership!.departedAt;
      final dep =
          departedAt != null
              ? formatDate(departedAt.toLocal())
              : formatDate(DateUtils.dateOnly(DateTime.now()));
      return (titlePrefix: pastHubTitleL10n, periodRange: '$start - $dep');
    }
    return (titlePrefix: activeHubTitleL10n, periodRange: range);
  }
}
