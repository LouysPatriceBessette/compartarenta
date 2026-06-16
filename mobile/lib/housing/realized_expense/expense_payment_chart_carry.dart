import '../../db/app_database.dart';
import '../projection/plan_projection.dart';
import 'realized_expense_ledger_service.dart';
import 'realized_expense_status.dart';

/// Chart-attributed amount from a single published expense in its payment month.
int expenseChartAttributedMinor(RealizedExpense expense) {
  final carry = expense.paymentChartCarryForwardMinor;
  if (carry <= 0) {
    return expense.amountMinor;
  }
  return (expense.amountMinor - carry).clamp(0, expense.amountMinor);
}

/// Carry-in for [planLineId] on the payment-status chart for [year]-[month].
Future<int> expensePaymentChartCarryInMinor({
  required RealizedExpenseLedgerService ledger,
  required String packageId,
  required String planId,
  required String planLineId,
  required int year,
  required int month,
}) async {
  final previousMonth = month == 1
      ? DateTime(year - 1, 12)
      : DateTime(year, month - 1);
  final published = await ledger.listPublishedForMonth(
    packageId: packageId,
    year: previousMonth.year,
    month: previousMonth.month,
  );
  return published
      .where(
        (e) =>
            e.planId == planId &&
            e.planLineId == planLineId &&
            RealizedExpenseKind.usesPlanLine(e.kind),
      )
      .fold<int>(0, (sum, e) => sum + e.paymentChartCarryForwardMinor);
}

/// Chart-attributed paid total for [planLineId] in [year]-[month].
Future<int> expensePaymentChartPaidMinor({
  required RealizedExpenseLedgerService ledger,
  required String packageId,
  required String planId,
  required String planLineId,
  required int year,
  required int month,
  String? excludeExpenseId,
}) async {
  final carryIn = await expensePaymentChartCarryInMinor(
    ledger: ledger,
    packageId: packageId,
    planId: planId,
    planLineId: planLineId,
    year: year,
    month: month,
  );
  final published = await ledger.listPublishedForMonth(
    packageId: packageId,
    year: year,
    month: month,
  );
  final attributed = published
      .where(
        (e) =>
            e.planId == planId &&
            e.planLineId == planLineId &&
            RealizedExpenseKind.usesPlanLine(e.kind) &&
            (excludeExpenseId == null || e.id != excludeExpenseId),
      )
      .fold<int>(0, (sum, e) => sum + expenseChartAttributedMinor(e));
  return carryIn + attributed;
}

final class ExpensePaymentChartSubmissionContext {
  const ExpensePaymentChartSubmissionContext({
    required this.monthlyTotalMinor,
    required this.carryInMinor,
    required this.chartPaidMinor,
  });

  final int monthlyTotalMinor;
  final int carryInMinor;
  final int chartPaidMinor;
}

/// Context for deciding whether a new payment exceeds the monthly chart total.
Future<ExpensePaymentChartSubmissionContext?> chartSubmissionContext({
  required AppDatabase db,
  required RealizedExpenseLedgerService ledger,
  required String planId,
  required String packageId,
  required String planLineId,
  required DateTime paymentDate,
  String? excludeExpenseId,
}) async {
  PlanLine? line;
  for (final candidate in await db.listPlanLines(planId)) {
    if (candidate.id == planLineId) {
      line = candidate;
      break;
    }
  }
  if (line == null) {
    return null;
  }

  final monthlyTotalMinor = PlanProjection.monthlyChartUnitMinor(line);
  final chartPaidMinor = await expensePaymentChartPaidMinor(
    ledger: ledger,
    packageId: packageId,
    planId: planId,
    planLineId: planLineId,
    year: paymentDate.year,
    month: paymentDate.month,
    excludeExpenseId: excludeExpenseId,
  );
  final carryInMinor = await expensePaymentChartCarryInMinor(
    ledger: ledger,
    packageId: packageId,
    planId: planId,
    planLineId: planLineId,
    year: paymentDate.year,
    month: paymentDate.month,
  );
  return ExpensePaymentChartSubmissionContext(
    monthlyTotalMinor: monthlyTotalMinor,
    carryInMinor: carryInMinor,
    chartPaidMinor: chartPaidMinor,
  );
}

/// Excess over the monthly chart total after adding [newAmountMinor].
int expensePaymentChartExcessMinor({
  required ExpensePaymentChartSubmissionContext context,
  required int newAmountMinor,
}) {
  final projected = context.chartPaidMinor + newAmountMinor;
  final excess = projected - context.monthlyTotalMinor;
  return excess > 0 ? excess : 0;
}

/// Carry-forward to store on the expense when the user defers [excessMinor].
int expensePaymentChartCarryForwardForSubmission({
  required int excessMinor,
  required bool deferToNextMonth,
}) {
  return deferToNextMonth ? excessMinor : 0;
}

/// Whether the chart should allow the paid bar to exceed the scale height.
bool expensePaymentChartShowsOverflow({
  required int displayPaidMinor,
  required int monthlyTotalMinor,
}) {
  return monthlyTotalMinor > 0 && displayPaidMinor > monthlyTotalMinor;
}
