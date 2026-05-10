import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Compartarenta'**
  String get appTitle;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get commonFinishSetup;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get commonRestart;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @settingsProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileTitle;

  /// No description provided for @settingsCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrencyTitle;

  /// No description provided for @settingsDateFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get settingsDateFormatTitle;

  /// No description provided for @settingsDistanceUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Distance unit'**
  String get settingsDistanceUnitTitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @settingsAppVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersionTitle;

  /// No description provided for @settingsEnvironmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get settingsEnvironmentTitle;

  /// No description provided for @settingsApiBaseUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get settingsApiBaseUrlTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get onboardingTitle;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language. You can change it anytime in Settings.'**
  String get onboardingLanguageBody;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeCopyShort.
  ///
  /// In en, this message translates to:
  /// **'Thanks for trying Compartarenta.\n\nThe app is free as long as it isn’t actively used. During this phase, you can configure your expense-sharing plan as precisely as you need. This plan will serve as a proposed agreement to share with one or more people.\n\nOnce your plan is accepted and put into service, the 6‑week free trial begins.'**
  String get onboardingWelcomeCopyShort;

  /// No description provided for @onboardingReadLater.
  ///
  /// In en, this message translates to:
  /// **'Read later'**
  String get onboardingReadLater;

  /// No description provided for @onboardingWelcomeMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'About the trial and license'**
  String get onboardingWelcomeMoreTitle;

  /// No description provided for @onboardingWelcomeCopyLong.
  ///
  /// In en, this message translates to:
  /// **'At the end of the trial, you and your partners can choose to continue by purchasing a \$4 license per person. Each participant in the plan must have a license.\n\nThis license funds development and maintenance. There will NEVER be ads in the app.\n\nYour data is not used in any way: it stays on your device (and the participants’ devices) and nowhere else. The data belongs to you.\n\nIf you don’t renew the license, you won’t be able to add new data, but you will be able to export existing data.'**
  String get onboardingWelcomeCopyLong;

  /// No description provided for @onboardingOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get onboardingOk;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get onboardingAvatarTitle;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get onboardingPreferencesTitle;

  /// No description provided for @prefsCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get prefsCurrencyLabel;

  /// No description provided for @prefsCurrencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code or name'**
  String get prefsCurrencySearchHint;

  /// No description provided for @prefsDateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get prefsDateFormatLabel;

  /// No description provided for @prefsDistanceUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance unit'**
  String get prefsDistanceUnitLabel;

  /// No description provided for @prefsDistanceUnitKm.
  ///
  /// In en, this message translates to:
  /// **'Kilometers (km)'**
  String get prefsDistanceUnitKm;

  /// No description provided for @prefsDistanceUnitMiles.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get prefsDistanceUnitMiles;

  /// No description provided for @prefsTimeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get prefsTimeZoneLabel;

  /// No description provided for @prefsTimeZoneDevice.
  ///
  /// In en, this message translates to:
  /// **'Use device local time'**
  String get prefsTimeZoneDevice;

  /// No description provided for @prefsTimeZoneExplicit.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific time zone (later)'**
  String get prefsTimeZoneExplicit;

  /// No description provided for @errorSomethingWentWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorSomethingWentWrongTitle;

  /// No description provided for @errorSomethingWentWrongBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If this keeps happening, contact support.'**
  String get errorSomethingWentWrongBody;

  /// No description provided for @errorUnknownOnboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Unknown onboarding step.'**
  String get errorUnknownOnboardingStep;

  /// No description provided for @homeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment: {env}'**
  String homeEnvironment(String env);

  /// No description provided for @homeApiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL: {url}'**
  String homeApiBaseUrl(String url);

  /// No description provided for @homeHousingPlan.
  ///
  /// In en, this message translates to:
  /// **'Housing plan'**
  String get homeHousingPlan;

  /// No description provided for @housingPlanSummaryMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get housingPlanSummaryMonthlyTotal;

  /// No description provided for @homeCarSharingPlan.
  ///
  /// In en, this message translates to:
  /// **'Car sharing plan'**
  String get homeCarSharingPlan;

  /// No description provided for @homePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This is a placeholder home screen for the store-publishable MVP shell.'**
  String get homePlaceholderBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
