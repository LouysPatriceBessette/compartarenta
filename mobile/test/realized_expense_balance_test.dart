import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_balance.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal expense splits owed to payer', () {
    final published = [
      RealizedExpense(
        id: 'e1',
        packageId: 'pkg',
        planId: 'plan',
        planLineId: 'line',
        status: RealizedExpenseStatus.published,
        amountMinor: 10000,
        currency: 'CAD',
        paymentDate: DateTime.utc(2026, 5, 1),
        payerParticipantId: 'p1',
        kind: RealizedExpenseKind.normal,
        beneficiaryParticipantId: null,
        priorExpenseId: null,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
      ),
    ];
    final ratios = [
      PlanRatio(
        id: 'r1',
        planId: 'plan',
        lineId: 'line',
        participantId: 'p1',
        weight: 5000,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      PlanRatio(
        id: 'r2',
        planId: 'plan',
        lineId: 'line',
        participantId: 'p2',
        weight: 5000,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
    final balances = computePairwiseBalances(
      publishedExpenses: published,
      planRatios: ratios,
      participantIds: ['p1', 'p2'],
    );
    expect(balances, hasLength(1));
    expect(balances.single.fromParticipantId, 'p2');
    expect(balances.single.toParticipantId, 'p1');
    expect(balances.single.amountMinor, 5000);
  });
}
