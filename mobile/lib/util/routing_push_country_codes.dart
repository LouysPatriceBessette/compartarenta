/// ISO 3166-1 alpha-2 codes offered when the user opts into country statistics
/// disclosure for routing push registration (relay stores the choice only).
///
/// Coverage: every UN-member sovereign state in North America, Central America,
/// the Caribbean, South America and Europe (Wikipedia, May 2026), every
/// populated dependent territory in those regions that owns an ISO 3166-1
/// alpha-2 code (real usage location, not political ownership), plus a
/// curated set of additional markets kept from the earlier list (AU, JP, KR,
/// IN, ZA, …). Each entry ships a fixed translation table for the locales
/// supported by the app (`en`, `fr`, `es`). Only display labels are localized;
/// codes are kept stable. See
/// `widgets/routing_push_country_picker_sheet.dart` for the searchable
/// combobox UI built on top of this list.
class SupportedRoutingPushCountry {
  const SupportedRoutingPushCountry({
    required this.code,
    required this.nameEn,
    required this.nameFr,
    required this.nameEs,
  });

  /// ISO 3166-1 alpha-2 code (uppercase, exactly two letters).
  final String code;

  /// Localized country name shown in the picker.
  final String nameEn;
  final String nameFr;
  final String nameEs;

  String displayName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return nameFr;
      case 'es':
        return nameEs;
      default:
        return nameEn;
    }
  }

  /// Lowercase, diacritic-stripped form of the localized name. Used for
  /// case- and accent-insensitive sorting and filtering in every supported
  /// locale, e.g.:
  ///   - fr  "États-Unis" → "etats-unis"   (sorts under E, matches "etats")
  ///   - es  "España"     → "espana"       (sorts under E, matches "espana")
  ///   - es  "Perú"       → "peru"         (sorts under P, matches "peru")
  ///   - fr  "Brésil"     → "bresil"       (matches "bresil" and "brésil")
  String foldedName(String languageCode) =>
      foldRoutingPushCountryKey(displayName(languageCode));

  bool matchesQuery(String query, String languageCode) {
    final q = foldRoutingPushCountryKey(query.trim());
    if (q.isEmpty) return true;
    if (code.toLowerCase().contains(q)) return true;
    if (foldedName(languageCode).contains(q)) return true;
    return false;
  }
}

/// Lowercases the input and strips Latin-1 / Latin Extended diacritics so the
/// resulting key collates as if no accents were present. Kept inline (no extra
/// dependency) because the set of characters in our localized labels is small
/// and stable. Anything not in the map passes through unchanged.
String foldRoutingPushCountryKey(String input) {
  if (input.isEmpty) return '';
  final buf = StringBuffer();
  for (final rune in input.runes) {
    final replacement = _diacriticFoldMap[rune];
    if (replacement != null) {
      buf.write(replacement);
    } else if (rune < 0x80) {
      buf.writeCharCode(_asciiLower(rune));
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

int _asciiLower(int codeUnit) {
  if (codeUnit >= 0x41 && codeUnit <= 0x5A) return codeUnit + 0x20;
  return codeUnit;
}

const Map<int, String> _diacriticFoldMap = <int, String>{
  // A / a
  0x00C0: 'a', 0x00C1: 'a', 0x00C2: 'a', 0x00C3: 'a', 0x00C4: 'a', 0x00C5: 'a',
  0x00E0: 'a', 0x00E1: 'a', 0x00E2: 'a', 0x00E3: 'a', 0x00E4: 'a', 0x00E5: 'a',
  // AE / ae
  0x00C6: 'ae', 0x00E6: 'ae',
  // C / c
  0x00C7: 'c', 0x00E7: 'c',
  // E / e
  0x00C8: 'e', 0x00C9: 'e', 0x00CA: 'e', 0x00CB: 'e',
  0x00E8: 'e', 0x00E9: 'e', 0x00EA: 'e', 0x00EB: 'e',
  // I / i
  0x00CC: 'i', 0x00CD: 'i', 0x00CE: 'i', 0x00CF: 'i',
  0x00EC: 'i', 0x00ED: 'i', 0x00EE: 'i', 0x00EF: 'i',
  0x0130: 'i', 0x0131: 'i',
  // N / n
  0x00D1: 'n', 0x00F1: 'n',
  // O / o
  0x00D2: 'o', 0x00D3: 'o', 0x00D4: 'o', 0x00D5: 'o', 0x00D6: 'o', 0x00D8: 'o',
  0x00F2: 'o', 0x00F3: 'o', 0x00F4: 'o', 0x00F5: 'o', 0x00F6: 'o', 0x00F8: 'o',
  // OE / oe
  0x0152: 'oe', 0x0153: 'oe',
  // S / s
  0x015A: 's', 0x015B: 's', 0x015E: 's', 0x015F: 's', 0x0160: 's', 0x0161: 's',
  0x017F: 's',
  // U / u
  0x00D9: 'u', 0x00DA: 'u', 0x00DB: 'u', 0x00DC: 'u',
  0x00F9: 'u', 0x00FA: 'u', 0x00FB: 'u', 0x00FC: 'u',
  // Y / y
  0x00DD: 'y', 0x0178: 'y', 0x00FD: 'y', 0x00FF: 'y',
  // ß
  0x00DF: 'ss',
};

/// Alphabetized by ISO code so updates remain auditable.
const List<SupportedRoutingPushCountry> kRoutingPushSupportedCountries =
    <SupportedRoutingPushCountry>[
  SupportedRoutingPushCountry(
    code: 'AD',
    nameEn: 'Andorra',
    nameFr: 'Andorre',
    nameEs: 'Andorra',
  ),
  SupportedRoutingPushCountry(
    code: 'AG',
    nameEn: 'Antigua and Barbuda',
    nameFr: 'Antigua-et-Barbuda',
    nameEs: 'Antigua y Barbuda',
  ),
  SupportedRoutingPushCountry(
    code: 'AI',
    nameEn: 'Anguilla',
    nameFr: 'Anguilla',
    nameEs: 'Anguila',
  ),
  SupportedRoutingPushCountry(
    code: 'AL',
    nameEn: 'Albania',
    nameFr: 'Albanie',
    nameEs: 'Albania',
  ),
  SupportedRoutingPushCountry(
    code: 'AM',
    nameEn: 'Armenia',
    nameFr: 'Arménie',
    nameEs: 'Armenia',
  ),
  SupportedRoutingPushCountry(
    code: 'AR',
    nameEn: 'Argentina',
    nameFr: 'Argentine',
    nameEs: 'Argentina',
  ),
  SupportedRoutingPushCountry(
    code: 'AT',
    nameEn: 'Austria',
    nameFr: 'Autriche',
    nameEs: 'Austria',
  ),
  SupportedRoutingPushCountry(
    code: 'AU',
    nameEn: 'Australia',
    nameFr: 'Australie',
    nameEs: 'Australia',
  ),
  SupportedRoutingPushCountry(
    code: 'AW',
    nameEn: 'Aruba',
    nameFr: 'Aruba',
    nameEs: 'Aruba',
  ),
  SupportedRoutingPushCountry(
    code: 'AX',
    nameEn: 'Åland Islands',
    nameFr: 'Îles Åland',
    nameEs: 'Islas Åland',
  ),
  SupportedRoutingPushCountry(
    code: 'AZ',
    nameEn: 'Azerbaijan',
    nameFr: 'Azerbaïdjan',
    nameEs: 'Azerbaiyán',
  ),
  SupportedRoutingPushCountry(
    code: 'BA',
    nameEn: 'Bosnia and Herzegovina',
    nameFr: 'Bosnie-Herzégovine',
    nameEs: 'Bosnia y Herzegovina',
  ),
  SupportedRoutingPushCountry(
    code: 'BB',
    nameEn: 'Barbados',
    nameFr: 'Barbade',
    nameEs: 'Barbados',
  ),
  SupportedRoutingPushCountry(
    code: 'BE',
    nameEn: 'Belgium',
    nameFr: 'Belgique',
    nameEs: 'Bélgica',
  ),
  SupportedRoutingPushCountry(
    code: 'BG',
    nameEn: 'Bulgaria',
    nameFr: 'Bulgarie',
    nameEs: 'Bulgaria',
  ),
  SupportedRoutingPushCountry(
    code: 'BL',
    nameEn: 'Saint Barthélemy',
    nameFr: 'Saint-Barthélemy',
    nameEs: 'San Bartolomé',
  ),
  SupportedRoutingPushCountry(
    code: 'BM',
    nameEn: 'Bermuda',
    nameFr: 'Bermudes',
    nameEs: 'Bermudas',
  ),
  SupportedRoutingPushCountry(
    code: 'BO',
    nameEn: 'Bolivia',
    nameFr: 'Bolivie',
    nameEs: 'Bolivia',
  ),
  SupportedRoutingPushCountry(
    code: 'BQ',
    nameEn: 'Bonaire, Sint Eustatius and Saba',
    nameFr: 'Bonaire, Saint-Eustache et Saba',
    nameEs: 'Bonaire, San Eustaquio y Saba',
  ),
  SupportedRoutingPushCountry(
    code: 'BR',
    nameEn: 'Brazil',
    nameFr: 'Brésil',
    nameEs: 'Brasil',
  ),
  SupportedRoutingPushCountry(
    code: 'BS',
    nameEn: 'Bahamas',
    nameFr: 'Bahamas',
    nameEs: 'Bahamas',
  ),
  SupportedRoutingPushCountry(
    code: 'BY',
    nameEn: 'Belarus',
    nameFr: 'Biélorussie',
    nameEs: 'Bielorrusia',
  ),
  SupportedRoutingPushCountry(
    code: 'BZ',
    nameEn: 'Belize',
    nameFr: 'Bélize',
    nameEs: 'Belice',
  ),
  SupportedRoutingPushCountry(
    code: 'CA',
    nameEn: 'Canada',
    nameFr: 'Canada',
    nameEs: 'Canadá',
  ),
  SupportedRoutingPushCountry(
    code: 'CH',
    nameEn: 'Switzerland',
    nameFr: 'Suisse',
    nameEs: 'Suiza',
  ),
  SupportedRoutingPushCountry(
    code: 'CL',
    nameEn: 'Chile',
    nameFr: 'Chili',
    nameEs: 'Chile',
  ),
  SupportedRoutingPushCountry(
    code: 'CN',
    nameEn: 'China',
    nameFr: 'Chine',
    nameEs: 'China',
  ),
  SupportedRoutingPushCountry(
    code: 'CO',
    nameEn: 'Colombia',
    nameFr: 'Colombie',
    nameEs: 'Colombia',
  ),
  SupportedRoutingPushCountry(
    code: 'CR',
    nameEn: 'Costa Rica',
    nameFr: 'Costa Rica',
    nameEs: 'Costa Rica',
  ),
  SupportedRoutingPushCountry(
    code: 'CU',
    nameEn: 'Cuba',
    nameFr: 'Cuba',
    nameEs: 'Cuba',
  ),
  SupportedRoutingPushCountry(
    code: 'CW',
    nameEn: 'Curaçao',
    nameFr: 'Curaçao',
    nameEs: 'Curazao',
  ),
  SupportedRoutingPushCountry(
    code: 'CY',
    nameEn: 'Cyprus',
    nameFr: 'Chypre',
    nameEs: 'Chipre',
  ),
  SupportedRoutingPushCountry(
    code: 'CZ',
    nameEn: 'Czechia',
    nameFr: 'Tchéquie',
    nameEs: 'Chequia',
  ),
  SupportedRoutingPushCountry(
    code: 'DE',
    nameEn: 'Germany',
    nameFr: 'Allemagne',
    nameEs: 'Alemania',
  ),
  SupportedRoutingPushCountry(
    code: 'DK',
    nameEn: 'Denmark',
    nameFr: 'Danemark',
    nameEs: 'Dinamarca',
  ),
  SupportedRoutingPushCountry(
    code: 'DM',
    nameEn: 'Dominica',
    nameFr: 'Dominique',
    nameEs: 'Dominica',
  ),
  SupportedRoutingPushCountry(
    code: 'DO',
    nameEn: 'Dominican Republic',
    nameFr: 'République dominicaine',
    nameEs: 'República Dominicana',
  ),
  SupportedRoutingPushCountry(
    code: 'EC',
    nameEn: 'Ecuador',
    nameFr: 'Équateur',
    nameEs: 'Ecuador',
  ),
  SupportedRoutingPushCountry(
    code: 'EE',
    nameEn: 'Estonia',
    nameFr: 'Estonie',
    nameEs: 'Estonia',
  ),
  SupportedRoutingPushCountry(
    code: 'ES',
    nameEn: 'Spain',
    nameFr: 'Espagne',
    nameEs: 'España',
  ),
  SupportedRoutingPushCountry(
    code: 'FI',
    nameEn: 'Finland',
    nameFr: 'Finlande',
    nameEs: 'Finlandia',
  ),
  SupportedRoutingPushCountry(
    code: 'FK',
    nameEn: 'Falkland Islands',
    nameFr: 'Îles Malouines',
    nameEs: 'Islas Malvinas',
  ),
  SupportedRoutingPushCountry(
    code: 'FO',
    nameEn: 'Faroe Islands',
    nameFr: 'Îles Féroé',
    nameEs: 'Islas Feroe',
  ),
  SupportedRoutingPushCountry(
    code: 'FR',
    nameEn: 'France',
    nameFr: 'France',
    nameEs: 'Francia',
  ),
  SupportedRoutingPushCountry(
    code: 'GB',
    nameEn: 'United Kingdom',
    nameFr: 'Royaume-Uni',
    nameEs: 'Reino Unido',
  ),
  SupportedRoutingPushCountry(
    code: 'GD',
    nameEn: 'Grenada',
    nameFr: 'Grenade',
    nameEs: 'Granada',
  ),
  SupportedRoutingPushCountry(
    code: 'GE',
    nameEn: 'Georgia',
    nameFr: 'Géorgie',
    nameEs: 'Georgia',
  ),
  SupportedRoutingPushCountry(
    code: 'GF',
    nameEn: 'French Guiana',
    nameFr: 'Guyane française',
    nameEs: 'Guayana Francesa',
  ),
  SupportedRoutingPushCountry(
    code: 'GG',
    nameEn: 'Guernsey',
    nameFr: 'Guernesey',
    nameEs: 'Guernsey',
  ),
  SupportedRoutingPushCountry(
    code: 'GI',
    nameEn: 'Gibraltar',
    nameFr: 'Gibraltar',
    nameEs: 'Gibraltar',
  ),
  SupportedRoutingPushCountry(
    code: 'GL',
    nameEn: 'Greenland',
    nameFr: 'Groenland',
    nameEs: 'Groenlandia',
  ),
  SupportedRoutingPushCountry(
    code: 'GP',
    nameEn: 'Guadeloupe',
    nameFr: 'Guadeloupe',
    nameEs: 'Guadalupe',
  ),
  SupportedRoutingPushCountry(
    code: 'GR',
    nameEn: 'Greece',
    nameFr: 'Grèce',
    nameEs: 'Grecia',
  ),
  SupportedRoutingPushCountry(
    code: 'GT',
    nameEn: 'Guatemala',
    nameFr: 'Guatemala',
    nameEs: 'Guatemala',
  ),
  SupportedRoutingPushCountry(
    code: 'GY',
    nameEn: 'Guyana',
    nameFr: 'Guyana',
    nameEs: 'Guyana',
  ),
  SupportedRoutingPushCountry(
    code: 'HK',
    nameEn: 'Hong Kong',
    nameFr: 'Hong Kong',
    nameEs: 'Hong Kong',
  ),
  SupportedRoutingPushCountry(
    code: 'HN',
    nameEn: 'Honduras',
    nameFr: 'Honduras',
    nameEs: 'Honduras',
  ),
  SupportedRoutingPushCountry(
    code: 'HR',
    nameEn: 'Croatia',
    nameFr: 'Croatie',
    nameEs: 'Croacia',
  ),
  SupportedRoutingPushCountry(
    code: 'HT',
    nameEn: 'Haiti',
    nameFr: 'Haïti',
    nameEs: 'Haití',
  ),
  SupportedRoutingPushCountry(
    code: 'HU',
    nameEn: 'Hungary',
    nameFr: 'Hongrie',
    nameEs: 'Hungría',
  ),
  SupportedRoutingPushCountry(
    code: 'ID',
    nameEn: 'Indonesia',
    nameFr: 'Indonésie',
    nameEs: 'Indonesia',
  ),
  SupportedRoutingPushCountry(
    code: 'IE',
    nameEn: 'Ireland',
    nameFr: 'Irlande',
    nameEs: 'Irlanda',
  ),
  SupportedRoutingPushCountry(
    code: 'IL',
    nameEn: 'Israel',
    nameFr: 'Israël',
    nameEs: 'Israel',
  ),
  SupportedRoutingPushCountry(
    code: 'IM',
    nameEn: 'Isle of Man',
    nameFr: 'Île de Man',
    nameEs: 'Isla de Man',
  ),
  SupportedRoutingPushCountry(
    code: 'IN',
    nameEn: 'India',
    nameFr: 'Inde',
    nameEs: 'India',
  ),
  SupportedRoutingPushCountry(
    code: 'IS',
    nameEn: 'Iceland',
    nameFr: 'Islande',
    nameEs: 'Islandia',
  ),
  SupportedRoutingPushCountry(
    code: 'IT',
    nameEn: 'Italy',
    nameFr: 'Italie',
    nameEs: 'Italia',
  ),
  SupportedRoutingPushCountry(
    code: 'JE',
    nameEn: 'Jersey',
    nameFr: 'Jersey',
    nameEs: 'Jersey',
  ),
  SupportedRoutingPushCountry(
    code: 'JM',
    nameEn: 'Jamaica',
    nameFr: 'Jamaïque',
    nameEs: 'Jamaica',
  ),
  SupportedRoutingPushCountry(
    code: 'JP',
    nameEn: 'Japan',
    nameFr: 'Japon',
    nameEs: 'Japón',
  ),
  SupportedRoutingPushCountry(
    code: 'KN',
    nameEn: 'Saint Kitts and Nevis',
    nameFr: 'Saint-Kitts-et-Nevis',
    nameEs: 'San Cristóbal y Nieves',
  ),
  SupportedRoutingPushCountry(
    code: 'KR',
    nameEn: 'South Korea',
    nameFr: 'Corée du Sud',
    nameEs: 'Corea del Sur',
  ),
  SupportedRoutingPushCountry(
    code: 'KY',
    nameEn: 'Cayman Islands',
    nameFr: 'Îles Caïmans',
    nameEs: 'Islas Caimán',
  ),
  SupportedRoutingPushCountry(
    code: 'KZ',
    nameEn: 'Kazakhstan',
    nameFr: 'Kazakhstan',
    nameEs: 'Kazajistán',
  ),
  SupportedRoutingPushCountry(
    code: 'LC',
    nameEn: 'Saint Lucia',
    nameFr: 'Sainte-Lucie',
    nameEs: 'Santa Lucía',
  ),
  SupportedRoutingPushCountry(
    code: 'LI',
    nameEn: 'Liechtenstein',
    nameFr: 'Liechtenstein',
    nameEs: 'Liechtenstein',
  ),
  SupportedRoutingPushCountry(
    code: 'LT',
    nameEn: 'Lithuania',
    nameFr: 'Lituanie',
    nameEs: 'Lituania',
  ),
  SupportedRoutingPushCountry(
    code: 'LU',
    nameEn: 'Luxembourg',
    nameFr: 'Luxembourg',
    nameEs: 'Luxemburgo',
  ),
  SupportedRoutingPushCountry(
    code: 'LV',
    nameEn: 'Latvia',
    nameFr: 'Lettonie',
    nameEs: 'Letonia',
  ),
  SupportedRoutingPushCountry(
    code: 'MC',
    nameEn: 'Monaco',
    nameFr: 'Monaco',
    nameEs: 'Mónaco',
  ),
  SupportedRoutingPushCountry(
    code: 'MD',
    nameEn: 'Moldova',
    nameFr: 'Moldavie',
    nameEs: 'Moldavia',
  ),
  SupportedRoutingPushCountry(
    code: 'ME',
    nameEn: 'Montenegro',
    nameFr: 'Monténégro',
    nameEs: 'Montenegro',
  ),
  SupportedRoutingPushCountry(
    code: 'MF',
    nameEn: 'Saint Martin (French part)',
    nameFr: 'Saint-Martin (partie française)',
    nameEs: 'San Martín (parte francesa)',
  ),
  SupportedRoutingPushCountry(
    code: 'MK',
    nameEn: 'North Macedonia',
    nameFr: 'Macédoine du Nord',
    nameEs: 'Macedonia del Norte',
  ),
  SupportedRoutingPushCountry(
    code: 'MQ',
    nameEn: 'Martinique',
    nameFr: 'Martinique',
    nameEs: 'Martinica',
  ),
  SupportedRoutingPushCountry(
    code: 'MS',
    nameEn: 'Montserrat',
    nameFr: 'Montserrat',
    nameEs: 'Montserrat',
  ),
  SupportedRoutingPushCountry(
    code: 'MT',
    nameEn: 'Malta',
    nameFr: 'Malte',
    nameEs: 'Malta',
  ),
  SupportedRoutingPushCountry(
    code: 'MX',
    nameEn: 'Mexico',
    nameFr: 'Mexique',
    nameEs: 'México',
  ),
  SupportedRoutingPushCountry(
    code: 'MY',
    nameEn: 'Malaysia',
    nameFr: 'Malaisie',
    nameEs: 'Malasia',
  ),
  SupportedRoutingPushCountry(
    code: 'NI',
    nameEn: 'Nicaragua',
    nameFr: 'Nicaragua',
    nameEs: 'Nicaragua',
  ),
  SupportedRoutingPushCountry(
    code: 'NL',
    nameEn: 'Netherlands',
    nameFr: 'Pays-Bas',
    nameEs: 'Países Bajos',
  ),
  SupportedRoutingPushCountry(
    code: 'NO',
    nameEn: 'Norway',
    nameFr: 'Norvège',
    nameEs: 'Noruega',
  ),
  SupportedRoutingPushCountry(
    code: 'NZ',
    nameEn: 'New Zealand',
    nameFr: 'Nouvelle-Zélande',
    nameEs: 'Nueva Zelanda',
  ),
  SupportedRoutingPushCountry(
    code: 'PA',
    nameEn: 'Panama',
    nameFr: 'Panama',
    nameEs: 'Panamá',
  ),
  SupportedRoutingPushCountry(
    code: 'PE',
    nameEn: 'Peru',
    nameFr: 'Pérou',
    nameEs: 'Perú',
  ),
  SupportedRoutingPushCountry(
    code: 'PH',
    nameEn: 'Philippines',
    nameFr: 'Philippines',
    nameEs: 'Filipinas',
  ),
  SupportedRoutingPushCountry(
    code: 'PL',
    nameEn: 'Poland',
    nameFr: 'Pologne',
    nameEs: 'Polonia',
  ),
  SupportedRoutingPushCountry(
    code: 'PM',
    nameEn: 'Saint Pierre and Miquelon',
    nameFr: 'Saint-Pierre-et-Miquelon',
    nameEs: 'San Pedro y Miquelón',
  ),
  SupportedRoutingPushCountry(
    code: 'PR',
    nameEn: 'Puerto Rico',
    nameFr: 'Porto Rico',
    nameEs: 'Puerto Rico',
  ),
  SupportedRoutingPushCountry(
    code: 'PT',
    nameEn: 'Portugal',
    nameFr: 'Portugal',
    nameEs: 'Portugal',
  ),
  SupportedRoutingPushCountry(
    code: 'PY',
    nameEn: 'Paraguay',
    nameFr: 'Paraguay',
    nameEs: 'Paraguay',
  ),
  SupportedRoutingPushCountry(
    code: 'RO',
    nameEn: 'Romania',
    nameFr: 'Roumanie',
    nameEs: 'Rumania',
  ),
  SupportedRoutingPushCountry(
    code: 'RS',
    nameEn: 'Serbia',
    nameFr: 'Serbie',
    nameEs: 'Serbia',
  ),
  SupportedRoutingPushCountry(
    code: 'RU',
    nameEn: 'Russia',
    nameFr: 'Russie',
    nameEs: 'Rusia',
  ),
  SupportedRoutingPushCountry(
    code: 'SA',
    nameEn: 'Saudi Arabia',
    nameFr: 'Arabie saoudite',
    nameEs: 'Arabia Saudita',
  ),
  SupportedRoutingPushCountry(
    code: 'SE',
    nameEn: 'Sweden',
    nameFr: 'Suède',
    nameEs: 'Suecia',
  ),
  SupportedRoutingPushCountry(
    code: 'SG',
    nameEn: 'Singapore',
    nameFr: 'Singapour',
    nameEs: 'Singapur',
  ),
  SupportedRoutingPushCountry(
    code: 'SI',
    nameEn: 'Slovenia',
    nameFr: 'Slovénie',
    nameEs: 'Eslovenia',
  ),
  SupportedRoutingPushCountry(
    code: 'SJ',
    nameEn: 'Svalbard and Jan Mayen',
    nameFr: 'Svalbard et Jan Mayen',
    nameEs: 'Svalbard y Jan Mayen',
  ),
  SupportedRoutingPushCountry(
    code: 'SK',
    nameEn: 'Slovakia',
    nameFr: 'Slovaquie',
    nameEs: 'Eslovaquia',
  ),
  SupportedRoutingPushCountry(
    code: 'SM',
    nameEn: 'San Marino',
    nameFr: 'Saint-Marin',
    nameEs: 'San Marino',
  ),
  SupportedRoutingPushCountry(
    code: 'SR',
    nameEn: 'Suriname',
    nameFr: 'Suriname',
    nameEs: 'Surinam',
  ),
  SupportedRoutingPushCountry(
    code: 'SV',
    nameEn: 'El Salvador',
    nameFr: 'Salvador',
    nameEs: 'El Salvador',
  ),
  SupportedRoutingPushCountry(
    code: 'SX',
    nameEn: 'Sint Maarten (Dutch part)',
    nameFr: 'Saint-Martin (partie néerlandaise)',
    nameEs: 'San Martín (parte neerlandesa)',
  ),
  SupportedRoutingPushCountry(
    code: 'TC',
    nameEn: 'Turks and Caicos Islands',
    nameFr: 'Îles Turques-et-Caïques',
    nameEs: 'Islas Turcas y Caicos',
  ),
  SupportedRoutingPushCountry(
    code: 'TH',
    nameEn: 'Thailand',
    nameFr: 'Thaïlande',
    nameEs: 'Tailandia',
  ),
  SupportedRoutingPushCountry(
    code: 'TR',
    nameEn: 'Türkiye',
    nameFr: 'Turquie',
    nameEs: 'Turquía',
  ),
  SupportedRoutingPushCountry(
    code: 'TT',
    nameEn: 'Trinidad and Tobago',
    nameFr: 'Trinité-et-Tobago',
    nameEs: 'Trinidad y Tobago',
  ),
  SupportedRoutingPushCountry(
    code: 'TW',
    nameEn: 'Taiwan',
    nameFr: 'Taïwan',
    nameEs: 'Taiwán',
  ),
  SupportedRoutingPushCountry(
    code: 'UA',
    nameEn: 'Ukraine',
    nameFr: 'Ukraine',
    nameEs: 'Ucrania',
  ),
  SupportedRoutingPushCountry(
    code: 'US',
    nameEn: 'United States',
    nameFr: 'États-Unis',
    nameEs: 'Estados Unidos',
  ),
  SupportedRoutingPushCountry(
    code: 'UY',
    nameEn: 'Uruguay',
    nameFr: 'Uruguay',
    nameEs: 'Uruguay',
  ),
  SupportedRoutingPushCountry(
    code: 'VA',
    nameEn: 'Vatican City',
    nameFr: 'Vatican',
    nameEs: 'Ciudad del Vaticano',
  ),
  SupportedRoutingPushCountry(
    code: 'VC',
    nameEn: 'Saint Vincent and the Grenadines',
    nameFr: 'Saint-Vincent-et-les-Grenadines',
    nameEs: 'San Vicente y las Granadinas',
  ),
  SupportedRoutingPushCountry(
    code: 'VE',
    nameEn: 'Venezuela',
    nameFr: 'Venezuela',
    nameEs: 'Venezuela',
  ),
  SupportedRoutingPushCountry(
    code: 'VG',
    nameEn: 'British Virgin Islands',
    nameFr: 'Îles Vierges britanniques',
    nameEs: 'Islas Vírgenes Británicas',
  ),
  SupportedRoutingPushCountry(
    code: 'VI',
    nameEn: 'U.S. Virgin Islands',
    nameFr: 'Îles Vierges des États-Unis',
    nameEs: 'Islas Vírgenes de los Estados Unidos',
  ),
  SupportedRoutingPushCountry(
    code: 'VN',
    nameEn: 'Vietnam',
    nameFr: 'Vietnam',
    nameEs: 'Vietnam',
  ),
  SupportedRoutingPushCountry(
    code: 'ZA',
    nameEn: 'South Africa',
    nameFr: 'Afrique du Sud',
    nameEs: 'Sudáfrica',
  ),
];

SupportedRoutingPushCountry? supportedRoutingPushCountryByCode(String code) {
  final upper = code.trim().toUpperCase();
  for (final c in kRoutingPushSupportedCountries) {
    if (c.code == upper) return c;
  }
  return null;
}
