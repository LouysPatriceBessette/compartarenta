import 'package:compartarenta/housing/expense_form/expense_ratio_template_repository.dart';
import 'package:compartarenta/housing/expense_form/expense_split_grid_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseSplitGridState', () {
    test('equal parts sums to total for three participants', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b', 'c'],
        displayNames: ['A', 'B', 'C'],
        totalMinor: 30000,
      );
      expect(g.sumAmountMinor, 30000);
      expect(g.hasAmountMismatch, isFalse);
      expect(g.weightsAreEqualParts, isTrue);
    });

    test('row amount edit updates weight for that row only', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b'],
        displayNames: ['A', 'B'],
        totalMinor: 10000,
      );
      g.onAmountEdited(0, 7000);
      expect(g.rows[0].amountMinor, 7000);
      expect(g.rows[1].amountMinor, 5000);
      expect(g.hasAmountMismatch, isTrue);
    });

    test('setTotalMinor keeps equal parts exact when weights sum to scale', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b', 'c'],
        displayNames: ['A', 'B', 'C'],
        totalMinor: 100_001,
      );
      g.setTotalMinor(90_003);
      expect(g.sumAmountMinor, 90_003);
      expect(g.hasAmountMismatch, isFalse);
    });

    test('setTotalMinor scales rows by locked weights when sum is not 100%', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b'],
        displayNames: ['A', 'B'],
        totalMinor: 100_000,
      );
      g.onPercentTenthsEdited(0, 600);
      g.onPercentTenthsEdited(1, 100);
      expect(g.rows[0].amountMinor, 60_000);
      expect(g.rows[1].amountMinor, 10_000);
      expect(g.hasAmountMismatch, isTrue);
      // sum 70% of total → under-allocated by 30%
      expect(g.amountDeltaMinor, -30_000);

      g.setTotalMinor(200_000);
      expect(g.rows[0].amountMinor, 120_000);
      expect(g.rows[1].amountMinor, 20_000);
      expect(g.amountDeltaMinor, -60_000);
      expect(g.rows[0].weightBps, 6000);
      expect(g.rows[1].weightBps, 1000);
    });

    test('onAmountEdited updates weight from amount share of total', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b'],
        displayNames: ['A', 'B'],
        totalMinor: 100_000,
      );
      g.onAmountEdited(0, 70_000);
      expect(g.rows[0].weightBps, 7000);
      expect(g.rows[1].amountMinor, 50_000);
      expect(g.amountDeltaMinor, 20_000);
    });

    test('applyWeights from template recomputes amounts', () {
      final g = ExpenseSplitGridState.equalParts(
        participantIds: ['a', 'b', 'c'],
        displayNames: ['A', 'B', 'C'],
        totalMinor: 80000,
      );
      g.applyWeights({
        'a': 2660,
        'b': 4000,
        'c': 3340,
      });
      expect(g.sumAmountMinor, 80000);
      expect(g.rows[0].weightBps, 2660);
    });
  });

  group('ExpenseRatioTemplateRepository', () {
    test('weightsSignature deduplicates key order', () {
      final a = ExpenseRatioTemplateRepository.weightsSignature({
        'p2': 5000,
        'p1': 5000,
      });
      final b = ExpenseRatioTemplateRepository.weightsSignature({
        'p1': 5000,
        'p2': 5000,
      });
      expect(a, b);
    });
  });
}
