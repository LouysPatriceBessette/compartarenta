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
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonPaste => 'Paste';

  @override
  String get commonBlock => 'Block';

  @override
  String get commonUnblock => 'Unblock';

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
  String get housingPlanStepAgreementRules => 'Agreement rules';

  @override
  String get housingAgreementRulesIntro =>
      'Turn rules on or off. Fixed rules stay listed even when off so everyone sees what was negotiated. You can add your own rules and remove them until a proposal has been accepted.';

  @override
  String get housingAgreementRuleCurfewTitle => 'Quiet hours calendar';

  @override
  String get housingAgreementRuleCurfewPlaceholder =>
      'Indicative week (no dates): tap a day letter, then use the grid. In edit mode, tap a 30-minute cell to cycle no rule → absolute quiet (red) → moderate quiet (yellow).';

  @override
  String get housingQuietHoursAbsolute => 'Absolute quiet';

  @override
  String get housingQuietHoursModerate => 'Moderate quiet';

  @override
  String get housingQuietHoursNoneThisDay => 'No quiet hours';

  @override
  String get housingAgreementRuleEarlyWithdrawalTitle => 'Early withdrawal';

  @override
  String get housingAgreementRuleBuildingTitle => 'Building / household rules';

  @override
  String get housingAgreementRuleBuildingHint =>
      'Suggested topics you can copy or adapt:\n• Non-smoking\n• No pets\n• Nothing stored in hallways\n• …';

  @override
  String get housingAgreementRuleEdit => 'Edit';

  @override
  String get housingAgreementRuleFinishEditing => 'Done editing';

  @override
  String get housingAgreementRuleTitleRequired =>
      'Enter a title for this rule.';

  @override
  String get housingAgreementSuggestionLabel => 'Suggestion';

  @override
  String get housingAgreementSuggestionCleanlinessTitle =>
      'Common area cleanliness';

  @override
  String get housingAgreementSuggestionCleanlinessBody =>
      '• Keep clothing in assigned storage only.\n• Clean the shower and toilet after each use.\n• Wipe kitchen counters after cooking.\n• …';

  @override
  String get housingAgreementSuggestionFridgeTitle => 'Fridge management';

  @override
  String get housingAgreementSuggestionFridgeBody =>
      '• Label food you do not want to share.\n• Throw away expired items regularly.\n• Keep shelves and door clean.\n• …';

  @override
  String get housingAgreementRuleRemove => 'Remove rule';

  @override
  String get housingAgreementRuleDismissSuggestion => 'Remove from list';

  @override
  String get housingAgreementRuleAdd => 'Add rule';

  @override
  String get housingAgreementRuleAddTitle => 'Add agreement rule';

  @override
  String get housingAgreementRuleCustomTitleLabel => 'Title';

  @override
  String get housingAgreementRuleCustomBodyLabel => 'Details (optional)';

  @override
  String get housingAgreementRulesRemovalLockedHint =>
      'Rules that were part of an accepted proposal cannot be removed; you can still turn them off.';

  @override
  String get housingAgreementRuleEarlyWithdrawalDisabledHint =>
      'Turn this rule on to set minimum notice and penalty.';

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
  String get housingPlanPreviousPerson => 'Previous';

  @override
  String get housingPlanNextPerson => 'Next';

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
  String get housingInviteProposalAppBarTitle => 'Invitation proposal';

  @override
  String get housingInviteProposalIntroTitle =>
      'Here is the proposal that will be sent to each of your participants.';

  @override
  String get housingInviteParticipantsSectionTitle => 'Participants';

  @override
  String get housingInviteExpensesSectionTitle => 'Expenses and split';

  @override
  String get housingInviteRulesSectionTitle => 'Agreement rules';

  @override
  String get housingInviteStatusAccepted => 'Accepted';

  @override
  String get housingInviteStatusPending => 'Pending';

  @override
  String get housingInviteStatusNegotiating => 'In negotiation';

  @override
  String get housingInviteStatusRejected => 'Rejected';

  @override
  String get housingInviteAcceptFull => 'I accept in full';

  @override
  String get housingInviteNegotiate => 'I would like to negotiate';

  @override
  String get housingInviteRejectBlock => 'I reject outright';

  @override
  String get housingInviteNegotiateMessageLabel =>
      'Message to send with your negotiation request';

  @override
  String get housingInviteProposalLockedHint =>
      'Another participant is negotiating or has rejected this proposal. Responses are paused until the plan is revised.';

  @override
  String get housingInviteGenerateCodes => 'Generate invitation codes';

  @override
  String get housingInviteCodesDialogTitle => 'Invitation codes';

  @override
  String get housingInviteCodesDialogBody =>
      'Each code is for one co-participant. Share them however you prefer; registering codes with the relay server will be added later.';

  @override
  String get housingInviteCodesCopyAll => 'Copy all';

  @override
  String get housingInviteCodesCopied => 'Copied to clipboard';

  @override
  String get housingInviteRuleOffHint =>
      'This rule is turned off for this proposal.';

  @override
  String get housingInviteWithdrawalPerParticipantIntro =>
      'Notice and penalty differ by participant (see below).';

  @override
  String get housingInviteHousingAgreementTitle => 'Housing agreement';

  @override
  String get housingInviteDateRangeSeparator => ' to ';

  @override
  String get housingInviteSunburstCenterLabel => 'Overall';

  @override
  String housingInviteSunburstCenterParticipation(String pct) {
    return 'Overall participation $pct%';
  }

  @override
  String get housingInviteSunburstEmptyHint =>
      'No expense data to chart for this plan.';

  @override
  String housingInviteSunburstLegendAgreementShare(String name, String pct) {
    return '$name - $pct% of the agreement';
  }

  @override
  String housingInviteSunburstLegendYouParticipation(
    String userAmount,
    String totalAmount,
    String pct,
  ) {
    return 'Your participation: $userAmount/$totalAmount ($pct%)';
  }

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
  String get carSharingPlanTitle => 'Car sharing plan';

  @override
  String get carSharingPlanFinish => 'Done';

  @override
  String carSharingOwnerPrompt(String name) {
    return '$name: specify whether this is your owned vehicle or a rental.';
  }

  @override
  String get carSharingStepVehicle => 'Vehicle';

  @override
  String get carSharingStepOwner => 'Owner';

  @override
  String get carSharingStepParticipants => 'Participants';

  @override
  String get carSharingStepInsurance => 'Insurance & registration';

  @override
  String get carSharingStepCurrentState => 'Current condition';

  @override
  String get carSharingStepMaintenance => 'Maintenance estimates';

  @override
  String get carSharingStepAvailability => 'Offered availability';

  @override
  String get carSharingStepFuel => 'Fuel management';

  @override
  String get carSharingStepClauses => 'Other clauses';

  @override
  String get carSharingFieldMake => 'Make';

  @override
  String get carSharingFieldModel => 'Model';

  @override
  String get carSharingFieldColor => 'Color';

  @override
  String get carSharingFieldYear => 'Year';

  @override
  String get carSharingOwnerIsOwner => 'Owner vehicle';

  @override
  String get carSharingOwnerIsRental => 'Rental vehicle';

  @override
  String get carSharingRentalSharePermission =>
      'Sharing right obtained from the lessor';

  @override
  String get carSharingRentalContractCopy =>
      'Will provide a copy of the lease when the agreement is accepted';

  @override
  String get carSharingInsuranceNotify =>
      'Will notify insurers when the agreement is accepted';

  @override
  String get carSharingInsuranceAssumeIncrease =>
      'Will assume any insurance premium increase (if not, and premiums rise, this agreement is subject to renegotiation)';

  @override
  String get carSharingInsuranceProvideDocs =>
      'Will provide copies of insurance and registration papers when the agreement is accepted';

  @override
  String get carSharingEstimatedValueLabel => 'Estimated value';

  @override
  String get carSharingPhotoFront => 'Front photo path (optional)';

  @override
  String get carSharingPhotoLeft => 'Left side photo path (optional)';

  @override
  String get carSharingPhotoRight => 'Right side photo path (optional)';

  @override
  String get carSharingPhotoRear => 'Rear photo path (optional)';

  @override
  String get carSharingPhotoSeatsFront => 'Front seats photo path (optional)';

  @override
  String get carSharingPhotoSeatsRear => 'Rear seats photo path (optional)';

  @override
  String get carSharingPhotoDashboard => 'Dashboard photo path (optional)';

  @override
  String get carSharingPhotoOdometer => 'Odometer photo path (optional)';

  @override
  String get carSharingMaintenanceIntro =>
      'Planned maintenance items count toward the “maintenance” category when sharing costs.';

  @override
  String get carSharingMaintenanceAdd => 'Add maintenance item';

  @override
  String get carSharingMaintenanceEditTitle => 'Edit maintenance item';

  @override
  String get carSharingMaintenanceEmpty => 'No maintenance items yet.';

  @override
  String get carSharingMaintenanceTitleLabel => 'Title';

  @override
  String get carSharingMaintenanceAmountLabel => 'Amount';

  @override
  String get carSharingAvailabilityIntro =>
      'Tap half-hour cells for the selected day: highlighted slots are when the vehicle is offered to co-sharers. Other times are assumed to stay with the owner.';

  @override
  String get carSharingAvailabilityAvailable => 'Offered to co-sharers';

  @override
  String get carSharingAvailabilityOwner => 'Owner use';

  @override
  String get carSharingFuelIntro =>
      'When using in-app fuel tracking, each purchase records: date/time, total cost, fuel volume, odometer reading, and whether it was a full tank. Full-tank entries anchor consumption between refills. Odometer readings also support distance per trip.';

  @override
  String get carSharingFuelUseAppTracking =>
      'Use in-app fuel and odometer tracking';

  @override
  String get carSharingFuelCustomHint =>
      'Describe a different arrangement (not tracked by the app)';

  @override
  String get carSharingClausesIntro =>
      'Add optional clauses and suggested topics. Housing-specific rules (curfew, early withdrawal, building rules) are omitted here.';

  @override
  String get homePlaceholderBody =>
      'This is a placeholder home screen for the store-publishable MVP shell.';

  @override
  String get homeContacts => 'Contacts';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsEmptyTitle => 'No contacts yet';

  @override
  String get contactsEmptyBody =>
      'Add someone you know to reuse them across modules, or invite a contact to connect through the relay.';

  @override
  String get contactsAddLocalOnlyAction => 'Add a contact';

  @override
  String get contactsAddLocalOnlyTitle => 'New contact';

  @override
  String get contactsEditTitle => 'Edit contact';

  @override
  String get contactsDetailTitle => 'Contact';

  @override
  String get contactsDetailMissing => 'This contact no longer exists.';

  @override
  String get contactsInviteAction => 'Invite a contact';

  @override
  String get contactsInviteTitle => 'Invite a contact';

  @override
  String get contactsInviteIntroTitle => 'Share a one-time code';

  @override
  String get contactsInviteIntroBody =>
      'Generate a single-use code and share it outside the app (SMS, email, in person). Anyone with the code can request to connect with you. You will confirm before they are added.';

  @override
  String get contactsInviteValidityLabel => 'Code valid for';

  @override
  String get contactsInviteGenerateAction => 'Generate code';

  @override
  String get contactsInviteShareWarning =>
      'Share this code with one person only. It expires automatically and stops working after being used or revoked.';

  @override
  String get contactsInviteShortCodeLabel => 'Code';

  @override
  String get contactsInviteCopyDeepLink => 'Copy link';

  @override
  String contactsInviteExpiresAt(String when) {
    return 'Expires $when';
  }

  @override
  String get contactsInviteRevokeAction => 'Revoke';

  @override
  String get contactsInvitationsTitle => 'Sent invitations';

  @override
  String get contactsInvitationsEmpty => 'No invitations sent yet.';

  @override
  String contactsInvitationsItemTitle(String createdAt) {
    return 'Invitation · $createdAt';
  }

  @override
  String get contactsInvitationsStatusPending => 'Pending';

  @override
  String get contactsInvitationsStatusUsed => 'Used';

  @override
  String get contactsInvitationsStatusExpired => 'Expired';

  @override
  String get contactsInvitationsStatusRevoked => 'Revoked';

  @override
  String get contactsEnterInviteCodeTitle => 'Enter a code';

  @override
  String get contactsEnterInviteCodeIntro =>
      'Paste or type the code you received from a contact. The app checks the format locally before doing anything else.';

  @override
  String get contactsEnterInviteCodeFieldLabel => 'Invitation code';

  @override
  String get contactsEnterInviteCodeSubmit => 'Connect';

  @override
  String get contactsEnterInviteCodeWaveBNote =>
      'The encrypted handshake with the relay will be enabled once the relay infrastructure is deployed.';

  @override
  String get contactsEnterInviteCodeValid => 'Code format is valid';

  @override
  String contactsEnterInviteCodeInvitationId(String id) {
    return 'Invitation id: $id';
  }

  @override
  String get contactsHandshakeNotAvailableYet =>
      'The relay handshake is not available yet. The code is valid locally, but cannot be redeemed until the relay is live.';

  @override
  String get contactsCodeErrorEmpty => 'Enter a code to continue.';

  @override
  String get contactsCodeErrorTooShort => 'This code is too short.';

  @override
  String get contactsCodeErrorTooLong => 'This code is too long.';

  @override
  String get contactsCodeErrorInvalidCharacters =>
      'This code contains characters that are not allowed.';

  @override
  String get contactsCodeErrorBadChecksum =>
      'This code looks mistyped. Check the characters and try again.';

  @override
  String get contactsCodeErrorUnsupportedVersion =>
      'This code was created by a newer version of the app.';

  @override
  String get contactsKindLocalOnly => 'Local only';

  @override
  String get contactsKindConnected => 'Connected';

  @override
  String get contactsKindBlocked => 'Blocked';

  @override
  String get contactsKindDeleted => 'Deleted';

  @override
  String get contactsFieldNameLabel => 'Name';

  @override
  String get contactsFieldNameHint => 'How this person appears in the app';

  @override
  String get contactsFieldAvatarLabel => 'Avatar';

  @override
  String get contactsFieldNotesLabel => 'Notes';

  @override
  String get contactsFieldNotesHint => 'Personal reminder, not shared';

  @override
  String get contactsDeleteTitle => 'Delete contact?';

  @override
  String get contactsDeleteBody =>
      'Existing housing or vehicle entries that reference this contact will keep their stored name and avatar. You can re-add the contact later.';

  @override
  String get contactsDeletePreservesHistory =>
      'Existing entries that reference this contact keep their stored name and avatar.';

  @override
  String get contactsBlockTitle => 'Block this contact?';

  @override
  String get contactsBlockBody =>
      'Incoming messages from this contact will be ignored locally. The relay is not informed of the block.';

  @override
  String get contactsUnblockTitle => 'Unblock this contact?';

  @override
  String get contactsUnblockBody =>
      'Incoming messages from this contact will be processed again.';
}
