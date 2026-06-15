import 'package:compartarenta/util/fixed_decimal_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatFixedDecimalInputOnBlur', () {
    test('pads money values to two decimals', () {
      expect(
        formatFixedDecimalInputOnBlur('1000', fractionDigits: 2),
        '1000.00',
      );
      expect(
        formatFixedDecimalInputOnBlur('1000.5', fractionDigits: 2),
        '1000.50',
      );
      expect(
        formatFixedDecimalInputOnBlur('1000,5', fractionDigits: 2),
        '1000.50',
      );
    });

    test('pads signed money values to two decimals', () {
      expect(
        formatFixedDecimalInputOnBlur('-1000', fractionDigits: 2, signed: true),
        '-1000.00',
      );
    });

    test('pads percent values to one decimal', () {
      expect(
        formatFixedDecimalInputOnBlur('30', fractionDigits: 1),
        '30.0',
      );
      expect(
        formatFixedDecimalInputOnBlur('69.94', fractionDigits: 1),
        '69.9',
      );
      expect(
        formatFixedDecimalInputOnBlur('69.95', fractionDigits: 1),
        '70.0',
      );
    });

    test('returns null for empty or invalid text', () {
      expect(formatFixedDecimalInputOnBlur('', fractionDigits: 2), isNull);
      expect(formatFixedDecimalInputOnBlur('abc', fractionDigits: 2), isNull);
    });
  });

  group('applyFixedDecimalInputOnBlur', () {
    test('formats controller text only when focus is lost', () {
      final controller = TextEditingController(text: '1000');
      applyFixedDecimalInputOnBlur(controller, fractionDigits: 2);
      expect(controller.text, '1000.00');
    });

    test('uses emptyBlurText for empty values', () {
      final controller = TextEditingController();
      applyFixedDecimalInputOnBlur(
        controller,
        fractionDigits: 2,
        emptyBlurText: '0.00',
      );
      expect(controller.text, '0.00');
    });
  });
}
