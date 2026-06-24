import 'package:compartarenta/housing/participation/housing_voluntary_withdrawal_ack.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ack last day is notice plus five calendar days', () {
    final notice = DateTime(2026, 6, 10);
    expect(
      voluntaryWithdrawalAckLastDayInclusive(notice),
      DateUtils.dateOnly(DateTime(2026, 6, 15)),
    );
  });

  test('ack expiry applies after last inclusive day', () {
    final notice = DateTime(2026, 6, 10);
    expect(
      voluntaryWithdrawalAckExpiryApplies(
        noticeLocal: notice,
        now: DateTime(2026, 6, 15),
      ),
      isFalse,
    );
    expect(
      voluntaryWithdrawalAckExpiryApplies(
        noticeLocal: notice,
        now: DateTime(2026, 6, 16),
      ),
      isTrue,
    );
  });
}
