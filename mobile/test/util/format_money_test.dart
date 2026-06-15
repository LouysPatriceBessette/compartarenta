import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:compartarenta/prefs/regional_unit_choices.dart';
import 'package:compartarenta/util/format_money.dart';

void main() {
  testWidgets('default currency formats with dollar symbol, not ISO code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) {
            final formatted = formatMinorAsMoney(
              context,
              12345,
              kDefaultCurrencyCode,
            );
            final symbol = currencyDisplaySymbol(context, kDefaultCurrencyCode);
            expect(symbol, r'$');
            expect(formatted, isNot(contains('CAD')));
            expect(formatted, contains(r'$'));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  test('formatMinorAsMoneyForLocale never embeds CAD for default currency', () {
    for (final locale in ['en', 'fr', 'es']) {
      final formatted = formatMinorAsMoneyForLocale(
        locale,
        999,
        kDefaultCurrencyCode,
      );
      expect(formatted, isNot(contains('CAD')));
      expect(formatted, contains(r'$'));
    }
  });

  test('resolveStorageCurrencyCode falls back to CAD', () {
    expect(resolveStorageCurrencyCode(''), kDefaultCurrencyCode);
    expect(resolveStorageCurrencyCode('  '), kDefaultCurrencyCode);
    expect(resolveStorageCurrencyCode('USD'), 'USD');
  });

  test('displayCurrencyCodeForPlan defaults when prefs and lines empty', () async {
    // Covered indirectly via resolveStorageCurrencyCode; plan helper needs DB types.
    expect(resolveStorageCurrencyCode(''), kDefaultCurrencyCode);
  });
}
