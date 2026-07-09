import 'dart:ui';

/// Public legal pages on `compartarenta.incoherences.org`.
const _legalSiteOrigin = 'https://compartarenta.incoherences.org';

/// Locale-aware privacy policy URL (FR / EN / ES paths on the marketing site).
Uri privacyPolicyUrlForLocale(Locale locale) {
  final path = switch (locale.languageCode) {
    'fr' => '/fr/legal/confidentialite/',
    'es' => '/es/legal/confidentialite/',
    _ => '/en/legal/confidentialite/',
  };
  return Uri.parse('$_legalSiteOrigin$path');
}
