import 'package:compartarenta/util/routing_push_country_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldRoutingPushCountryKey', () {
    test('lowercases ASCII letters', () {
      expect(foldRoutingPushCountryKey('Canada'), 'canada');
      expect(foldRoutingPushCountryKey('UNITED KINGDOM'), 'united kingdom');
    });

    test('folds French diacritics', () {
      expect(foldRoutingPushCountryKey('États-Unis'), 'etats-unis');
      expect(foldRoutingPushCountryKey('Brésil'), 'bresil');
      expect(foldRoutingPushCountryKey('Pérou'), 'perou');
      expect(foldRoutingPushCountryKey('Îles Féroé'), 'iles feroe');
      expect(foldRoutingPushCountryKey('Curaçao'), 'curacao');
      expect(foldRoutingPushCountryKey('Türkiye'), 'turkiye');
    });

    test('folds Spanish diacritics (á é í ó ú ñ)', () {
      expect(foldRoutingPushCountryKey('España'), 'espana');
      expect(foldRoutingPushCountryKey('Perú'), 'peru');
      expect(foldRoutingPushCountryKey('México'), 'mexico');
      expect(foldRoutingPushCountryKey('Panamá'), 'panama');
      expect(foldRoutingPushCountryKey('Bélgica'), 'belgica');
      expect(foldRoutingPushCountryKey('Hungría'), 'hungria');
      expect(foldRoutingPushCountryKey('Islas Caimán'), 'islas caiman');
      expect(foldRoutingPushCountryKey('Türkiye'), 'turkiye');
    });

    test('makes query matching accent-insensitive in any locale', () {
      final es = kRoutingPushSupportedCountries.firstWhere(
        (c) => c.code == 'ES',
      );
      expect(es.matchesQuery('espana', 'es'), isTrue);
      expect(es.matchesQuery('ESPAÑA', 'es'), isTrue);
      expect(es.matchesQuery('España', 'es'), isTrue);

      final mx = kRoutingPushSupportedCountries.firstWhere(
        (c) => c.code == 'MX',
      );
      expect(mx.matchesQuery('mexico', 'es'), isTrue);
      expect(mx.matchesQuery('méxico', 'es'), isTrue);

      final fr = kRoutingPushSupportedCountries.firstWhere(
        (c) => c.code == 'BR',
      );
      expect(fr.matchesQuery('bresil', 'fr'), isTrue);
      expect(fr.matchesQuery('Brésil', 'fr'), isTrue);
    });
  });

  group('SupportedRoutingPushCountry sort by foldedName', () {
    List<String> sortedCodes(String lang) {
      final list = List<SupportedRoutingPushCountry>.of(
        kRoutingPushSupportedCountries,
      )..sort((a, b) => a.foldedName(lang).compareTo(b.foldedName(lang)));
      return list.map((c) => c.code).toList(growable: false);
    }

    test('French: États-Unis sorts under E (next to Espagne, Estonie)', () {
      final codes = sortedCodes('fr');
      final us = codes.indexOf('US');
      final es = codes.indexOf('ES');
      final ee = codes.indexOf('EE');
      final fi = codes.indexOf('FI');
      expect(us, greaterThan(es));
      expect(us, greaterThan(ee));
      expect(us, lessThan(fi));
    });

    test('Spanish: España sorts under E, before Estados Unidos', () {
      final codes = sortedCodes('es');
      final es = codes.indexOf('ES');
      final us = codes.indexOf('US');
      final ec = codes.indexOf('EC');
      final fi = codes.indexOf('FI');
      expect(es, greaterThan(ec));
      expect(es, lessThan(us));
      expect(us, lessThan(fi));
    });

    test('Spanish: Perú sorts under P (before Polonia)', () {
      final codes = sortedCodes('es');
      final pe = codes.indexOf('PE');
      final pl = codes.indexOf('PL');
      final pa = codes.indexOf('PA');
      expect(pe, greaterThan(pa));
      expect(pe, lessThan(pl));
    });

    test('English ordering is independent of fold map', () {
      final codes = sortedCodes('en');
      final ca = codes.indexOf('CA');
      final us = codes.indexOf('US');
      expect(ca, lessThan(us));
    });
  });
}
