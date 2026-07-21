import 'dart:ui';

import 'package:compartarenta/util/product_legal_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacyPolicyUrlForLocale uses FR / EN / ES paths', () {
    expect(
      privacyPolicyUrlForLocale(const Locale('fr')),
      Uri.parse(
        'https://bojairu.app/fr/legal/confidentialite/',
      ),
    );
    expect(
      privacyPolicyUrlForLocale(const Locale('en')),
      Uri.parse(
        'https://bojairu.app/en/legal/confidentialite/',
      ),
    );
    expect(
      privacyPolicyUrlForLocale(const Locale('es')),
      Uri.parse(
        'https://bojairu.app/es/legal/confidentialite/',
      ),
    );
  });

  test('privacyPolicyUrlForLocale falls back to EN', () {
    expect(
      privacyPolicyUrlForLocale(const Locale('de')),
      Uri.parse(
        'https://bojairu.app/en/legal/confidentialite/',
      ),
    );
  });

  test('vehicleModuleFaqUrlForLocale uses FR / EN / ES paths', () {
    expect(
      vehicleModuleFaqUrlForLocale(const Locale('fr')),
      Uri.parse(
        'https://bojairu.app/fr/modules/vehicule/faq/',
      ),
    );
    expect(
      vehicleModuleFaqUrlForLocale(const Locale('en')),
      Uri.parse(
        'https://bojairu.app/en/modules/vehicule/faq/',
      ),
    );
    expect(
      vehicleModuleFaqUrlForLocale(const Locale('es')),
      Uri.parse(
        'https://bojairu.app/es/modules/vehicule/faq/',
      ),
    );
  });
}
