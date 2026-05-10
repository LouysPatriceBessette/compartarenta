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
  String housingPlanLoadError(String error) {
    return 'Could not load plan data.\n$error';
  }

  @override
  String get housingPlanStepParticipants => 'Participants';

  @override
  String get housingPlanStepPlanDates => 'Plan dates';

  @override
  String get housingPlanStepExpenseCategories => 'Expense categories';

  @override
  String get housingPlanStepExpenses => 'Expenses';

  @override
  String get housingPlanStepSplit => 'Split';

  @override
  String get housingPlanStepWithdrawal => 'Withdrawal';

  @override
  String housingPlanParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get housingPlanFewerParticipantsTooltip => 'Fewer participants';

  @override
  String get housingPlanMoreParticipantsTooltip => 'More participants';

  @override
  String get housingPlanAddCategoryTooltip => 'Add expense category';

  @override
  String get housingPlanAddExpenseTooltip => 'Add expense';

  @override
  String get housingPlanBack => 'Back';

  @override
  String get housingPlanNext => 'Next';

  @override
  String get housingPlanFinish => 'Finish';

  @override
  String get housingPlanExpenseValidationMessage =>
      'Add at least one expense. Each needs a valid amount (fixed or min/max range) and recurring items need a day of month.';

  @override
  String get housingPlanSplitValidationMessage =>
      'Each expense or category must total 100% across participants.';

  @override
  String housingPlanCouldNotContinue(String error) {
    return 'Could not continue: $error';
  }

  @override
  String get housingPlanInviteComingSoon => 'Invite participants (coming soon)';

  @override
  String get housingPlanPreviousPerson => 'Previous person';

  @override
  String get housingPlanNextPerson => 'Next person';

  @override
  String get housingPlanParticipantNameLabel => 'Name';

  @override
  String get housingPlanParticipantsPlaceholderNote =>
      'Names and avatars are placeholders until someone joins for real.';

  @override
  String get housingPlanYou => 'You';

  @override
  String housingPlanCoParticipantUnnamed(int index) {
    return 'Co-participant $index';
  }

  @override
  String get housingPlanPlanStart => 'Plan start';

  @override
  String get housingPlanPlanEnd => 'Plan end';

  @override
  String get housingPlanEndDateError =>
      'End date must be after start date (by at least one calendar day).';

  @override
  String get housingPlanCategoriesEmptyHint =>
      'Tap + to add a category. On the next step you can assign each expense to a category so related items stay together.';

  @override
  String get housingPlanDeleteCategoryTitle => 'Delete category';

  @override
  String get housingPlanDeleteCategoryBody =>
      'Expenses in this category will be unassigned from it. This does not delete the expenses.';

  @override
  String get housingPlanCancel => 'Cancel';

  @override
  String get housingPlanDelete => 'Delete';

  @override
  String get housingPlanTapToAddExpense => 'Tap + to add an expense.';

  @override
  String get housingPlanAddExpensesFirst => 'Add expenses first.';

  @override
  String get housingPlanSplitNoCategory => 'No category';

  @override
  String get housingPlanWithdrawalIntro => 'Early withdrawal rules.';

  @override
  String get housingPlanWithdrawalSameForAll =>
      'Same rule for all participants';

  @override
  String get housingPlanMinimumNoticeDays => 'Minimum notice (days)';

  @override
  String get housingPlanPenaltyAmount => 'Penalty amount';

  @override
  String get housingPlanSummaryMissingAgreement => 'Missing agreement';

  @override
  String get housingPlanSummaryEditPlan => 'Edit plan';

  @override
  String get housingPlanSummaryInvite => 'Invite my participants';

  @override
  String get housingPlanSummaryDestroy => 'Destroy plan';

  @override
  String get housingPlanDestroyTitle => 'Destroy plan';

  @override
  String get housingPlanDestroyBody =>
      'This removes this housing plan, expenses, ratios, agreement, and draft participants from this device.';

  @override
  String get housingPlanDestroyConfirm => 'Destroy';

  @override
  String get housingPlanRemovedSnackbar => 'Plan removed';

  @override
  String get housingPlanAddCategoryTitle => 'Add category';

  @override
  String get housingPlanEditCategoryTitle => 'Edit category';

  @override
  String get housingPlanCategoryNameLabel => 'Category name';

  @override
  String get housingPlanCategoryDescriptionLabel =>
      'What belongs here (optional)';

  @override
  String get housingPlanSave => 'Save';

  @override
  String get housingPlanAddExpenseTitle => 'Add expense';

  @override
  String get housingPlanEditExpenseTitle => 'Edit expense';

  @override
  String get housingPlanRecurringSwitch => 'Recurring';

  @override
  String get housingPlanApproximateAmountSwitch => 'Approximate amount';

  @override
  String get housingPlanExpenseTitleLabel => 'Title';

  @override
  String get housingPlanCategoryOptionalLabel => 'Category (optional)';

  @override
  String get housingPlanCategoryNone => 'None';

  @override
  String get housingPlanExpenseDescriptionLabel => 'Description (optional)';

  @override
  String get housingPlanDayOfMonthLabel => 'Day of month';

  @override
  String get housingPlanMinLabel => 'Min';

  @override
  String get housingPlanMaxLabel => 'Max';

  @override
  String get housingPlanAmountLabel => 'Amount';

  @override
  String housingPlanDurationMonthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String housingPlanDurationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get homeCarSharingPlan => 'Car sharing plan';

  @override
  String get homePlaceholderBody =>
      'This is a placeholder home screen for the store-publishable MVP shell.';
}
