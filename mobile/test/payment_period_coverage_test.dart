import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/expense_form/expense_recurrence_spec.dart';
import 'package:compartarenta/housing/reminders/payment_period_coverage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('everyNDays sliding period contains evaluation instant', () {
    final anchor = DateTime.utc(2026, 1, 1);
    final line = PlanLine(
      id: 'plan:line:1',
      planId: 'plan:1',
      isRecurring: true,
      title: 'Rent',
      currency: 'CAD',
      amountUsesRange: false,
      amountMinor: 100_00,
      minAmountMinor: null,
      maxAmountMinor: null,
      description: '',
      cadence: 'monthly',
      recurrenceDayOfMonth: null,
      sortOrder: 0,
      groupId: null,
      amountIsBudgetCap: false,
      paymentResponsibleParticipantId: null,
      recurrenceSpecJson: ExpenseRecurrenceSpec.encode(
        EveryNDaysRecurrence(n: 14, anchorIso: anchor.toIso8601String()),
      ),
      ratioTemplateId: null,
      createdAt: anchor,
    );
    final at = DateTime.utc(2026, 1, 20);
    final period = slidingPeriodContaining(line: line, atUtc: at);
    expect(period, isNotNull);
    expect(period!.windowDays, 14);
    expect(at.isBefore(period.endUtcExclusive), isTrue);
    expect(!at.isBefore(period.startUtc), isTrue);
  });
}
