// Day-only agreement period checks per housing-plan-proposal-offer-flow:
// Compare calendar dates only: ≤1 shared day is allowed; ≥2 shared days blocks.

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Inclusive calendar-day count for the intersection of two inclusive date ranges.
/// Returns 0 when disjoint.
int sharedInclusiveCalendarDays(
  DateTime aStart,
  DateTime aEnd,
  DateTime bStart,
  DateTime bEnd,
) {
  final as = _dateOnly(aStart);
  final ae = _dateOnly(aEnd);
  final bs = _dateOnly(bStart);
  final be = _dateOnly(bEnd);
  if (as.isAfter(ae) || bs.isAfter(be)) return 0;
  final start = as.isAfter(bs) ? as : bs;
  final end = ae.isBefore(be) ? ae : be;
  if (start.isAfter(end)) return 0;
  return end.difference(start).inDays + 1;
}

/// True when the candidate period **conflicts** with the blocking period
/// (**two or more** shared calendar days).
bool agreementPeriodsConflictByDayRule(
  DateTime candidateStart,
  DateTime candidateEnd,
  DateTime blockingStart,
  DateTime blockingEnd,
) =>
    sharedInclusiveCalendarDays(
      candidateStart,
      candidateEnd,
      blockingStart,
      blockingEnd,
    ) >=
    2;

/// True when [candidate] conflicts with **any** blocking range.
bool candidateConflictsWithAnyBlockingRange(
  DateTime candidateStart,
  DateTime candidateEnd,
  Iterable<({DateTime start, DateTime end})> blockingRanges,
) {
  for (final b in blockingRanges) {
    if (agreementPeriodsConflictByDayRule(
          candidateStart,
          candidateEnd,
          b.start,
          b.end,
        )) {
      return true;
    }
  }
  return false;
}
