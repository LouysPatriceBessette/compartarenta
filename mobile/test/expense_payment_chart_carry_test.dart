import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/expense_payment_chart_carry.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:flutter_test/flutter_test.dart';

RealizedExpense _expense({
  required int amountMinor,
  int carryForward = 0,
  required DateTime paymentDate,
  String planLineId = 'line-e',
}) {
  return RealizedExpense(
    id: 'exp-1',
    packageId: 'pkg',
    planId: 'plan',
    planLineId: planLineId,
    status: RealizedExpenseStatus.published,
    amountMinor: amountMinor,
    paymentChartCarryForwardMinor: carryForward,
    currency: 'CAD',
    paymentDate: paymentDate,
    payerParticipantId: 'plan:self',
    kind: RealizedExpenseKind.normal,
    beneficiaryParticipantId: null,
    description: null,
    priorExpenseId: null,
    planLineTitleSnapshot: null,
    splitRatiosJson: null,
    createdAt: paymentDate,
    updatedAt: paymentDate,
  );
}

void main() {
  group('expenseChartAttributedMinor', () {
    test('full amount when nothing is carried forward', () {
      expect(
        expenseChartAttributedMinor(_expense(amountMinor: 1200, paymentDate: DateTime(2026, 6, 1))),
        1200,
      );
    });

    test('subtracts carry-forward from current month chart total', () {
      expect(
        expenseChartAttributedMinor(
          _expense(
            amountMinor: 1200,
            carryForward: 287,
            paymentDate: DateTime(2026, 6, 1),
          ),
        ),
        913,
      );
    });
  });

  group('expensePaymentChartExcessMinor', () {
    test('detects projected overflow', () {
      const context = ExpensePaymentChartSubmissionContext(
        monthlyTotalMinor: 913,
        carryInMinor: 0,
        chartPaidMinor: 0,
      );
      expect(
        expensePaymentChartExcessMinor(
          context: context,
          newAmountMinor: 1200,
        ),
        287,
      );
    });

    test('includes carry-in and prior chart payments', () {
      const context = ExpensePaymentChartSubmissionContext(
        monthlyTotalMinor: 913,
        carryInMinor: 200,
        chartPaidMinor: 1000,
      );
      expect(
        expensePaymentChartExcessMinor(
          context: context,
          newAmountMinor: 50,
        ),
        137,
      );
    });
  });

  group('expensePaymentChartCarryForwardForSubmission', () {
    test('stores excess only when deferred', () {
      expect(
        expensePaymentChartCarryForwardForSubmission(
          excessMinor: 287,
          deferToNextMonth: true,
        ),
        287,
      );
      expect(
        expensePaymentChartCarryForwardForSubmission(
          excessMinor: 287,
          deferToNextMonth: false,
        ),
        0,
      );
    });
  });
}
