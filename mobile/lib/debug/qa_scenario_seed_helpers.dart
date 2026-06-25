import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import '../housing/participation/housing_participation_change_kind.dart';
import '../housing/participation/housing_participation_membership_service.dart';
import '../housing/proposals/plan_agreement_proposal_service.dart';
import '../housing/realized_expense/realized_expense_ledger_service.dart';
import '../housing/realized_expense/realized_expense_status.dart';

/// Shared agreement anchor for QA housing scenarios (noon UTC avoids TZ date shift).
final kQaAnchorPeriodStart = DateTime.utc(2027, 1, 1, 12);
final kQaAnchorPeriodEnd = DateTime.utc(2027, 8, 10, 12);
final kQaSeedCreatedAt = DateTime.utc(2027, 1, 1);

/// Plan id for settlement-open scenarios ([settlement_open], [settlement_window_open]).
const kQaSettlementOpenPlanId = 'housing:qa-settlement-open';

String qaPlanIdForScenario(String scenarioId) {
  return switch (scenarioId) {
    'period_end_day' => 'housing:qa-period-end-day',
    'settlement_open' || 'settlement_window_open' => kQaSettlementOpenPlanId,
    'settlement_last_day' => 'housing:qa-settlement-last-day',
    'settlement_closed' => 'housing:qa-settlement-closed',
    'renewal_fork_visible' => 'housing:qa-renewal-fork',
    'voluntary_withdrawal_ack_j5' => 'housing:qa-withdraw-ack',
    'voluntary_withdrawal_effective' => 'housing:qa-withdraw-effective',
    'proposal_response_expired' => 'housing:qa-proposal-expired',
    _ => throw ArgumentError('Unknown QA scenario: $scenarioId'),
  };
}

/// Seeds Monica (self) + Louys with an in-force housing plan and optional expense.
Future<void> seedQaInForceHousingPlan({
  required AppDatabase db,
  required String planId,
  required String title,
  DateTime? periodStart,
  DateTime? periodEnd,
  bool withPublishedExpense = false,
}) async {
  final start = periodStart ?? kQaAnchorPeriodStart;
  final end = periodEnd ?? kQaAnchorPeriodEnd;
  final packageId = 'pkg:$planId';
  final revisionId = 'rev:$planId:active';
  final lineId = 'line:$planId:rent';
  final selfId = '$planId:self';
  final coId = '$planId:p0';
  final createdAt = kQaSeedCreatedAt;

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: createdAt,
      title: drift.Value(title),
      currency: const drift.Value('CAD'),
      notes: const drift.Value.absent(),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: selfId,
      displayName: 'Monica QA',
      avatarId: 'mdi:0',
      createdAt: createdAt,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: coId,
      displayName: 'Louys QA',
      avatarId: 'mdi:1',
      createdAt: createdAt,
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: start,
      periodEnd: end,
      minNoticeDays: const drift.Value(30),
      penaltyMinor: const drift.Value(0),
      clauses: const drift.Value(''),
      withdrawalSameForAll: const drift.Value('true'),
      withdrawalPerParticipantJson: const drift.Value('{}'),
      agreementRulesJson: const drift.Value('{}'),
      version: const drift.Value(1),
      createdAt: createdAt,
    ),
  );
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: lineId,
      planId: planId,
      isRecurring: true,
      title: 'Loyer',
      currency: 'CAD',
      amountMinor: const drift.Value(100000),
      recurrenceDayOfMonth: const drift.Value(1),
      sortOrder: const drift.Value(0),
      createdAt: createdAt,
    ),
  );
  for (final pid in [selfId, coId]) {
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$lineId:$pid',
        planId: planId,
        lineId: drift.Value(lineId),
        participantId: pid,
        weight: 5000,
        createdAt: createdAt,
      ),
    );
  }

  final payload = <String, Object?>{
    'kind': PlanAgreementProposalService.kind,
    'lifecycleState': 'archived',
    'agreement': {
      'periodStart': start.toUtc().toIso8601String(),
      'periodEnd': end.toUtc().toIso8601String(),
    },
  };
  await db.into(db.proposalPackages).insertOnConflictUpdate(
    ProposalPackagesCompanion.insert(
      id: packageId,
      planId: planId,
      createdAt: createdAt,
      activeRevisionId: drift.Value(revisionId),
      pendingRevisionId: const drift.Value.absent(),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: revisionId,
      packageId: packageId,
      contentHash: 'qa:$revisionId',
      proposerParticipantId: selfId,
      payloadJson: jsonEncode(payload),
      createdAt: createdAt,
    ),
  );

  if (withPublishedExpense) {
    final expenseAt = DateTime.utc(2027, 7, 1);
    await db.into(db.realizedExpenses).insert(
      RealizedExpensesCompanion.insert(
        id: 'expense:$planId:1',
        packageId: packageId,
        planId: planId,
        planLineId: lineId,
        amountMinor: 20000,
        currency: 'CAD',
        paymentDate: expenseAt,
        payerParticipantId: selfId,
        kind: RealizedExpenseKind.normal,
        status: RealizedExpenseStatus.published,
        createdAt: expenseAt,
        updatedAt: expenseAt,
      ),
    );
  }

  await HousingParticipationMembershipService(db).ensureMembershipsForPlan(planId);
}

Future<void> seedQaVoluntaryWithdrawal({
  required AppDatabase db,
  required String planId,
  required String changeId,
  required DateTime noticeAt,
  required DateTime departureDate,
  required bool monicaAcknowledged,
}) async {
  final packageId = 'pkg:$planId';
  final louysId = '$planId:p0';
  final monicaId = '$planId:self';

  await db.into(db.housingParticipationChanges).insert(
    HousingParticipationChangesCompanion.insert(
      id: changeId,
      planId: planId,
      packageId: packageId,
      kind: HousingParticipationChangeKind.voluntaryWithdrawal.wireValue,
      initiatorParticipantId: louysId,
      targetParticipantId: drift.Value(louysId),
      departureDate: drift.Value(departureDate),
      status: HousingParticipationChangeStatus.pending.wireValue,
      createdAt: noticeAt,
    ),
  );

  if (monicaAcknowledged) {
    await db.into(db.housingParticipationDecisions).insertOnConflictUpdate(
      HousingParticipationDecisionsCompanion.insert(
        changeId: changeId,
        participantId: monicaId,
        status: HousingParticipationDecisionStatus.accepted.wireValue,
        decidedAt: drift.Value(noticeAt),
      ),
    );
  }
}

/// Open proposal past [responseExpiresAt] with no active revision (expires on module entry).
Future<void> seedQaExpiredPendingProposal({
  required AppDatabase db,
  required String planId,
  required String title,
  required DateTime responseExpiresAt,
}) async {
  final packageId = 'pkg:$planId';
  final revisionId = 'rev:$planId:pending';
  final selfId = '$planId:self';
  final coId = '$planId:p0';
  final createdAt = kQaSeedCreatedAt;
  final periodStart = kQaAnchorPeriodStart;
  final periodEnd = kQaAnchorPeriodEnd;

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: createdAt,
      title: drift.Value(title),
      currency: const drift.Value('CAD'),
      notes: const drift.Value.absent(),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: selfId,
      displayName: 'Monica QA',
      avatarId: 'mdi:0',
      createdAt: createdAt,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: coId,
      displayName: 'Louys QA',
      avatarId: 'mdi:1',
      createdAt: createdAt,
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      minNoticeDays: const drift.Value(30),
      penaltyMinor: const drift.Value(0),
      clauses: const drift.Value(''),
      withdrawalSameForAll: const drift.Value('true'),
      withdrawalPerParticipantJson: const drift.Value('{}'),
      agreementRulesJson: const drift.Value('{}'),
      version: const drift.Value(1),
      createdAt: createdAt,
    ),
  );

  final payload = <String, Object?>{
    'kind': PlanAgreementProposalService.kind,
    'lifecycleState': 'open',
    'responseExpiresAt': responseExpiresAt.toUtc().toIso8601String(),
    'plan': {'title': title},
    'agreement': {
      'periodStart': periodStart.toUtc().toIso8601String(),
      'periodEnd': periodEnd.toUtc().toIso8601String(),
    },
  };
  await db.into(db.proposalPackages).insertOnConflictUpdate(
    ProposalPackagesCompanion.insert(
      id: packageId,
      planId: planId,
      createdAt: createdAt,
      pendingRevisionId: drift.Value(revisionId),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: revisionId,
      packageId: packageId,
      contentHash: 'qa:$revisionId',
      proposerParticipantId: selfId,
      payloadJson: jsonEncode(payload),
      createdAt: createdAt,
    ),
  );
}

Future<bool> qaPlanHasNonZeroBalances(AppDatabase db, String planId) {
  return RealizedExpenseLedgerService(db).hasNonZeroOptimizedBalances(planId);
}
