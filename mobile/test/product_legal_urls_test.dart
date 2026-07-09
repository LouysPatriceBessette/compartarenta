import 'dart:ui';

import 'package:compartarenta/util/product_legal_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacyPolicyUrlForLocale uses FR / EN / ES paths', () {
    expect(
      privacyPolicyUrlForLocale(const Locale('fr')),
      Uri.parse(
        'https://compartarenta.incoherences.org/fr/legal/confidentialite/',
      ),
    );
    expect(
      privacyPolicyUrlForLocale(const Locale('en')),
      Uri.parse(
        'https://compartarenta.incoherences.org/en/legal/confidentialite/',
      ),
    );
    expect(
      privacyPolicyUrlForLocale(const Locale('es')),
      Uri.parse(
        'https://compartarenta.incoherences.org/es/legal/confidentialite/',
      ),
    );
  });

  test('privacyPolicyUrlForLocale falls back to EN', () {
    expect(
      privacyPolicyUrlForLocale(const Locale('de')),
      Uri.parse(
        'https://compartarenta.incoherences.org/en/legal/confidentialite/',
      ),
    );
  });
}
