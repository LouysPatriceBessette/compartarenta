import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_ledger_service.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Db extends AppDatabase {
  _Db() : super.forTesting(NativeDatabase.memory());
}

RealizedExpense _expense({
  required String payerParticipantId,
  required String status,
}) {
  final now = DateTime.utc(2026, 7, 16, 22, 47, 30);
  return RealizedExpense(
    id: 'exp-1',
    packageId: 'pkg',
    planId: 'plan',
    planLineId: 'line',
    status: status,
    amountMinor: 1000,
    currency: 'CAD',
    paymentDate: now,
    payerParticipantId: payerParticipantId,
    kind: RealizedExpenseKind.normal,
    paymentChartCarryForwardMinor: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('shouldNotifyAcceptedDecision notifies payer on each peer accept', () async {
    const payerId = 'payer';
    const reviewerId = 'reviewer';
    final ledger = RealizedExpenseLedgerService(_Db());

    for (final status in [
      RealizedExpenseStatus.proposed,
      RealizedExpenseStatus.published,
    ]) {
      final expense = _expense(payerParticipantId: payerId, status: status);
      expect(
        await ledger.shouldNotifyAcceptedDecision(
          expense: expense,
          selfParticipantId: payerId,
        ),
        isTrue,
        reason: 'payer should be notified while status is $status',
      );
      expect(
        await ledger.shouldNotifyAcceptedDecision(
          expense: expense,
          selfParticipantId: reviewerId,
        ),
        isFalse,
        reason: 'reviewer should not receive payer accept notifications',
      );
    }
  });
}
