import 'package:compartarenta/housing/expense_form/expense_recurrence_labels.dart';
import 'package:compartarenta/housing/expense_form/expense_recurrence_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monthlyDay round-trip', () {
    const spec = MonthlyDayRecurrence(day: 10, anchorIso: '2026-06-10');
    final json = ExpenseRecurrenceSpec.encode(spec);
    final parsed = ExpenseRecurrenceSpec.parseStored(json);
    expect(parsed, isA<MonthlyDayRecurrence>());
    expect((parsed! as MonthlyDayRecurrence).day, 10);
  });

  test('inclusive calendar day count includes end date', () {
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 30);
    expect(inclusiveCalendarDayCount(start, end), 30);
  });

  test('ordinal of weekday in month', () {
    expect(ordinalOfWeekdayInMonth(DateTime(2026, 6, 1)), 1);
    expect(ordinalOfWeekdayInMonth(DateTime(2026, 6, 8)), 2);
  });

  test('legacy day of month', () {
    final spec = ExpenseRecurrenceSpec.fromLegacyDayOfMonth(15);
    expect(spec, isA<MonthlyDayRecurrence>());
    expect((spec! as MonthlyDayRecurrence).day, 15);
  });
}
