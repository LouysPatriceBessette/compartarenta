import 'package:compartarenta/housing/proposals/agreement_period_day_overlap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sharedInclusiveCalendarDays', () {
    test('touching ranges share exactly one calendar day', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 2);
      final c = DateTime(2026, 1, 2);
      final d = DateTime(2026, 1, 3);
      expect(sharedInclusiveCalendarDays(a, b, c, d), 1);
    });

    test('disjoint ranges share zero days', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 1);
      final c = DateTime(2026, 1, 5);
      final d = DateTime(2026, 1, 5);
      expect(sharedInclusiveCalendarDays(a, b, c, d), 0);
    });

    test('overlapping multi-day ranges count inclusive days', () {
      final a = DateTime(2026, 3, 1);
      final b = DateTime(2026, 3, 5);
      final c = DateTime(2026, 3, 4);
      final d = DateTime(2026, 3, 10);
      expect(sharedInclusiveCalendarDays(a, b, c, d), 2);
    });
  });

  group('agreementPeriodsConflictByDayRule', () {
    test('one shared day does not conflict', () {
      expect(
        agreementPeriodsConflictByDayRule(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 2),
        ),
        false,
      );
    });

    test('two or more shared days conflict', () {
      expect(
        agreementPeriodsConflictByDayRule(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 3),
          DateTime(2026, 6, 2),
          DateTime(2026, 6, 4),
        ),
        true,
      );
    });
  });

  group('candidateConflictsWithAnyBlockingRange', () {
    test('returns false when no blocking range conflicts by day rule', () {
      final blocking = [
        (start: DateTime(2026, 1, 10), end: DateTime(2026, 1, 10)),
      ];
      expect(
        candidateConflictsWithAnyBlockingRange(
          DateTime(2026, 1, 11),
          DateTime(2026, 2, 1),
          blocking,
        ),
        false,
      );
    });

    test('returns true when any blocking range shares two or more days', () {
      final blocking = [
        (start: DateTime(2026, 4, 1), end: DateTime(2026, 4, 5)),
      ];
      expect(
        candidateConflictsWithAnyBlockingRange(
          DateTime(2026, 4, 4),
          DateTime(2026, 4, 10),
          blocking,
        ),
        true,
      );
    });
  });
}
