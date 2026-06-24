import '../../db/app_database.dart';
import '../amendment/housing_active_agreement_service.dart';
import '../participation/housing_participation_membership_service.dart';
import '../realized_expense/realized_expense_repository.dart';
import '../realized_expense/realized_expense_status.dart';

/// Participant ids on [planId] linked to [contactId].
Future<List<String>> participantIdsForContactOnPlan(
  AppDatabase db, {
  required String planId,
  required String contactId,
}) async {
  final prefix = '$planId:';
  final rows = await (db.select(db.participants)
        ..where((t) => t.contactId.equals(contactId)))
      .get();
  return rows
      .where((p) => p.id.startsWith(prefix))
      .map((p) => p.id)
      .toList(growable: false);
}

bool isUnpublishedRealizedExpenseStatus(String status) =>
    status == RealizedExpenseStatus.draft ||
    status == RealizedExpenseStatus.proposed ||
    status == RealizedExpenseStatus.accepted;

Future<bool> realizedExpenseInvolvesParticipant({
  required RealizedExpense expense,
  required String participantId,
  required RealizedExpenseRepository repo,
}) async {
  if (expense.payerParticipantId == participantId) return true;
  final beneficiary = expense.beneficiaryParticipantId;
  if (beneficiary != null && beneficiary == participantId) return true;
  if (expense.status == RealizedExpenseStatus.draft) return false;

  final acceptances = await repo.acceptancesFor(expense.id);
  return acceptances.any((a) => a.participantId == participantId);
}

/// True when [contactId] is still an active member on an in-force agreement.
Future<bool> housingInForceAgreementBlocksContactDisconnect({
  required AppDatabase db,
  required String planId,
  required String contactId,
  DateTime? now,
}) async {
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) return false;

  final agreementSvc = HousingActiveAgreementService(db);
  if (!agreementSvc.isAgreementPeriodOpen(agreement, now: now)) {
    return false;
  }

  final participantIds = await participantIdsForContactOnPlan(
    db,
    planId: planId,
    contactId: contactId,
  );
  if (participantIds.isEmpty) return false;

  final membership = HousingParticipationMembershipService(db);
  await membership.ensureMembershipsForPlan(planId);
  for (final participantId in participantIds) {
    if (await membership.isActiveMember(planId, participantId)) {
      return true;
    }
  }
  return false;
}

/// True when an unpublished realized expense on [planId] involves [contactId].
Future<bool> housingUnpublishedExpenseBlocksContactDisconnect({
  required AppDatabase db,
  required String planId,
  required String contactId,
}) async {
  final participantIds = await participantIdsForContactOnPlan(
    db,
    planId: planId,
    contactId: contactId,
  );
  if (participantIds.isEmpty) return false;

  final expenses = await (db.select(db.realizedExpenses)
        ..where((t) => t.planId.equals(planId)))
      .get();
  if (expenses.isEmpty) return false;

  final repo = RealizedExpenseRepository(db);
  final pidSet = participantIds.toSet();

  for (final expense in expenses) {
    if (!isUnpublishedRealizedExpenseStatus(expense.status)) continue;
    for (final participantId in pidSet) {
      if (await realizedExpenseInvolvesParticipant(
        expense: expense,
        participantId: participantId,
        repo: repo,
      )) {
        return true;
      }
    }
  }
  return false;
}
