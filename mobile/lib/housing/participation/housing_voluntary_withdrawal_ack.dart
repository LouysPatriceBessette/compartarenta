import 'package:flutter/material.dart' show DateUtils;

/// Calendar days after notice date when acknowledgement is still open (inclusive).
const kVoluntaryWithdrawalAckDeadlineCalendarDays = 5;

/// Local calendar date of the withdrawal notice (change creation).
DateTime voluntaryWithdrawalNoticeDateLocal(DateTime createdAtUtc) {
  return DateUtils.dateOnly(createdAtUtc.toLocal());
}

/// Last local calendar day on which peers may still acknowledge manually.
DateTime voluntaryWithdrawalAckLastDayInclusive(DateTime noticeLocal) {
  return DateUtils.dateOnly(
    noticeLocal.add(
      const Duration(days: kVoluntaryWithdrawalAckDeadlineCalendarDays),
    ),
  );
}

/// True when manual acknowledgement time has ended; missing acks default after this.
bool voluntaryWithdrawalAckExpiryApplies({
  required DateTime noticeLocal,
  required DateTime now,
}) {
  final today = DateUtils.dateOnly(now.toLocal());
  final lastDay = voluntaryWithdrawalAckLastDayInclusive(noticeLocal);
  return today.isAfter(lastDay);
}
