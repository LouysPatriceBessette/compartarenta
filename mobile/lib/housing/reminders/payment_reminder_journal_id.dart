/// Stable primary key for a housing payment-reminder journal row.
///
/// - `before_due` (#10): one row per calendar day of [recordedAt] so successive
///   before-due fires for the same period (J−4, J−2, due day J) do not overwrite.
/// - `overdue` (#11): one row per period (`periodKey` + kind).
String housingPaymentReminderJournalId({
  required String planId,
  required String planLineId,
  required String periodKey,
  required String reminderKind,
  required DateTime recordedAt,
}) {
  if (reminderKind == 'before_due') {
    final local = recordedAt.toLocal();
    final dayKey =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return '$planId:$planLineId:$periodKey:$reminderKind:$dayKey';
  }
  return '$planId:$planLineId:$periodKey:$reminderKind';
}
