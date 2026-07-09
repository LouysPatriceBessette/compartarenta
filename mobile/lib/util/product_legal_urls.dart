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

/// FAQ anchor for duplicate-contact / restore-data flows (bug 1.22 extension).
Uri contactDuplicateFaqUrlForLocale(Locale locale) {
  final path = switch (locale.languageCode) {
    'fr' => '/fr/modules/contacts/faq/#reject',
    'es' => '/es/modules/contacts/faq/#reject',
    _ => '/en/modules/contacts/faq/#reject',
  };
  return Uri.parse('$_legalSiteOrigin$path');
}
