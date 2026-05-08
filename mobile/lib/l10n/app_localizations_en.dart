// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Compartarenta';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonFinishSetup => 'Finish setup';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRestart => 'Restart';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Change the app language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get settingsProfileTitle => 'Profile';

  @override
  String get settingsCurrencyTitle => 'Currency';

  @override
  String get settingsDateFormatTitle => 'Date format';

  @override
  String get settingsDistanceUnitTitle => 'Distance unit';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy policy';

  @override
  String get settingsAppVersionTitle => 'App version';

  @override
  String get settingsEnvironmentTitle => 'Environment';

  @override
  String get settingsApiBaseUrlTitle => 'API base URL';

  @override
  String get onboardingTitle => 'Setup';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeCopy =>
      'Thanks for trying Compartarenta.\\n\\nIn the next steps, you’ll configure your sharing plan(s) (shared housing, car sharing, or both) and start a 6‑week real‑mode trial.\\n\\nYour data stays on your device—this app does not collect it.\\n\\nIf these conditions don’t work for you, you can uninstall at any time.';

  @override
  String get onboardingPlansTitle => 'What do you want to set up?';

  @override
  String get onboardingPlanHousingTitle => 'Shared housing';

  @override
  String get onboardingPlanHousingSubtitle =>
      'Shared rent and household expenses.';

  @override
  String get onboardingPlanCarSharingTitle => 'Car sharing';

  @override
  String get onboardingPlanCarSharingSubtitle =>
      'Track usage, fuel, maintenance, violations, and reservations.';

  @override
  String get onboardingProfileTitle => 'Your profile';

  @override
  String get onboardingNameLabel => 'Name';

  @override
  String get onboardingNameHint => 'Your display name';

  @override
  String get onboardingAvatarTitle => 'Choose an avatar';

  @override
  String get onboardingPreferencesTitle => 'Preferences';

  @override
  String get prefsCurrencyLabel => 'Currency';

  @override
  String get prefsDateFormatLabel => 'Date format';

  @override
  String get prefsDistanceUnitLabel => 'Distance unit';

  @override
  String get prefsDistanceUnitKm => 'Kilometers (km)';

  @override
  String get prefsDistanceUnitMiles => 'Miles';

  @override
  String get prefsTimeZoneLabel => 'Time zone';

  @override
  String get prefsTimeZoneDevice => 'Use device local time';

  @override
  String get prefsTimeZoneExplicit => 'Choose a specific time zone (later)';

  @override
  String get errorSomethingWentWrongTitle => 'Something went wrong';

  @override
  String get errorSomethingWentWrongBody =>
      'Please try again. If this keeps happening, contact support.';

  @override
  String get errorUnknownOnboardingStep => 'Unknown onboarding step.';

  @override
  String homeEnvironment(String env) {
    return 'Environment: $env';
  }

  @override
  String homeApiBaseUrl(String url) {
    return 'API base URL: $url';
  }

  @override
  String get homePlaceholderBody =>
      'This is a placeholder home screen for the store-publishable MVP shell.';
}
