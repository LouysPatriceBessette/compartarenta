import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:compartarenta/housing/realized_expense/expense_payment_status.dart';

void main() {
  group('expensePaymentFlattenedAmount', () {
    test('zero stays zero', () {
      expect(expensePaymentFlattenedAmount(0), 0);
    });

    test('applies exponent 0.25', () {
      expect(
        expensePaymentFlattenedAmount(10000),
        closeTo(math.pow(10000, 0.25), 0.0001),
      );
    });
  });

  group('expensePaymentBandHeightPixels', () {
    test('largest flattened amount maps to reference height', () {
      const amount = 10000;
      final flattened = expensePaymentFlattenedAmount(amount);
      expect(
        expensePaymentBandHeightPixels(
          amountMinor: amount,
          maxFlattenedAmount: flattened,
        ),
        expensePaymentBandReferenceHeightPx,
      );
    });

    test('smaller amount scales proportionally to flattened values', () {
      const large = 10000;
      const small = 100;
      final maxFlattened = expensePaymentFlattenedAmount(large);
      final smallFlattened = expensePaymentFlattenedAmount(small);
      expect(
        expensePaymentBandHeightPixels(
          amountMinor: small,
          maxFlattenedAmount: maxFlattened,
        ),
        closeTo(
          expensePaymentBandReferenceHeightPx * smallFlattened / maxFlattened,
          0.0001,
        ),
      );
    });

    test('zero max flattened yields zero height', () {
      expect(
        expensePaymentBandHeightPixels(
          amountMinor: 500,
          maxFlattenedAmount: 0,
        ),
        0,
      );
    });
  });
}
