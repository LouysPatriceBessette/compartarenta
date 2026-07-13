import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import '../housing/realized_expense/realized_expense_line_snapshot.dart';
import '../housing/realized_expense/realized_expense_status.dart';
import 'qa_scenario_seed_helpers.dart';

/// Stable plan id for housing payment reminder QA (Monica emulator).
const kQaPaymentReminderPlanId = 'housing:qa-payment-reminder';

/// Matches [seedQaInForceHousingPlan] line id for this plan (`line:$planId:rent`).
const kQaPaymentReminderLineId = 'line:housing:qa-payment-reminder:rent';

/// In-force active plan with monthly recurring [Loyer]; agreement period wraps [DateTime.now].
///
/// Also seeds one published (unanimously accepted) rent payment dated on the
/// previous due day (day 1 of the current calendar month) so Accepted expenses
/// is not empty when browsing prior months.
Future<void> seedQaPaymentReminderActivePlan(AppDatabase db) async {
  final local = DateTime.now().toLocal();
  final periodStart = DateTime.utc(local.year, local.month, 1, 12);
  final periodEnd = DateTime.utc(local.year + 1, local.month, 1, 12);

  await seedQaInForceHousingPlan(
    db: db,
    planId: kQaPaymentReminderPlanId,
    title: 'Plan QA rappel paiement',
    periodStart: periodStart,
    periodEnd: periodEnd,
  );

  await _seedPreviousDuePublishedLoyer(db, localNow: local);
}

Future<void> _seedPreviousDuePublishedLoyer(
  AppDatabase db, {
  required DateTime localNow,
}) async {
  final planId = kQaPaymentReminderPlanId;
  final packageId = 'pkg:$planId';
  final lineId = kQaPaymentReminderLineId;
  final selfId = '$planId:self';
  final coId = '$planId:p0';
  // Previous period due = day 1 of the current calendar month (Loyer recurrence).
  final paymentDate = DateTime.utc(localNow.year, localNow.month, 1, 12);
  final expenseId = 'expense:$planId:prev-due-rent';

  await db.into(db.realizedExpenses).insertOnConflictUpdate(
        RealizedExpensesCompanion.insert(
          id: expenseId,
          packageId: packageId,
          planId: planId,
          planLineId: lineId,
          amountMinor: 100000,
          currency: 'CAD',
          paymentDate: paymentDate,
          payerParticipantId: selfId,
          kind: RealizedExpenseKind.normal,
          status: RealizedExpenseStatus.published,
          createdAt: paymentDate,
          updatedAt: paymentDate,
        ),
      );

  for (final participantId in [selfId, coId]) {
    await db.into(db.realizedExpenseAcceptances).insertOnConflictUpdate(
          RealizedExpenseAcceptancesCompanion.insert(
            expenseId: expenseId,
            participantId: participantId,
            decision: RealizedExpenseDecision.accepted,
            decidedAt: drift.Value(paymentDate),
          ),
        );
  }

  final published = await (db.select(db.realizedExpenses)
        ..where((t) => t.id.equals(expenseId)))
      .getSingleOrNull();
  if (published != null) {
    await captureLineSnapshotForExpense(db, published);
  }
}
