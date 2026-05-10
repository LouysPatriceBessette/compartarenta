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
  String get onboardingLanguageTitle => 'Language';

  @override
  String get onboardingLanguageBody =>
      'Choose the app language. You can change it anytime in Settings.';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeCopyShort =>
      'Thanks for trying Compartarenta.\n\nThe app is free as long as it isn’t actively used. During this phase, you can configure your expense-sharing plan as precisely as you need. This plan will serve as a proposed agreement to share with one or more people.\n\nOnce your plan is accepted and put into service, the 6‑week free trial begins.';

  @override
  String get onboardingReadLater => 'Read later';

  @override
  String get onboardingWelcomeMoreTitle => 'About the trial and license';

  @override
  String get onboardingWelcomeCopyLong =>
      'At the end of the trial, you and your partners can choose to continue by purchasing a \$4 license per person. Each participant in the plan must have a license.\n\nThis license funds development and maintenance. There will NEVER be ads in the app.\n\nYour data is not used in any way: it stays on your device (and the participants’ devices) and nowhere else. The data belongs to you.\n\nIf you don’t renew the license, you won’t be able to add new data, but you will be able to export existing data.';

  @override
  String get onboardingOk => 'OK';

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
  String get prefsCurrencySearchHint => 'Search by code or name';

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
  String get homeHousingPlan => 'Housing plan';

  @override
  String get housingPlanSummaryMonthlyTotal => 'Monthly total';

  @override
  String get homeCarSharingPlan => 'Car sharing plan';

  @override
  String get homePlaceholderBody =>
      'This is a placeholder home screen for the store-publishable MVP shell.';
}
