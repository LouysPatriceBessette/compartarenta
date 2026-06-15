import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';

/// Resolves [AppLocalizations] for tray notifications on this device.
///
/// Uses the recipient's in-app language ([AppPreferences.languageCode]) when
/// set; otherwise falls back to the device locale (same rule as [MaterialApp]).
AppLocalizations l10nForNotificationLocale({AppPreferences? prefs}) {
  final override = prefs?.languageCode?.trim();
  final languageCode = override != null && override.isNotEmpty
      ? override
      : WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return lookupAppLocalizations(
    Locale(supportedNotificationLanguageCode(languageCode)),
  );
}

/// Maps arbitrary language codes to a supported notification locale.
String supportedNotificationLanguageCode(String code) {
  return switch (code) {
    'fr' || 'es' => code,
    _ => 'en',
  };
}
