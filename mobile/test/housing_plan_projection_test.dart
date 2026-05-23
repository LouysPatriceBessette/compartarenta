import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/expense_form/expense_recurrence_spec.dart';
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

  group('PlanProjection.monthlyChartUnitMinor', () {
    PlanLine everyNDays({
      required int amountMinor,
      required int n,
    }) {
      return PlanLine(
        id: 'l-n',
        planId: 'p1',
        isRecurring: true,
        title: 'Maint',
        currency: 'CAD',
        amountUsesRange: false,
        amountMinor: amountMinor,
        minAmountMinor: null,
        maxAmountMinor: null,
        description: '',
        cadence: 'monthly',
        recurrenceDayOfMonth: null,
        sortOrder: 0,
        groupId: null,
        amountIsBudgetCap: true,
        paymentResponsibleParticipantId: null,
        recurrenceSpecJson: ExpenseRecurrenceSpec.encode(
          EveryNDaysRecurrence(n: n, anchorIso: '2026-05-01'),
        ),
        ratioTemplateId: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('period 61 days is normalized to 30-day month', () {
      final line = everyNDays(amountMinor: 7500, n: 61);
      expect(PlanProjection.monthlyChartUnitMinor(line), 3689);
      expect(PlanProjection.isMonthlyChartNormalized(line), isTrue);
    });

    test('period 92 days is normalized to 30-day month', () {
      final line = everyNDays(amountMinor: 10000, n: 92);
      expect(PlanProjection.monthlyChartUnitMinor(line), 3261);
    });

    test('period 30 days is left unchanged', () {
      final line = everyNDays(amountMinor: 7500, n: 30);
      expect(PlanProjection.monthlyChartUnitMinor(line), 7500);
      expect(PlanProjection.isMonthlyChartNormalized(line), isFalse);
    });

    test('period 28 days is left unchanged', () {
      final line = everyNDays(amountMinor: 7500, n: 28);
      expect(PlanProjection.monthlyChartUnitMinor(line), 7500);
    });

    test('period 7 days is normalized upward', () {
      final line = everyNDays(amountMinor: 700, n: 7);
      expect(PlanProjection.monthlyChartUnitMinor(line), 3000);
    });
  });

  group('PlanProjection.projectTotalMinor', () {
    Agreement agreement({
      required DateTime start,
      required DateTime end,
    }) {
      return Agreement(
        id: 'c1',
        planId: 'p1',
        periodStart: start,
        periodEnd: end,
        minNoticeDays: 0,
        penaltyMinor: 0,
        clauses: '',
        withdrawalSameForAll: 'true',
        withdrawalPerParticipantJson: '{}',
        agreementRulesJson: '{}',
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    PlanLine recurring({
      required int amountMinor,
      bool amountUsesRange = false,
      bool amountIsBudgetCap = false,
    }) {
      return PlanLine(
        id: 'l1',
        planId: 'p1',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountUsesRange: amountUsesRange,
        amountMinor: amountMinor,
        minAmountMinor: null,
        maxAmountMinor: null,
        description: '',
        cadence: 'monthly',
        recurrenceDayOfMonth: 1,
        sortOrder: 0,
        groupId: null,
        amountIsBudgetCap: amountIsBudgetCap,
        paymentResponsibleParticipantId: null,
        recurrenceSpecJson: '',
        ratioTemplateId: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    PlanLine oneOff({
      required int minMinor,
      required int maxMinor,
      bool amountUsesRange = true,
    }) {
      return PlanLine(
        id: 'l2',
        planId: 'p1',
        isRecurring: false,
        title: 'Repair',
        currency: 'CAD',
        amountUsesRange: amountUsesRange,
        amountMinor: null,
        minAmountMinor: minMinor,
        maxAmountMinor: maxMinor,
        description: '',
        cadence: 'monthly',
        recurrenceDayOfMonth: null,
        sortOrder: 0,
        groupId: null,
        amountIsBudgetCap: false,
        paymentResponsibleParticipantId: null,
        recurrenceSpecJson: '',
        ratioTemplateId: null,
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('budget cap uses amountMinor as unit high estimate', () {
      expect(
        PlanProjection.unitMinor(recurring(amountMinor: 5000, amountIsBudgetCap: true)),
        5000,
      );
    });

    test('recurring monthly multiplies by covered months (inclusive)', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [recurring(amountMinor: 1000)],
        agreement: agreement(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 6, 30),
        ),
      );
      expect(total, 1000 * 2);
    });

    test('one-off uses midpoint of min/max', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [oneOff(minMinor: 100, maxMinor: 300)],
        agreement: agreement(
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
            amountUsesRange: false,
            amountMinor: null,
            minAmountMinor: null,
            maxAmountMinor: null,
            description: '',
            cadence: 'monthly',
            recurrenceDayOfMonth: null,
            sortOrder: 0,
            groupId: null,
            amountIsBudgetCap: false,
            paymentResponsibleParticipantId: null,
            recurrenceSpecJson: '',
            ratioTemplateId: null,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        agreement: agreement(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(total, 0);
    });

    test('caps months using maxMonths', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [recurring(amountMinor: 10)],
        agreement: agreement(
          start: DateTime.utc(2020, 1, 1),
          end: DateTime.utc(2035, 12, 31),
        ),
        maxMonths: 12,
      );
      expect(total, 10 * 12);
    });

    test('one-off fixed amount uses amountMinor', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [
          PlanLine(
            id: 'l4',
            planId: 'p1',
            isRecurring: false,
            title: 'Desk',
            currency: 'CAD',
            amountUsesRange: false,
            amountMinor: 5000,
            minAmountMinor: null,
            maxAmountMinor: null,
            description: '',
            cadence: 'monthly',
            recurrenceDayOfMonth: null,
            sortOrder: 0,
            groupId: null,
            amountIsBudgetCap: false,
            paymentResponsibleParticipantId: null,
            recurrenceSpecJson: '',
            ratioTemplateId: null,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        agreement: agreement(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(total, 5000);
    });

    test('recurring range uses midpoint per month', () {
      final total = PlanProjection.projectTotalMinor(
        lines: [
          PlanLine(
            id: 'l5',
            planId: 'p1',
            isRecurring: true,
            title: 'Utilities',
            currency: 'CAD',
            amountUsesRange: true,
            amountMinor: null,
            minAmountMinor: 800,
            maxAmountMinor: 1200,
            description: '',
            cadence: 'monthly',
            recurrenceDayOfMonth: 15,
            sortOrder: 0,
            groupId: null,
            amountIsBudgetCap: false,
            paymentResponsibleParticipantId: null,
            recurrenceSpecJson: '',
            ratioTemplateId: null,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        agreement: agreement(
          start: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 6, 30),
        ),
      );
      expect(total, 1000 * 2);
    });
  });
}

