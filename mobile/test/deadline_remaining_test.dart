import 'package:compartarenta/util/deadline_remaining.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeadlineRemaining.compute', () {
    test('more than 24 hours => days', () {
      final now = DateTime.utc(2026, 5, 23, 12);
      final deadline = now.add(const Duration(hours: 50));
      final r = DeadlineRemaining.compute(deadline, now);
      expect(r.kind, DeadlineRemainingKind.days);
      expect(r.days, 2);
    });

    test('between 4 and 24 hours => today', () {
      final now = DateTime.utc(2026, 5, 23, 12);
      final deadline = now.add(const Duration(hours: 10));
      final r = DeadlineRemaining.compute(deadline, now);
      expect(r.kind, DeadlineRemainingKind.today);
    });

    test('at or past deadline => expired', () {
      final now = DateTime.utc(2026, 5, 23, 12);
      expect(
        DeadlineRemaining.compute(now, now).kind,
        DeadlineRemainingKind.expired,
      );
      expect(
        DeadlineRemaining.compute(now.subtract(const Duration(seconds: 1)), now)
            .kind,
        DeadlineRemainingKind.expired,
      );
    });
  });

  group('DeadlineRemaining.formatCountdown', () {
    test('under one hour omits hour prefix', () {
      expect(
        DeadlineRemaining.formatCountdown(const Duration(minutes: 5, seconds: 7)),
        '05:07',
      );
    });

    test('one hour or more uses HH:MM:SS', () {
      expect(
        DeadlineRemaining.formatCountdown(const Duration(hours: 2, minutes: 3)),
        '02:03:00',
      );
    });
  });
}
