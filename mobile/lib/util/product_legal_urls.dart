import 'dart:ui';

/// Public legal / FAQ pages on `bojairu.app`.
const _legalSiteOrigin = 'https://bojairu.app';

/// FAQ fragment ids on the marketing site (must match site `<details id="…">`).
abstract final class ProductFaqAnchors {
  /// Contacts FAQ — duplicate handshake / restore-data refusal.
  static const contactReject = 'reject';

  /// Housing FAQ — cannot invite into an active plan.
  static const housingInviteParticipant = 'housing-invite-participant';

  /// Vehicle FAQ — fuel in tank display.
  static const vehicleFuelTank = 'vehicle-fuel-tank';

  /// Vehicle FAQ — consumption estimation modes.
  static const vehicleConsumptionEstimation = 'vehicle-consumption-estimation';

  /// Vehicle FAQ — ownership transfer export.
  static const vehicleOwnershipExport = 'vehicle-ownership-export';

  /// Vehicle FAQ — ownership transfer import.
  static const vehicleOwnershipImport = 'vehicle-ownership-import';
}

/// Locale-aware privacy policy URL (FR / EN / ES paths on the marketing site).
Uri privacyPolicyUrlForLocale(Locale locale) {
  final path = switch (locale.languageCode) {
    'fr' => '/fr/legal/confidentialite/',
    'es' => '/es/legal/confidentialite/',
    _ => '/en/legal/confidentialite/',
  };
  return Uri.parse('$_legalSiteOrigin$path');
}

Uri _moduleFaqUrl({
  required Locale locale,
  required String frPath,
  required String esPath,
  required String enPath,
  required String fragment,
}) {
  final path = switch (locale.languageCode) {
    'fr' => frPath,
    'es' => esPath,
    _ => enPath,
  };
  return Uri.parse('$_legalSiteOrigin$path#$fragment');
}

/// FAQ anchor for duplicate-contact / restore-data flows (bug 1.22 extension).
Uri contactDuplicateFaqUrlForLocale(Locale locale) {
  return _moduleFaqUrl(
    locale: locale,
    frPath: '/fr/modules/contacts/faq/',
    esPath: '/es/modules/contacts/faq/',
    enPath: '/en/modules/contacts/faq/',
    fragment: ProductFaqAnchors.contactReject,
  );
}

/// Housing module FAQ (invite into active plan / participation change).
Uri housingModuleFaqUrlForLocale(
  Locale locale, {
  String fragment = ProductFaqAnchors.housingInviteParticipant,
}) {
  return _moduleFaqUrl(
    locale: locale,
    frPath: '/fr/modules/logement/faq/',
    esPath: '/es/modules/logement/faq/',
    enPath: '/en/modules/logement/faq/',
    fragment: fragment,
  );
}

/// Vehicle module FAQ (sale export / import, fuel tank, consumption, …).
Uri vehicleModuleFaqUrlForLocale(
  Locale locale, {
  required String fragment,
}) {
  return _moduleFaqUrl(
    locale: locale,
    frPath: '/fr/modules/vehicule/faq/',
    esPath: '/es/modules/vehicule/faq/',
    enPath: '/en/modules/vehicule/faq/',
    fragment: fragment,
  );
}
