import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/reminders/payment_reminder_journal_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('before_due journal month uses recordedAt, not periodDueAt', () {
    final entry = HousingPaymentOverdueJournalEntry(
      id: '1',
      planId: 'p',
      planLineId: 'l',
      periodKey: 'k',
      periodDueAt: DateTime.utc(2026, 8, 1, 12),
      recordedAt: DateTime.utc(2026, 7, 28, 18),
      reminderKind: 'before_due',
    );
    expect(
      journalMonthForHousingPaymentReminder(entry),
      DateTime(2026, 7),
    );
  });

  test('overdue journal month uses periodDueAt', () {
    final entry = HousingPaymentOverdueJournalEntry(
      id: '2',
      planId: 'p',
      planLineId: 'l',
      periodKey: 'k',
      periodDueAt: DateTime.utc(2026, 8, 1, 12),
      recordedAt: DateTime.utc(2026, 8, 2, 18),
      reminderKind: 'overdue',
    );
    expect(
      journalMonthForHousingPaymentReminder(entry),
      DateTime(2026, 8),
    );
  });
}
