import '../../db/app_database.dart';

/// Calendar month where a payment-reminder journal card is shown.
///
/// - `before_due` (#10): month of [HousingPaymentOverdueJournalEntry.recordedAt]
///   (notification day, e.g. 28 Jul for a J−4 fire).
/// - `overdue` (#11) and due-day reminders: month of
///   [HousingPaymentOverdueJournalEntry.periodDueAt] (e.g. August).
DateTime journalMonthForHousingPaymentReminder(
  HousingPaymentOverdueJournalEntry entry,
) {
  final at = entry.reminderKind == 'before_due'
      ? entry.recordedAt
      : entry.periodDueAt;
  final local = at.toLocal();
  return DateTime(local.year, local.month);
}
