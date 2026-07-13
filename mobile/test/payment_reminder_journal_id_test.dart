import 'package:compartarenta/housing/reminders/payment_reminder_journal_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('before_due journal ids differ by recorded calendar day', () {
    final dueKey = '1';
    final day1 = housingPaymentReminderJournalId(
      planId: 'p',
      planLineId: 'l',
      periodKey: dueKey,
      reminderKind: 'before_due',
      recordedAt: DateTime(2026, 7, 28, 14),
    );
    final day2 = housingPaymentReminderJournalId(
      planId: 'p',
      planLineId: 'l',
      periodKey: dueKey,
      reminderKind: 'before_due',
      recordedAt: DateTime(2026, 7, 30, 14),
    );
    expect(day1, isNot(day2));
    expect(day1, contains('before_due'));
  });

  test('overdue journal id ignores recorded day', () {
    final a = housingPaymentReminderJournalId(
      planId: 'p',
      planLineId: 'l',
      periodKey: '1',
      reminderKind: 'overdue',
      recordedAt: DateTime.utc(2026, 8, 2, 18),
    );
    final b = housingPaymentReminderJournalId(
      planId: 'p',
      planLineId: 'l',
      periodKey: '1',
      reminderKind: 'overdue',
      recordedAt: DateTime.utc(2026, 8, 3, 18),
    );
    expect(a, b);
    expect(a, 'p:l:1:overdue');
  });
}
