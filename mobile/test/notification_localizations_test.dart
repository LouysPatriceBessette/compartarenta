import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/notifications/notification_localizations.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('l10nForNotificationLocale', () {
    test('uses in-app language override over device locale', () async {
      SharedPreferences.setMockInitialValues({
        'prefs.languageCode': 'es',
      });
      final prefs = await AppPreferences.load();

      final l10n = l10nForNotificationLocale(prefs: prefs);

      expect(
        l10n.pushNotificationHousingDecisionTitle,
        lookupAppLocalizations(const Locale('es'))
            .pushNotificationHousingDecisionTitle,
      );
      expect(
        l10n.pushNotificationHousingDecisionTitle,
        isNot(
          lookupAppLocalizations(const Locale('fr'))
              .pushNotificationHousingDecisionTitle,
        ),
      );
    });

    testWidgets('falls back to device locale when override is unset', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.load();

      tester.platformDispatcher.localeTestValue = const Locale('es');
      addTearDown(() {
        tester.platformDispatcher.localeTestValue = const Locale('en');
      });

      final l10n = l10nForNotificationLocale(prefs: prefs);

      expect(
        l10n.pushNotificationHousingDecisionTitle,
        lookupAppLocalizations(const Locale('es'))
            .pushNotificationHousingDecisionTitle,
      );
    });
  });

  group('supportedNotificationLanguageCode', () {
    test('maps unsupported codes to English', () {
      expect(supportedNotificationLanguageCode('de'), 'en');
      expect(supportedNotificationLanguageCode('fr'), 'fr');
      expect(supportedNotificationLanguageCode('es'), 'es');
    });
  });
}
