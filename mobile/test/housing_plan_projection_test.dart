import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/projection/plan_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanProjection.monthsCoveredInclusive', () {
    test('same month => 1', () {
      final months = PlanProjection.monthsCoveredInclusive(
        DateTime.utc(2026, 5, 1),
        DateTime.utc(2026, 5, 31),
      );
      expect(months, 1);
    });

    test('spans two months => 2 (inclusive)', () {
      final months = PlanProjection.monthsCoveredInclusive(
        DateTime.utc(2026, 5, 15),
        DateTime.utc(2026, 6, 1),
      );
      expect(months, 2);
    });
  });

  group('PlanProjection.projectTotalMinor', () {
    AgreementContract contract({
      required DateTime start,
      required DateTime end,
    }) {
      return AgreementContract(
        id: 'c1',
        planId: 'p1',
        periodStart: start,
        periodEnd: end,
        minNoticeDays: 0,
        penaltyMinor: 0,
        clauses: '',
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    PlanLine recurring({
      required int amountMinor,
    }) {
      return PlanLine(
        id: 'l1',
        planId: 'p1',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: amountMinor,
        minAmountMinor: null,
        maxAmountMinor: null,
        cadence: 'monthly',
        groupId: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    PlanLine oneOff({
      required int minMinor,
      required int maxMinor,
    }) {
      return PlanLine(
        id: 'l2',
        planId: 'p1',
        isRecurring: false,
        title: 'Repair',
        currency: 'CAD',
        amountMinor: null,
        minAmountMinor: minMinor,
        maxAmountMinor: maxMinor,
        cadence: 'monthly',
        groupId: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('recurring monthly multiplies by covered months (inclusive)', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [recurring(amountMinor: 1000)],
        contract: contract(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 6, 30),
        ),
      );
      expect(total, 1000 * 2);
    });

    test('one-off uses midpoint of min/max', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [oneOff(minMinor: 100, maxMinor: 300)],
        contract: contract(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(total, 200);
    });

    test('null amounts treated as 0', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [
          PlanLine(
            id: 'l3',
            planId: 'p1',
            isRecurring: true,
            title: 'Bad data',
            currency: 'CAD',
            amountMinor: null,
            minAmountMinor: null,
            maxAmountMinor: null,
            cadence: 'monthly',
            groupId: null,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        contract: contract(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(total, 0);
    });

    test('caps months using maxMonths', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [recurring(amountMinor: 10)],
        contract: contract(
          start: DateTime.utc(2020, 1, 1),
          end: DateTime.utc(2035, 12, 31),
        ),
        maxMonths: 12,
      );
      expect(total, 10 * 12);
    });
  });
}

