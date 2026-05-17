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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get commonPaste;

  /// No description provided for @commonBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commonBlock;

  /// No description provided for @commonUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get commonUnblock;

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

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions, categories, and sound'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsUnitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnitsTitle;

  /// No description provided for @settingsUnitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Currency, date format, and distance'**
  String get settingsUnitsSubtitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Environment, API URL, and app version'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsNotificationsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General permission'**
  String get settingsNotificationsGeneralSection;

  /// No description provided for @settingsNotificationsSystemPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'System permission'**
  String get settingsNotificationsSystemPermissionTitle;

  /// No description provided for @settingsNotificationsSystemPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'The app will ask after a relevant action, such as inviting someone.'**
  String get settingsNotificationsSystemPermissionBody;

  /// No description provided for @settingsNotificationsSystemPermissionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking permission…'**
  String get settingsNotificationsSystemPermissionChecking;

  /// No description provided for @settingsNotificationsSystemPermissionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this platform'**
  String get settingsNotificationsSystemPermissionUnsupported;

  /// No description provided for @settingsNotificationsSystemPermissionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not requested yet'**
  String get settingsNotificationsSystemPermissionUnknown;

  /// No description provided for @settingsNotificationsSystemPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed by the system'**
  String get settingsNotificationsSystemPermissionGranted;

  /// No description provided for @settingsNotificationsSystemPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Blocked by the system'**
  String get settingsNotificationsSystemPermissionDenied;

  /// No description provided for @settingsNotificationsSystemPermissionProvisional.
  ///
  /// In en, this message translates to:
  /// **'Allowed quietly'**
  String get settingsNotificationsSystemPermissionProvisional;

  /// No description provided for @settingsNotificationsRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsNotificationsRequestAction;

  /// No description provided for @settingsNotificationsGeneralSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow app notifications'**
  String get settingsNotificationsGeneralSwitchTitle;

  /// No description provided for @settingsNotificationsGeneralSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'Master switch for notification categories in this app.'**
  String get settingsNotificationsGeneralSwitchBody;

  /// No description provided for @settingsNotificationsContactsSection.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get settingsNotificationsContactsSection;

  /// No description provided for @settingsNotificationsContactAddRequest.
  ///
  /// In en, this message translates to:
  /// **'Add requests'**
  String get settingsNotificationsContactAddRequest;

  /// No description provided for @settingsNotificationsContactDisconnection.
  ///
  /// In en, this message translates to:
  /// **'Disconnection notices'**
  String get settingsNotificationsContactDisconnection;

  /// No description provided for @settingsNotificationsContactInvitationExpiration.
  ///
  /// In en, this message translates to:
  /// **'Unconsumed invitation expiration'**
  String get settingsNotificationsContactInvitationExpiration;

  /// No description provided for @settingsNotificationsHousingSection.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get settingsNotificationsHousingSection;

  /// No description provided for @settingsNotificationsHousingPlanSubmission.
  ///
  /// In en, this message translates to:
  /// **'Plan submission received'**
  String get settingsNotificationsHousingPlanSubmission;

  /// No description provided for @settingsNotificationsHousingDecisionChange.
  ///
  /// In en, this message translates to:
  /// **'Participant decision status changes'**
  String get settingsNotificationsHousingDecisionChange;

  /// No description provided for @settingsNotificationsHousingOfferExpiration.
  ///
  /// In en, this message translates to:
  /// **'Plan offer expiration without unanimous acceptance'**
  String get settingsNotificationsHousingOfferExpiration;

  /// No description provided for @settingsNotificationsSoundSection.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsNotificationsSoundSection;

  /// No description provided for @settingsNotificationsSoundSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound'**
  String get settingsNotificationsSoundSwitchTitle;

  /// No description provided for @settingsNotificationsSoundSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'Show notifications silently when this is off.'**
  String get settingsNotificationsSoundSwitchBody;

  /// No description provided for @settingsNotificationsSoundPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get settingsNotificationsSoundPickerTitle;

  /// No description provided for @settingsNotificationsSoundPickerBody.
  ///
  /// In en, this message translates to:
  /// **'Device sound selection will be added later where platforms allow it safely.'**
  String get settingsNotificationsSoundPickerBody;

  /// No description provided for @settingsNotificationsEnableBlocked.
  ///
  /// In en, this message translates to:
  /// **'System notification permission is not granted.'**
  String get settingsNotificationsEnableBlocked;

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

  /// No description provided for @homeHousingPlan.
  ///
  /// In en, this message translates to:
  /// **'Housing plan'**
  String get homeHousingPlan;

  /// No description provided for @homeModuleContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get homeModuleContacts;

  /// No description provided for @homeModuleHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get homeModuleHousing;

  /// No description provided for @homeModulePersonalBudget.
  ///
  /// In en, this message translates to:
  /// **'Personal budget'**
  String get homeModulePersonalBudget;

  /// No description provided for @homeModuleVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get homeModuleVehicle;

  /// No description provided for @homeModuleVehicleSharing.
  ///
  /// In en, this message translates to:
  /// **'Vehicle sharing'**
  String get homeModuleVehicleSharing;

  /// No description provided for @housingPlanSummaryMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get housingPlanSummaryMonthlyTotal;

  /// No description provided for @housingPlanLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load plan data.\n{error}'**
  String housingPlanLoadError(String error);

  /// No description provided for @housingPlanStepParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get housingPlanStepParticipants;

  /// No description provided for @housingPlanStepPlanDates.
  ///
  /// In en, this message translates to:
  /// **'Plan dates'**
  String get housingPlanStepPlanDates;

  /// No description provided for @housingPlanStepExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get housingPlanStepExpenseCategories;

  /// No description provided for @housingPlanStepExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get housingPlanStepExpenses;

  /// No description provided for @housingPlanStepSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get housingPlanStepSplit;

  /// No description provided for @housingPlanStepAgreementRules.
  ///
  /// In en, this message translates to:
  /// **'Agreement rules'**
  String get housingPlanStepAgreementRules;

  /// No description provided for @housingAgreementRulesIntro.
  ///
  /// In en, this message translates to:
  /// **'Turn rules on or off. Fixed rules stay listed even when off so everyone sees what was negotiated. You can add your own rules and remove them until a proposal has been accepted.'**
  String get housingAgreementRulesIntro;

  /// No description provided for @housingAgreementRuleCurfewTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours calendar'**
  String get housingAgreementRuleCurfewTitle;

  /// No description provided for @housingAgreementRuleCurfewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Indicative week (no dates): tap a day letter, then use the grid. In edit mode, tap a 30-minute cell to cycle no rule → absolute quiet (red) → moderate quiet (yellow).'**
  String get housingAgreementRuleCurfewPlaceholder;

  /// No description provided for @housingQuietHoursAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Absolute quiet'**
  String get housingQuietHoursAbsolute;

  /// No description provided for @housingQuietHoursModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate quiet'**
  String get housingQuietHoursModerate;

  /// No description provided for @housingQuietHoursNoneThisDay.
  ///
  /// In en, this message translates to:
  /// **'No quiet hours'**
  String get housingQuietHoursNoneThisDay;

  /// No description provided for @housingAgreementRuleEarlyWithdrawalTitle.
  ///
  /// In en, this message translates to:
  /// **'Early withdrawal'**
  String get housingAgreementRuleEarlyWithdrawalTitle;

  /// No description provided for @housingAgreementRuleBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building / household rules'**
  String get housingAgreementRuleBuildingTitle;

  /// No description provided for @housingAgreementRuleBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested topics you can copy or adapt:\n• Non-smoking\n• No pets\n• Nothing stored in hallways\n• …'**
  String get housingAgreementRuleBuildingHint;

  /// No description provided for @housingAgreementRuleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get housingAgreementRuleEdit;

  /// No description provided for @housingAgreementRuleFinishEditing.
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get housingAgreementRuleFinishEditing;

  /// No description provided for @housingAgreementRuleTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for this rule.'**
  String get housingAgreementRuleTitleRequired;

  /// No description provided for @housingAgreementSuggestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get housingAgreementSuggestionLabel;

  /// No description provided for @housingAgreementSuggestionCleanlinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Common area cleanliness'**
  String get housingAgreementSuggestionCleanlinessTitle;

  /// No description provided for @housingAgreementSuggestionCleanlinessBody.
  ///
  /// In en, this message translates to:
  /// **'• Keep clothing in assigned storage only.\n• Clean the shower and toilet after each use.\n• Wipe kitchen counters after cooking.\n• …'**
  String get housingAgreementSuggestionCleanlinessBody;

  /// No description provided for @housingAgreementSuggestionFridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fridge management'**
  String get housingAgreementSuggestionFridgeTitle;

  /// No description provided for @housingAgreementSuggestionFridgeBody.
  ///
  /// In en, this message translates to:
  /// **'• Label food you do not want to share.\n• Throw away expired items regularly.\n• Keep shelves and door clean.\n• …'**
  String get housingAgreementSuggestionFridgeBody;

  /// No description provided for @housingAgreementRuleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get housingAgreementRuleRemove;

  /// No description provided for @housingAgreementRuleDismissSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get housingAgreementRuleDismissSuggestion;

  /// No description provided for @housingAgreementRuleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get housingAgreementRuleAdd;

  /// No description provided for @housingAgreementRuleAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add agreement rule'**
  String get housingAgreementRuleAddTitle;

  /// No description provided for @housingAgreementRuleCustomTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get housingAgreementRuleCustomTitleLabel;

  /// No description provided for @housingAgreementRuleCustomBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get housingAgreementRuleCustomBodyLabel;

  /// No description provided for @housingAgreementRulesRemovalLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Rules that were part of an accepted proposal cannot be removed; you can still turn them off.'**
  String get housingAgreementRulesRemovalLockedHint;

  /// No description provided for @housingAgreementRuleEarlyWithdrawalDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Turn this rule on to set minimum notice and penalty.'**
  String get housingAgreementRuleEarlyWithdrawalDisabledHint;

  /// No description provided for @housingPlanParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String housingPlanParticipantsCount(int count);

  /// No description provided for @housingPlanFewerParticipantsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fewer participants'**
  String get housingPlanFewerParticipantsTooltip;

  /// No description provided for @housingPlanMoreParticipantsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More participants'**
  String get housingPlanMoreParticipantsTooltip;

  /// No description provided for @housingPlanAddCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add expense category'**
  String get housingPlanAddCategoryTooltip;

  /// No description provided for @housingPlanAddExpenseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get housingPlanAddExpenseTooltip;

  /// No description provided for @housingPlanBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get housingPlanBack;

  /// No description provided for @housingPlanNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get housingPlanNext;

  /// No description provided for @housingPlanFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get housingPlanFinish;

  /// No description provided for @housingPlanExpenseValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one expense. Each needs a valid amount (fixed or min/max range) and recurring items need a day of month.'**
  String get housingPlanExpenseValidationMessage;

  /// No description provided for @housingPlanSplitValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Each expense or category must total 100% across participants.'**
  String get housingPlanSplitValidationMessage;

  /// No description provided for @housingPlanCouldNotContinue.
  ///
  /// In en, this message translates to:
  /// **'Could not continue: {error}'**
  String housingPlanCouldNotContinue(String error);

  /// No description provided for @housingPlanInviteComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Invite participants (coming soon)'**
  String get housingPlanInviteComingSoon;

  /// No description provided for @housingPlanPreviousPerson.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get housingPlanPreviousPerson;

  /// No description provided for @housingPlanNextPerson.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get housingPlanNextPerson;

  /// No description provided for @housingPlanParticipantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get housingPlanParticipantNameLabel;

  /// No description provided for @housingPlanChooseContactAction.
  ///
  /// In en, this message translates to:
  /// **'Choose contact'**
  String get housingPlanChooseContactAction;

  /// No description provided for @housingPlanChangeContactAction.
  ///
  /// In en, this message translates to:
  /// **'Change contact'**
  String get housingPlanChangeContactAction;

  /// No description provided for @housingPlanContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact for each participant before continuing.'**
  String get housingPlanContactRequired;

  /// No description provided for @housingPlanParticipantsMustBeConnected.
  ///
  /// In en, this message translates to:
  /// **'Each co-participant must be a connected contact (they use the app on their own account). Invite them from Contacts first, then select them here.'**
  String get housingPlanParticipantsMustBeConnected;

  /// No description provided for @housingPlanParticipantsPlaceholderNote.
  ///
  /// In en, this message translates to:
  /// **'Co-participants must be connected contacts. The plan keeps a name and avatar snapshot for historical readability.'**
  String get housingPlanParticipantsPlaceholderNote;

  /// No description provided for @housingPlanYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get housingPlanYou;

  /// No description provided for @housingPlanCoParticipantUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Co-participant {index}'**
  String housingPlanCoParticipantUnnamed(int index);

  /// No description provided for @housingPlanPlanStart.
  ///
  /// In en, this message translates to:
  /// **'Plan start'**
  String get housingPlanPlanStart;

  /// No description provided for @housingPlanPlanEnd.
  ///
  /// In en, this message translates to:
  /// **'Plan end'**
  String get housingPlanPlanEnd;

  /// No description provided for @housingPlanEndDateError.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date (by at least one calendar day).'**
  String get housingPlanEndDateError;

  /// No description provided for @housingPlanCategoriesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a category. On the next step you can assign each expense to a category so related items stay together.'**
  String get housingPlanCategoriesEmptyHint;

  /// No description provided for @housingPlanDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get housingPlanDeleteCategoryTitle;

  /// No description provided for @housingPlanDeleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Expenses in this category will be unassigned from it. This does not delete the expenses.'**
  String get housingPlanDeleteCategoryBody;

  /// No description provided for @housingPlanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get housingPlanCancel;

  /// No description provided for @housingPlanDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get housingPlanDelete;

  /// No description provided for @housingPlanTapToAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an expense.'**
  String get housingPlanTapToAddExpense;

  /// No description provided for @housingPlanAddExpensesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add expenses first.'**
  String get housingPlanAddExpensesFirst;

  /// No description provided for @housingPlanSplitNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get housingPlanSplitNoCategory;

  /// No description provided for @housingPlanWithdrawalIntro.
  ///
  /// In en, this message translates to:
  /// **'Early withdrawal rules.'**
  String get housingPlanWithdrawalIntro;

  /// No description provided for @housingPlanWithdrawalSameForAll.
  ///
  /// In en, this message translates to:
  /// **'Same rule for all participants'**
  String get housingPlanWithdrawalSameForAll;

  /// No description provided for @housingPlanMinimumNoticeDays.
  ///
  /// In en, this message translates to:
  /// **'Minimum notice (days)'**
  String get housingPlanMinimumNoticeDays;

  /// No description provided for @housingPlanPenaltyAmount.
  ///
  /// In en, this message translates to:
  /// **'Penalty amount'**
  String get housingPlanPenaltyAmount;

  /// No description provided for @housingPlanSummaryMissingAgreement.
  ///
  /// In en, this message translates to:
  /// **'Missing agreement'**
  String get housingPlanSummaryMissingAgreement;

  /// No description provided for @housingPlanSummaryEditPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get housingPlanSummaryEditPlan;

  /// No description provided for @housingPlanSummaryInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite my participants'**
  String get housingPlanSummaryInvite;

  /// No description provided for @housingWorkbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'Housing plans'**
  String get housingWorkbenchTitle;

  /// No description provided for @housingWorkbenchDraftsSection.
  ///
  /// In en, this message translates to:
  /// **'Draft plans'**
  String get housingWorkbenchDraftsSection;

  /// No description provided for @housingWorkbenchPendingSection.
  ///
  /// In en, this message translates to:
  /// **'Pending proposals'**
  String get housingWorkbenchPendingSection;

  /// No description provided for @housingWorkbenchActiveSection.
  ///
  /// In en, this message translates to:
  /// **'Active plans'**
  String get housingWorkbenchActiveSection;

  /// No description provided for @housingWorkbenchOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get housingWorkbenchOpenPlan;

  /// No description provided for @housingWorkbenchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No housing plans with your profile on this device.'**
  String get housingWorkbenchEmpty;

  /// No description provided for @housingInviteResponseWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Response window'**
  String get housingInviteResponseWindowTitle;

  /// No description provided for @housingInviteResponseWindowBody.
  ///
  /// In en, this message translates to:
  /// **'Participants have until this date and time to respond (UTC).'**
  String get housingInviteResponseWindowBody;

  /// No description provided for @housingInvitePeriodOverlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement period conflict'**
  String get housingInvitePeriodOverlapTitle;

  /// No description provided for @housingInvitePeriodOverlapBody.
  ///
  /// In en, this message translates to:
  /// **'This agreement overlaps by more than one calendar day with another housing plan where you are a participant. Change the dates or resolve the other plan before sending.'**
  String get housingInvitePeriodOverlapBody;

  /// No description provided for @housingInviteProposalAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation proposal'**
  String get housingInviteProposalAppBarTitle;

  /// No description provided for @housingInviteProposalIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Here is the proposal that will be sent to each of your participants.'**
  String get housingInviteProposalIntroTitle;

  /// No description provided for @housingInviteParticipantsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get housingInviteParticipantsSectionTitle;

  /// No description provided for @housingInviteExpensesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses and split'**
  String get housingInviteExpensesSectionTitle;

  /// No description provided for @housingInviteRulesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement rules'**
  String get housingInviteRulesSectionTitle;

  /// No description provided for @housingInviteStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get housingInviteStatusAccepted;

  /// No description provided for @housingInviteStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get housingInviteStatusPending;

  /// No description provided for @housingInviteStatusNegotiating.
  ///
  /// In en, this message translates to:
  /// **'In negotiation'**
  String get housingInviteStatusNegotiating;

  /// No description provided for @housingInviteStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get housingInviteStatusRejected;

  /// No description provided for @housingInviteAcceptFull.
  ///
  /// In en, this message translates to:
  /// **'I accept in full'**
  String get housingInviteAcceptFull;

  /// No description provided for @housingInviteNegotiate.
  ///
  /// In en, this message translates to:
  /// **'I would like to negotiate'**
  String get housingInviteNegotiate;

  /// No description provided for @housingInviteRejectBlock.
  ///
  /// In en, this message translates to:
  /// **'I reject outright'**
  String get housingInviteRejectBlock;

  /// No description provided for @housingInviteNegotiateMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message to send with your negotiation request'**
  String get housingInviteNegotiateMessageLabel;

  /// No description provided for @housingInviteResponseSent.
  ///
  /// In en, this message translates to:
  /// **'Response sent.'**
  String get housingInviteResponseSent;

  /// No description provided for @housingArchiveEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived proposals'**
  String get housingArchiveEntryTitle;

  /// No description provided for @housingArchiveEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Choose an archived proposal to review or create a derived version, or create a new plan.'**
  String get housingArchiveEntryBody;

  /// No description provided for @housingArchiveNegotiatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan in negotiation'**
  String get housingArchiveNegotiatingTitle;

  /// No description provided for @housingArchiveRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Rejected plan'**
  String get housingArchiveRejectedTitle;

  /// No description provided for @housingArchiveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan draft'**
  String get housingArchiveDraftTitle;

  /// No description provided for @housingArchiveCreateDerivedAction.
  ///
  /// In en, this message translates to:
  /// **'Create a derived version'**
  String get housingArchiveCreateDerivedAction;

  /// No description provided for @housingArchiveEditDraftAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get housingArchiveEditDraftAction;

  /// No description provided for @housingArchiveViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get housingArchiveViewAction;

  /// No description provided for @housingArchiveCreateNewPlan.
  ///
  /// In en, this message translates to:
  /// **'Create a new plan'**
  String get housingArchiveCreateNewPlan;

  /// No description provided for @housingArchiveForkPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Your response was sent.'**
  String get housingArchiveForkPromptTitle;

  /// No description provided for @housingArchiveForkPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to create a derived version of this proposal now to make your changes?'**
  String get housingArchiveForkPromptBody;

  /// No description provided for @housingArchiveForkPromptLaterHint.
  ///
  /// In en, this message translates to:
  /// **'You can do this later from the main menu.'**
  String get housingArchiveForkPromptLaterHint;

  /// No description provided for @housingArchiveForkLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get housingArchiveForkLaterAction;

  /// No description provided for @housingArchiveForkPromptCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get housingArchiveForkPromptCreateAction;

  /// No description provided for @housingInviteProposalLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Another participant is negotiating or has rejected this proposal. Responses are paused until the plan is revised.'**
  String get housingInviteProposalLockedHint;

  /// No description provided for @housingInviteInvitationStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Invitation status'**
  String get housingInviteInvitationStatusAction;

  /// No description provided for @housingInviteStatusDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation status'**
  String get housingInviteStatusDialogTitle;

  /// No description provided for @housingInviteStatusSentAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent: {when}'**
  String housingInviteStatusSentAtLabel(String when);

  /// No description provided for @housingInviteStatusDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Response deadline: {when}'**
  String housingInviteStatusDeadlineLabel(String when);

  /// No description provided for @housingInviteStatusDeadlineNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get housingInviteStatusDeadlineNotSet;

  /// No description provided for @housingInviteStatusTableSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitees'**
  String get housingInviteStatusTableSectionTitle;

  /// No description provided for @housingInviteStatusTableInvitee.
  ///
  /// In en, this message translates to:
  /// **'Invitee'**
  String get housingInviteStatusTableInvitee;

  /// No description provided for @housingInviteStatusTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get housingInviteStatusTableStatus;

  /// No description provided for @housingInviteStatusMessagesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get housingInviteStatusMessagesSectionTitle;

  /// No description provided for @housingInviteStatusNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending invitation for this plan.'**
  String get housingInviteStatusNoPending;

  /// No description provided for @housingInviteTransportSent.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent to {sentCount} participant(s).'**
  String housingInviteTransportSent(int sentCount);

  /// No description provided for @housingInviteTransportPartial.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent to {sentCount} participant(s); {failedCount} participant(s) could not be reached.'**
  String housingInviteTransportPartial(int sentCount, int failedCount);

  /// No description provided for @pushNotificationHousingProposalTitle.
  ///
  /// In en, this message translates to:
  /// **'Housing proposal'**
  String get pushNotificationHousingProposalTitle;

  /// No description provided for @pushNotificationHousingProposalBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app to review the proposal.'**
  String get pushNotificationHousingProposalBody;

  /// No description provided for @pushNotificationHousingDecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Housing proposal response'**
  String get pushNotificationHousingDecisionTitle;

  /// No description provided for @pushNotificationHousingDecisionBody.
  ///
  /// In en, this message translates to:
  /// **'A participant responded to a housing proposal.'**
  String get pushNotificationHousingDecisionBody;

  /// No description provided for @pushNotificationHousingDecisionBodyFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} responded to a housing proposal.'**
  String pushNotificationHousingDecisionBodyFrom(String name);

  /// No description provided for @pushNotificationContactAddRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact request'**
  String get pushNotificationContactAddRequestTitle;

  /// No description provided for @pushNotificationContactAddRequestBody.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to connect with you.'**
  String pushNotificationContactAddRequestBody(String name);

  /// No description provided for @pushNotificationContactDisconnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact disconnected'**
  String get pushNotificationContactDisconnectionTitle;

  /// No description provided for @pushNotificationContactDisconnectionBody.
  ///
  /// In en, this message translates to:
  /// **'{name} disconnected from you.'**
  String pushNotificationContactDisconnectionBody(String name);

  /// No description provided for @housingInviteGenerateCodes.
  ///
  /// In en, this message translates to:
  /// **'Generate invitation codes'**
  String get housingInviteGenerateCodes;

  /// No description provided for @housingInviteCodesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation codes'**
  String get housingInviteCodesDialogTitle;

  /// No description provided for @housingInviteCodesDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Each code is for one co-participant. Share them however you prefer; registering codes with the relay server will be added later.'**
  String get housingInviteCodesDialogBody;

  /// No description provided for @housingInviteCodesCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get housingInviteCodesCopyAll;

  /// No description provided for @housingInviteCodesCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get housingInviteCodesCopied;

  /// No description provided for @housingInviteRuleOffHint.
  ///
  /// In en, this message translates to:
  /// **'This rule is turned off for this proposal.'**
  String get housingInviteRuleOffHint;

  /// No description provided for @housingInviteWithdrawalPerParticipantIntro.
  ///
  /// In en, this message translates to:
  /// **'Notice and penalty differ by participant (see below).'**
  String get housingInviteWithdrawalPerParticipantIntro;

  /// No description provided for @housingInviteHousingAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Housing agreement'**
  String get housingInviteHousingAgreementTitle;

  /// No description provided for @housingInviteDateRangeSeparator.
  ///
  /// In en, this message translates to:
  /// **' to '**
  String get housingInviteDateRangeSeparator;

  /// No description provided for @housingInviteSunburstCenterLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get housingInviteSunburstCenterLabel;

  /// No description provided for @housingInviteSunburstCenterParticipation.
  ///
  /// In en, this message translates to:
  /// **'Overall participation {pct}%'**
  String housingInviteSunburstCenterParticipation(String pct);

  /// No description provided for @housingInviteSunburstEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No expense data to chart for this plan.'**
  String get housingInviteSunburstEmptyHint;

  /// No description provided for @housingInviteSunburstLegendAgreementShare.
  ///
  /// In en, this message translates to:
  /// **'{name} - {pct}% of the agreement'**
  String housingInviteSunburstLegendAgreementShare(String name, String pct);

  /// No description provided for @housingInviteSunburstLegendYouParticipation.
  ///
  /// In en, this message translates to:
  /// **'Your participation: {userAmount}/{totalAmount} ({pct}%)'**
  String housingInviteSunburstLegendYouParticipation(
    String userAmount,
    String totalAmount,
    String pct,
  );

  /// No description provided for @housingPlanSummaryDestroy.
  ///
  /// In en, this message translates to:
  /// **'Destroy plan'**
  String get housingPlanSummaryDestroy;

  /// No description provided for @housingPlanDestroyTitle.
  ///
  /// In en, this message translates to:
  /// **'Destroy plan'**
  String get housingPlanDestroyTitle;

  /// No description provided for @housingPlanDestroyBody.
  ///
  /// In en, this message translates to:
  /// **'This removes this housing plan, expenses, ratios, agreement, and draft participants from this device.'**
  String get housingPlanDestroyBody;

  /// No description provided for @housingPlanDestroyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Destroy'**
  String get housingPlanDestroyConfirm;

  /// No description provided for @housingPlanRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Plan removed'**
  String get housingPlanRemovedSnackbar;

  /// No description provided for @housingPlanAddCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get housingPlanAddCategoryTitle;

  /// No description provided for @housingPlanEditCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get housingPlanEditCategoryTitle;

  /// No description provided for @housingPlanCategoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get housingPlanCategoryNameLabel;

  /// No description provided for @housingPlanCategoryDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What belongs here (optional)'**
  String get housingPlanCategoryDescriptionLabel;

  /// No description provided for @housingPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get housingPlanSave;

  /// No description provided for @housingPlanAddExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get housingPlanAddExpenseTitle;

  /// No description provided for @housingPlanEditExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get housingPlanEditExpenseTitle;

  /// No description provided for @housingPlanRecurringSwitch.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get housingPlanRecurringSwitch;

  /// No description provided for @housingPlanApproximateAmountSwitch.
  ///
  /// In en, this message translates to:
  /// **'Approximate amount'**
  String get housingPlanApproximateAmountSwitch;

  /// No description provided for @housingPlanExpenseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get housingPlanExpenseTitleLabel;

  /// No description provided for @housingPlanCategoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get housingPlanCategoryOptionalLabel;

  /// No description provided for @housingPlanCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get housingPlanCategoryNone;

  /// No description provided for @housingPlanExpenseDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get housingPlanExpenseDescriptionLabel;

  /// No description provided for @housingPlanDayOfMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get housingPlanDayOfMonthLabel;

  /// No description provided for @housingPlanMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get housingPlanMinLabel;

  /// No description provided for @housingPlanMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get housingPlanMaxLabel;

  /// No description provided for @housingPlanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get housingPlanAmountLabel;

  /// Months segment of plan calendar duration (step 2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 month} other{{count} months}}'**
  String housingPlanDurationMonthsCount(int count);

  /// Days segment of plan calendar duration (step 2).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String housingPlanDurationDaysCount(int count);

  /// No description provided for @carSharingPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Car sharing plan'**
  String get carSharingPlanTitle;

  /// No description provided for @carSharingPlanFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get carSharingPlanFinish;

  /// No description provided for @carSharingOwnerPrompt.
  ///
  /// In en, this message translates to:
  /// **'{name}: specify whether this is your owned vehicle or a rental.'**
  String carSharingOwnerPrompt(String name);

  /// No description provided for @carSharingStepVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get carSharingStepVehicle;

  /// No description provided for @carSharingStepOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get carSharingStepOwner;

  /// No description provided for @carSharingStepParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get carSharingStepParticipants;

  /// No description provided for @carSharingStepInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance & registration'**
  String get carSharingStepInsurance;

  /// No description provided for @carSharingStepCurrentState.
  ///
  /// In en, this message translates to:
  /// **'Current condition'**
  String get carSharingStepCurrentState;

  /// No description provided for @carSharingStepMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance estimates'**
  String get carSharingStepMaintenance;

  /// No description provided for @carSharingStepAvailability.
  ///
  /// In en, this message translates to:
  /// **'Offered availability'**
  String get carSharingStepAvailability;

  /// No description provided for @carSharingStepFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel management'**
  String get carSharingStepFuel;

  /// No description provided for @carSharingStepClauses.
  ///
  /// In en, this message translates to:
  /// **'Other clauses'**
  String get carSharingStepClauses;

  /// No description provided for @carSharingFieldMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get carSharingFieldMake;

  /// No description provided for @carSharingFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get carSharingFieldModel;

  /// No description provided for @carSharingFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get carSharingFieldColor;

  /// No description provided for @carSharingFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get carSharingFieldYear;

  /// No description provided for @carSharingOwnerIsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner vehicle'**
  String get carSharingOwnerIsOwner;

  /// No description provided for @carSharingOwnerIsRental.
  ///
  /// In en, this message translates to:
  /// **'Rental vehicle'**
  String get carSharingOwnerIsRental;

  /// No description provided for @carSharingRentalSharePermission.
  ///
  /// In en, this message translates to:
  /// **'Sharing right obtained from the lessor'**
  String get carSharingRentalSharePermission;

  /// No description provided for @carSharingRentalContractCopy.
  ///
  /// In en, this message translates to:
  /// **'Will provide a copy of the lease when the agreement is accepted'**
  String get carSharingRentalContractCopy;

  /// No description provided for @carSharingInsuranceNotify.
  ///
  /// In en, this message translates to:
  /// **'Will notify insurers when the agreement is accepted'**
  String get carSharingInsuranceNotify;

  /// No description provided for @carSharingInsuranceAssumeIncrease.
  ///
  /// In en, this message translates to:
  /// **'Will assume any insurance premium increase (if not, and premiums rise, this agreement is subject to renegotiation)'**
  String get carSharingInsuranceAssumeIncrease;

  /// No description provided for @carSharingInsuranceProvideDocs.
  ///
  /// In en, this message translates to:
  /// **'Will provide copies of insurance and registration papers when the agreement is accepted'**
  String get carSharingInsuranceProvideDocs;

  /// No description provided for @carSharingEstimatedValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get carSharingEstimatedValueLabel;

  /// No description provided for @carSharingPhotoFront.
  ///
  /// In en, this message translates to:
  /// **'Front photo path (optional)'**
  String get carSharingPhotoFront;

  /// No description provided for @carSharingPhotoLeft.
  ///
  /// In en, this message translates to:
  /// **'Left side photo path (optional)'**
  String get carSharingPhotoLeft;

  /// No description provided for @carSharingPhotoRight.
  ///
  /// In en, this message translates to:
  /// **'Right side photo path (optional)'**
  String get carSharingPhotoRight;

  /// No description provided for @carSharingPhotoRear.
  ///
  /// In en, this message translates to:
  /// **'Rear photo path (optional)'**
  String get carSharingPhotoRear;

  /// No description provided for @carSharingPhotoSeatsFront.
  ///
  /// In en, this message translates to:
  /// **'Front seats photo path (optional)'**
  String get carSharingPhotoSeatsFront;

  /// No description provided for @carSharingPhotoSeatsRear.
  ///
  /// In en, this message translates to:
  /// **'Rear seats photo path (optional)'**
  String get carSharingPhotoSeatsRear;

  /// No description provided for @carSharingPhotoDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard photo path (optional)'**
  String get carSharingPhotoDashboard;

  /// No description provided for @carSharingPhotoOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer photo path (optional)'**
  String get carSharingPhotoOdometer;

  /// No description provided for @carSharingMaintenanceIntro.
  ///
  /// In en, this message translates to:
  /// **'Planned maintenance items count toward the “maintenance” category when sharing costs.'**
  String get carSharingMaintenanceIntro;

  /// No description provided for @carSharingMaintenanceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add maintenance item'**
  String get carSharingMaintenanceAdd;

  /// No description provided for @carSharingMaintenanceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit maintenance item'**
  String get carSharingMaintenanceEditTitle;

  /// No description provided for @carSharingMaintenanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No maintenance items yet.'**
  String get carSharingMaintenanceEmpty;

  /// No description provided for @carSharingMaintenanceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get carSharingMaintenanceTitleLabel;

  /// No description provided for @carSharingMaintenanceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get carSharingMaintenanceAmountLabel;

  /// No description provided for @carSharingAvailabilityIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap half-hour cells for the selected day: highlighted slots are when the vehicle is offered to co-sharers. Other times are assumed to stay with the owner.'**
  String get carSharingAvailabilityIntro;

  /// No description provided for @carSharingAvailabilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Offered to co-sharers'**
  String get carSharingAvailabilityAvailable;

  /// No description provided for @carSharingAvailabilityOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner use'**
  String get carSharingAvailabilityOwner;

  /// No description provided for @carSharingFuelIntro.
  ///
  /// In en, this message translates to:
  /// **'When using in-app fuel tracking, each purchase records: date/time, total cost, fuel volume, odometer reading, and whether it was a full tank. Full-tank entries anchor consumption between refills. Odometer readings also support distance per trip.'**
  String get carSharingFuelIntro;

  /// No description provided for @carSharingFuelUseAppTracking.
  ///
  /// In en, this message translates to:
  /// **'Use in-app fuel and odometer tracking'**
  String get carSharingFuelUseAppTracking;

  /// No description provided for @carSharingFuelCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Describe a different arrangement (not tracked by the app)'**
  String get carSharingFuelCustomHint;

  /// No description provided for @carSharingClausesIntro.
  ///
  /// In en, this message translates to:
  /// **'Add optional clauses and suggested topics. Housing-specific rules (curfew, early withdrawal, building rules) are omitted here.'**
  String get carSharingClausesIntro;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact'**
  String get contactsPickerTitle;

  /// No description provided for @contactsPickerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No selectable contacts yet'**
  String get contactsPickerEmptyTitle;

  /// No description provided for @contactsPickerEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite people and complete the connection in Contacts first. Only connected contacts can join this module.'**
  String get contactsPickerEmptyBody;

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite someone and connect through the relay. Connected contacts can be reused across modules.'**
  String get contactsEmptyBody;

  /// No description provided for @contactsAddContactAction.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get contactsAddContactAction;

  /// No description provided for @contactsAddLocalOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Add local contact'**
  String get contactsAddLocalOnlyAction;

  /// No description provided for @contactsAddLocalOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get contactsAddLocalOnlyTitle;

  /// No description provided for @contactsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get contactsEditTitle;

  /// No description provided for @contactsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactsDetailTitle;

  /// No description provided for @contactsDetailMissing.
  ///
  /// In en, this message translates to:
  /// **'This contact no longer exists.'**
  String get contactsDetailMissing;

  /// No description provided for @contactsInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite a contact'**
  String get contactsInviteAction;

  /// No description provided for @contactsInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a contact'**
  String get contactsInviteTitle;

  /// No description provided for @contactsInviteIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a one-time code'**
  String get contactsInviteIntroTitle;

  /// No description provided for @contactsInviteIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a single-use code and share it outside the app (SMS, email, in person). Anyone with the code can request to connect with you. You will confirm before they are added.'**
  String get contactsInviteIntroBody;

  /// No description provided for @contactsInviteValidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Code valid for'**
  String get contactsInviteValidityLabel;

  /// No description provided for @contactsInviteGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get contactsInviteGenerateAction;

  /// No description provided for @contactsInviteShareWarning.
  ///
  /// In en, this message translates to:
  /// **'Share this code with one person only. It expires automatically and stops working after being used or revoked.'**
  String get contactsInviteShareWarning;

  /// No description provided for @contactsInviteQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code from the other device, or use the text code below.'**
  String get contactsInviteQrLabel;

  /// No description provided for @contactsInviteQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'Invitation QR code'**
  String get contactsInviteQrSemantics;

  /// No description provided for @contactsInviteShortCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get contactsInviteShortCodeLabel;

  /// No description provided for @contactsInviteCopyDeepLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get contactsInviteCopyDeepLink;

  /// No description provided for @contactsInviteCopyShareText.
  ///
  /// In en, this message translates to:
  /// **'Copy invitation'**
  String get contactsInviteCopyShareText;

  /// No description provided for @contactsInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to connect on Compartarenta.\n\nOne-time code:\n{code}\n\nTo use it: open the Compartarenta app, go to Contacts, tap the scan/enter-code icon at the top of the screen, then paste this code. From the device that has the app installed you can also open: {link}'**
  String contactsInviteShareText(String link, String code);

  /// No description provided for @contactsInviteExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires {when}'**
  String contactsInviteExpiresAt(String when);

  /// No description provided for @contactsInviteRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get contactsInviteRevokeAction;

  /// No description provided for @contactsInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent invitations'**
  String get contactsInvitationsTitle;

  /// No description provided for @contactsInvitationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invitations sent yet.'**
  String get contactsInvitationsEmpty;

  /// No description provided for @contactsInvitationsItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation · {createdAt}'**
  String contactsInvitationsItemTitle(String createdAt);

  /// No description provided for @contactsInvitationsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get contactsInvitationsStatusPending;

  /// No description provided for @contactsInvitationsStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get contactsInvitationsStatusUsed;

  /// No description provided for @contactsInvitationsStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get contactsInvitationsStatusExpired;

  /// No description provided for @contactsInvitationsStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get contactsInvitationsStatusRevoked;

  /// No description provided for @contactsEnterInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a code'**
  String get contactsEnterInviteCodeTitle;

  /// No description provided for @contactsEnterInviteCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste or type the code you received from a contact. The app checks the format locally before doing anything else.'**
  String get contactsEnterInviteCodeIntro;

  /// No description provided for @contactsEnterInviteCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get contactsEnterInviteCodeFieldLabel;

  /// No description provided for @contactsEnterInviteCodeScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get contactsEnterInviteCodeScanQr;

  /// No description provided for @contactsEnterInviteCodeScanQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a Compartarenta invitation QR code.'**
  String get contactsEnterInviteCodeScanQrHint;

  /// No description provided for @contactsEnterInviteCodeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get contactsEnterInviteCodeSubmit;

  /// No description provided for @contactsEnterInviteCodeWaveBNote.
  ///
  /// In en, this message translates to:
  /// **'After tapping Connect, the encrypted request travels to the relay and waits for the inviter to approve it.'**
  String get contactsEnterInviteCodeWaveBNote;

  /// No description provided for @contactsEnterInviteCodeValid.
  ///
  /// In en, this message translates to:
  /// **'Code format is valid'**
  String get contactsEnterInviteCodeValid;

  /// No description provided for @contactsEnterInviteCodeInvitationId.
  ///
  /// In en, this message translates to:
  /// **'Invitation id: {id}'**
  String contactsEnterInviteCodeInvitationId(String id);

  /// No description provided for @contactsHandshakeNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'The relay handshake is not available yet. The code is valid locally, but cannot be redeemed until the relay is live.'**
  String get contactsHandshakeNotAvailableYet;

  /// No description provided for @contactsHandshakeDispatching.
  ///
  /// In en, this message translates to:
  /// **'Sending the request to the relay…'**
  String get contactsHandshakeDispatching;

  /// No description provided for @contactsHandshakeDispatched.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Waiting for the inviter to confirm.'**
  String get contactsHandshakeDispatched;

  /// No description provided for @contactsHandshakeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Connected. The contact has been added to your list.'**
  String get contactsHandshakeCompleted;

  /// No description provided for @contactsHandshakeRejected.
  ///
  /// In en, this message translates to:
  /// **'The other person declined the connection. You can ask them for a new invitation if needed.'**
  String get contactsHandshakeRejected;

  /// No description provided for @contactsHandshakeFailed.
  ///
  /// In en, this message translates to:
  /// **'The connection attempt failed. You can try again with a fresh invitation.'**
  String get contactsHandshakeFailed;

  /// No description provided for @contactsHandshakeErrorRelayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the relay. Check your network and try again.'**
  String get contactsHandshakeErrorRelayUnavailable;

  /// No description provided for @contactsHandshakeErrorAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This code has already been used.'**
  String get contactsHandshakeErrorAlreadyCompleted;

  /// No description provided for @contactsHandshakeErrorNonceConsumed.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been redeemed.'**
  String get contactsHandshakeErrorNonceConsumed;

  /// No description provided for @contactsHandshakeErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired.'**
  String get contactsHandshakeErrorExpired;

  /// No description provided for @contactsHandshakeErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while contacting the relay.'**
  String get contactsHandshakeErrorUnknown;

  /// No description provided for @contactsIncomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection requests'**
  String get contactsIncomingTitle;

  /// No description provided for @contactsIncomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending connection requests.'**
  String get contactsIncomingEmpty;

  /// No description provided for @contactsIncomingBody.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to connect.'**
  String contactsIncomingBody(String name);

  /// No description provided for @contactsIncomingAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get contactsIncomingAccept;

  /// No description provided for @contactsIncomingReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get contactsIncomingReject;

  /// No description provided for @contactsIncomingBannerOne.
  ///
  /// In en, this message translates to:
  /// **'1 new connection request'**
  String get contactsIncomingBannerOne;

  /// No description provided for @contactsIncomingBannerMany.
  ///
  /// In en, this message translates to:
  /// **'{count} new connection requests'**
  String contactsIncomingBannerMany(int count);

  /// No description provided for @contactsRefreshIncomingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Check for connection requests'**
  String get contactsRefreshIncomingTooltip;

  /// No description provided for @contactsRefreshIncomingFound.
  ///
  /// In en, this message translates to:
  /// **'{count} pending connection request(s).'**
  String contactsRefreshIncomingFound(int count);

  /// No description provided for @contactsRefreshIncomingNone.
  ///
  /// In en, this message translates to:
  /// **'No pending connection requests found.'**
  String get contactsRefreshIncomingNone;

  /// No description provided for @contactsRefreshIncomingNoneWithActivePolls.
  ///
  /// In en, this message translates to:
  /// **'No pending connection requests found. Active relay poll(s): {count}.'**
  String contactsRefreshIncomingNoneWithActivePolls(int count);

  /// No description provided for @contactsRefreshIncomingDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No pending connection requests found. Active relay poll(s): {activeCount}. Local handshake row(s): {totalCount}. Latest state: {latestState}.'**
  String contactsRefreshIncomingDiagnostics(
    int activeCount,
    int totalCount,
    String latestState,
  );

  /// No description provided for @contactsCodeErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a code to continue.'**
  String get contactsCodeErrorEmpty;

  /// No description provided for @contactsCodeErrorTooShort.
  ///
  /// In en, this message translates to:
  /// **'This code is too short.'**
  String get contactsCodeErrorTooShort;

  /// No description provided for @contactsCodeErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'This code is too long.'**
  String get contactsCodeErrorTooLong;

  /// No description provided for @contactsCodeErrorInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'This code contains characters that are not allowed.'**
  String get contactsCodeErrorInvalidCharacters;

  /// No description provided for @contactsCodeErrorBadChecksum.
  ///
  /// In en, this message translates to:
  /// **'This code looks mistyped. Check the characters and try again.'**
  String get contactsCodeErrorBadChecksum;

  /// No description provided for @contactsCodeErrorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'This code was created by a newer version of the app.'**
  String get contactsCodeErrorUnsupportedVersion;

  /// No description provided for @contactsKindLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get contactsKindLocalOnly;

  /// No description provided for @contactsKindDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get contactsKindDisconnected;

  /// No description provided for @contactsKindConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get contactsKindConnected;

  /// No description provided for @contactsKindBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get contactsKindBlocked;

  /// No description provided for @contactsKindDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get contactsKindDeleted;

  /// No description provided for @contactsFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactsFieldNameLabel;

  /// No description provided for @contactsFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'How this person appears in the app'**
  String get contactsFieldNameHint;

  /// No description provided for @contactsFieldAvatarReadOnlyFootnote.
  ///
  /// In en, this message translates to:
  /// **'Only they can change their avatar on their device.'**
  String get contactsFieldAvatarReadOnlyFootnote;

  /// No description provided for @contactsFieldAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get contactsFieldAvatarLabel;

  /// No description provided for @contactsFieldNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get contactsFieldNotesLabel;

  /// No description provided for @contactsFieldNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Personal reminder, not shared'**
  String get contactsFieldNotesHint;

  /// No description provided for @contactsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete contact?'**
  String get contactsDeleteTitle;

  /// No description provided for @contactsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Existing housing or vehicle entries that reference this contact will keep the name and avatar stored at the time they were added. To work with this person again, create a new local contact, or send them a new invitation.'**
  String get contactsDeleteBody;

  /// No description provided for @contactsDeletePreservesHistory.
  ///
  /// In en, this message translates to:
  /// **'Existing entries that reference this contact keep their stored name and avatar.'**
  String get contactsDeletePreservesHistory;

  /// No description provided for @contactsDeleteBlockedByPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete this contact yet'**
  String get contactsDeleteBlockedByPlansTitle;

  /// No description provided for @contactsDeleteBlockedByPlansBody.
  ///
  /// In en, this message translates to:
  /// **'This contact is still listed as a participant in {count, plural, =1{one plan} other{{count} plans}}: {plans}. Remove them from those plans first, then you\'ll be able to delete the contact.'**
  String contactsDeleteBlockedByPlansBody(int count, String plans);

  /// No description provided for @contactsDeleteBlockedConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Disconnect first'**
  String get contactsDeleteBlockedConnectedTitle;

  /// No description provided for @contactsDeleteBlockedConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'This contact is currently connected. Just deleting it on this device would leave the other side thinking the connection is still up. Use Disconnect first: it sends an encrypted disconnect signal to the peer through the relay and downgrades the contact to local-only on this device. You can then delete the contact normally.'**
  String get contactsDeleteBlockedConnectedBody;

  /// No description provided for @contactsDeleteBlockedConnectedAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect first'**
  String get contactsDeleteBlockedConnectedAction;

  /// No description provided for @contactsBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this contact?'**
  String get contactsBlockTitle;

  /// No description provided for @contactsBlockBody.
  ///
  /// In en, this message translates to:
  /// **'Incoming messages from this contact will be ignored locally. The relay is not informed of the block.'**
  String get contactsBlockBody;

  /// No description provided for @contactsUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock this contact?'**
  String get contactsUnblockTitle;

  /// No description provided for @contactsUnblockBody.
  ///
  /// In en, this message translates to:
  /// **'Incoming messages from this contact will be processed again.'**
  String get contactsUnblockBody;

  /// No description provided for @contactsDisconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get contactsDisconnectAction;

  /// No description provided for @contactsDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from this contact?'**
  String get contactsDisconnectTitle;

  /// No description provided for @contactsDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'A disconnect notice will be sent to the relay. Both sides will fall back to local-only contacts.'**
  String get contactsDisconnectBody;

  /// No description provided for @contactsDisconnectSent.
  ///
  /// In en, this message translates to:
  /// **'Disconnect notice sent. Contact is now local-only.'**
  String get contactsDisconnectSent;

  /// No description provided for @contactsReconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Request reconnection'**
  String get contactsReconnectAction;

  /// No description provided for @contactsLabelEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'How you see this contact'**
  String get contactsLabelEditorTitle;

  /// No description provided for @contactsLabelEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the name they choose on their device'**
  String get contactsLabelEditorHint;

  /// No description provided for @contactsFieldTheirNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get contactsFieldTheirNameLabel;

  /// No description provided for @settingsProfileIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get settingsProfileIdentityTitle;

  /// No description provided for @settingsProfileIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name and avatar shown to your contacts'**
  String get settingsProfileIdentitySubtitle;

  /// No description provided for @settingsProfileAppearancesTitle.
  ///
  /// In en, this message translates to:
  /// **'How others label you'**
  String get settingsProfileAppearancesTitle;

  /// No description provided for @settingsProfileAppearancesBody.
  ///
  /// In en, this message translates to:
  /// **'Each connected contact can share the name they use for you in their list. It is delivered only inside encrypted profile updates.'**
  String get settingsProfileAppearancesBody;

  /// No description provided for @settingsProfileAppearancesColumnPeer.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get settingsProfileAppearancesColumnPeer;

  /// No description provided for @settingsProfileAppearancesColumnTheirLabel.
  ///
  /// In en, this message translates to:
  /// **'Their label for you'**
  String get settingsProfileAppearancesColumnTheirLabel;

  /// No description provided for @settingsProfileAppearancesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No connected contacts yet. Pair with someone to see how they label you here.'**
  String get settingsProfileAppearancesEmpty;

  /// No description provided for @settingsProfileAppearancesNoSharedLabels.
  ///
  /// In en, this message translates to:
  /// **'No contact has shared a custom name for you in their list yet.'**
  String get settingsProfileAppearancesNoSharedLabels;

  /// No description provided for @peerNameConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact updated their name'**
  String get peerNameConflictTitle;

  /// No description provided for @peerNameConflictBody.
  ///
  /// In en, this message translates to:
  /// **'You label this contact \"{label}\". They now use \"{canonical}\" on their device.'**
  String peerNameConflictBody(String label, String canonical);

  /// No description provided for @peerNameConflictUseTheirs.
  ///
  /// In en, this message translates to:
  /// **'Use their name'**
  String get peerNameConflictUseTheirs;

  /// No description provided for @peerNameConflictKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep my label'**
  String get peerNameConflictKeepMine;
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
