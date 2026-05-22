import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistanceUnit { km, miles }

enum PlanType { housing, carSharing }

class AppPreferences extends ChangeNotifier {
  AppPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingComplete = 'onboarding.complete';
  static const _kOnboardingStep = 'onboarding.step';
  static const _kOnboardingLanguageDone = 'onboarding.languageDone';
  static const _kOnboardingWelcomeDone = 'onboarding.welcomeDone';

  static const _kDisplayName = 'profile.displayName';
  static const _kAvatarId = 'profile.avatarId';

  static const _kPlanTypes = 'plans.enabled';

  static const _kCurrency = 'prefs.currency';
  static const _kDateFormat = 'prefs.dateFormat';
  static const _kDistanceUnit = 'prefs.distanceUnit';
  static const _kTimeZonePolicy = 'prefs.timeZonePolicy';
  static const _kLanguageCode = 'prefs.languageCode';

  static const _kNotificationsEnabled = 'notifications.enabled';
  static const _kNotificationsContactAddRequests =
      'notifications.contacts.addRequests';
  static const _kNotificationsContactDisconnection =
      'notifications.contacts.disconnection';
  static const _kNotificationsContactInvitationExpiration =
      'notifications.contacts.invitationExpiration';
  static const _kNotificationsHousingPlanSubmission =
      'notifications.housing.planSubmission';
  static const _kNotificationsHousingDecisionChange =
      'notifications.housing.decisionChange';
  static const _kNotificationsHousingOfferExpiration =
      'notifications.housing.offerExpiration';
  static const _kNotificationsSoundEnabled = 'notifications.sound.enabled';
  static const _kNotificationsCountryStatsEnabled =
      'notifications.countryStats.enabled';
  static const _kNotificationsCountryStatsCode =
      'notifications.countryStats.isoCode';

  /// Default housing draft plan reached the post-wizard summary at least once.
  static const _kHousingDefaultSummaryReached =
      'housing.default.summaryReached';
  /// Legacy single-plan backup key (v1); migrated on read for [housing:default].
  static const _kHousingDefaultPlanDraftBackupLegacy =
      'housing.default.planDraftBackupJson';
  static const _kCarSharingPlanDraft = 'carSharing.planDraftJson';

  static String _housingPlanDraftBackupKey(String planId) =>
      'housing.planDraftBackup.$planId';

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._(prefs);
  }

  bool get onboardingComplete => _prefs.getBool(_kOnboardingComplete) ?? false;

  String? get onboardingStep => _prefs.getString(_kOnboardingStep);
  Future<void> setOnboardingStep(String? value) async {
    if (value == null) {
      await _prefs.remove(_kOnboardingStep);
    } else {
      await _prefs.setString(_kOnboardingStep, value);
    }
    notifyListeners();
  }

  bool get onboardingLanguageDone =>
      _prefs.getBool(_kOnboardingLanguageDone) ?? false;
  Future<void> setOnboardingLanguageDone(bool value) async {
    await _prefs.setBool(_kOnboardingLanguageDone, value);
    notifyListeners();
  }

  bool get onboardingWelcomeDone =>
      _prefs.getBool(_kOnboardingWelcomeDone) ?? false;
  Future<void> setOnboardingWelcomeDone(bool value) async {
    await _prefs.setBool(_kOnboardingWelcomeDone, value);
    notifyListeners();
  }

  String get displayName => _prefs.getString(_kDisplayName) ?? '';
  Future<void> setDisplayName(String value) async {
    await _prefs.setString(_kDisplayName, value.trim());
    notifyListeners();
  }

  String get avatarId => _prefs.getString(_kAvatarId) ?? '';
  Future<void> setAvatarId(String value) async {
    await _prefs.setString(_kAvatarId, value);
    notifyListeners();
  }

  /// Sets display name and avatar in one step with a single [notifyListeners]
  /// so router listeners do not rebuild twice (avoids visible flicker).
  Future<void> setProfileIdentity({
    required String displayName,
    required String avatarId,
  }) async {
    await _prefs.setString(_kDisplayName, displayName.trim());
    await _prefs.setString(_kAvatarId, avatarId);
    notifyListeners();
  }

  Set<PlanType> get planTypes {
    final raw = _prefs.getStringList(_kPlanTypes) ?? const <String>[];
    return raw
        .map((e) => PlanType.values.where((p) => p.name == e).firstOrNull)
        .whereType<PlanType>()
        .toSet();
  }

  Future<void> setPlanTypes(Set<PlanType> value) async {
    await _prefs.setStringList(_kPlanTypes, value.map((e) => e.name).toList());
    notifyListeners();
  }

  String get currency => _prefs.getString(_kCurrency) ?? '';
  Future<void> setCurrency(String value) async {
    await _prefs.setString(_kCurrency, value);
    notifyListeners();
  }

  String get dateFormat => _prefs.getString(_kDateFormat) ?? '';
  Future<void> setDateFormat(String value) async {
    await _prefs.setString(_kDateFormat, value);
    notifyListeners();
  }

  DistanceUnit? get distanceUnit {
    final raw = _prefs.getString(_kDistanceUnit);
    return DistanceUnit.values.where((u) => u.name == raw).firstOrNull;
  }

  Future<void> setDistanceUnit(DistanceUnit value) async {
    await _prefs.setString(_kDistanceUnit, value.name);
    notifyListeners();
  }

  String get timeZonePolicy => _prefs.getString(_kTimeZonePolicy) ?? 'device';
  Future<void> setTimeZonePolicy(String value) async {
    await _prefs.setString(_kTimeZonePolicy, value);
    notifyListeners();
  }

  String? get languageCode => _prefs.getString(_kLanguageCode);
  Future<void> setLanguageCode(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_kLanguageCode);
    } else {
      await _prefs.setString(_kLanguageCode, value);
    }
    notifyListeners();
  }

  bool _notificationBool(String key, {bool defaultValue = true}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> _setNotificationBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
  }

  bool get notificationsEnabled =>
      _notificationBool(_kNotificationsEnabled, defaultValue: false);
  Future<void> setNotificationsEnabled(bool value) =>
      _setNotificationBool(_kNotificationsEnabled, value);

  bool get notificationContactAddRequests =>
      _notificationBool(_kNotificationsContactAddRequests);
  Future<void> setNotificationContactAddRequests(bool value) =>
      _setNotificationBool(_kNotificationsContactAddRequests, value);

  bool get notificationContactDisconnection =>
      _notificationBool(_kNotificationsContactDisconnection);
  Future<void> setNotificationContactDisconnection(bool value) =>
      _setNotificationBool(_kNotificationsContactDisconnection, value);

  bool get notificationContactInvitationExpiration =>
      _notificationBool(_kNotificationsContactInvitationExpiration);
  Future<void> setNotificationContactInvitationExpiration(bool value) =>
      _setNotificationBool(_kNotificationsContactInvitationExpiration, value);

  bool get notificationHousingPlanSubmission =>
      _notificationBool(_kNotificationsHousingPlanSubmission);
  Future<void> setNotificationHousingPlanSubmission(bool value) =>
      _setNotificationBool(_kNotificationsHousingPlanSubmission, value);

  bool get notificationHousingDecisionChange =>
      _notificationBool(_kNotificationsHousingDecisionChange);
  Future<void> setNotificationHousingDecisionChange(bool value) =>
      _setNotificationBool(_kNotificationsHousingDecisionChange, value);

  bool get notificationHousingOfferExpiration =>
      _notificationBool(_kNotificationsHousingOfferExpiration);
  Future<void> setNotificationHousingOfferExpiration(bool value) =>
      _setNotificationBool(_kNotificationsHousingOfferExpiration, value);

  bool get notificationSoundEnabled =>
      _notificationBool(_kNotificationsSoundEnabled);
  Future<void> setNotificationSoundEnabled(bool value) =>
      _setNotificationBool(_kNotificationsSoundEnabled, value);

  /// When true, the user allows sending a two-letter country code with
  /// routing push registration for aggregated relay statistics.
  bool get notificationCountryStatisticsEnabled =>
      _prefs.getBool(_kNotificationsCountryStatsEnabled) ?? false;

  Future<void> setNotificationCountryStatisticsEnabled(bool value) async {
    await _prefs.setBool(_kNotificationsCountryStatsEnabled, value);
    if (!value) {
      await _prefs.remove(_kNotificationsCountryStatsCode);
    }
    notifyListeners();
  }

  /// Two-letter ISO 3166-1 alpha-2 code when [notificationCountryStatisticsEnabled].
  String? get notificationCountryStatisticsCode =>
      _prefs.getString(_kNotificationsCountryStatsCode);

  Future<void> setNotificationCountryStatisticsCode(String? isoAlpha2) async {
    if (isoAlpha2 == null || isoAlpha2.isEmpty) {
      await _prefs.remove(_kNotificationsCountryStatsCode);
    } else {
      await _prefs.setString(
        _kNotificationsCountryStatsCode,
        isoAlpha2.trim().toUpperCase(),
      );
    }
    notifyListeners();
  }

  /// Value sent on routing push registration (`UNDISCLOSED` when disabled).
  String get countryCodeForRoutingPushRegistration {
    if (!notificationCountryStatisticsEnabled) {
      return 'UNDISCLOSED';
    }
    final raw = notificationCountryStatisticsCode;
    if (raw == null || raw.length != 2) {
      return 'UNDISCLOSED';
    }
    return raw.toUpperCase();
  }

  bool get hasProfile => displayName.isNotEmpty && avatarId.isNotEmpty;
  bool get hasRegionalPrefs =>
      currency.isNotEmpty && dateFormat.isNotEmpty && distanceUnit != null;
  bool get hasPlanSelection => planTypes.isNotEmpty;

  bool get housingDefaultPlanSummaryReached =>
      _prefs.getBool(_kHousingDefaultSummaryReached) ?? false;

  Future<void> setHousingDefaultPlanSummaryReached(bool value) async {
    await _prefs.setBool(_kHousingDefaultSummaryReached, value);
    notifyListeners();
  }

  String? housingPlanDraftBackupJson(String planId) =>
      _prefs.getString(_housingPlanDraftBackupKey(planId));

  Future<void> setHousingPlanDraftBackupJson(String planId, String? value) async {
    final key = _housingPlanDraftBackupKey(planId);
    if (value == null || value.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  /// One-time read of the pre–per-plan backup key (housing:default only).
  String? get housingDefaultPlanDraftBackupJsonLegacy =>
      _prefs.getString(_kHousingDefaultPlanDraftBackupLegacy);

  Future<void> clearHousingDefaultPlanDraftBackupLegacy() async {
    await _prefs.remove(_kHousingDefaultPlanDraftBackupLegacy);
  }

  String get carSharingPlanDraftJson =>
      _prefs.getString(_kCarSharingPlanDraft) ?? '';

  Future<void> setCarSharingPlanDraftJson(
    String value, {
    bool notify = true,
  }) async {
    await _prefs.setString(_kCarSharingPlanDraft, value);
    if (notify) notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kOnboardingComplete, true);
    await _prefs.remove(_kOnboardingStep);
    await _prefs.remove(_kOnboardingLanguageDone);
    await _prefs.remove(_kOnboardingWelcomeDone);
    notifyListeners();
  }

  /// Development convenience: clears onboarding and user preferences.
  ///
  /// This is meant to help iterate during development. It MUST NOT be triggered
  /// automatically in release builds.
  Future<void> resetOnboardingAndPreferences() async {
    await _prefs.remove(_kOnboardingComplete);
    await _prefs.remove(_kOnboardingStep);
    await _prefs.remove(_kOnboardingLanguageDone);
    await _prefs.remove(_kOnboardingWelcomeDone);

    await _prefs.remove(_kDisplayName);
    await _prefs.remove(_kAvatarId);
    await _prefs.remove(_kPlanTypes);

    await _prefs.remove(_kCurrency);
    await _prefs.remove(_kDateFormat);
    await _prefs.remove(_kDistanceUnit);
    await _prefs.remove(_kTimeZonePolicy);
    await _prefs.remove(_kLanguageCode);

    await _prefs.remove(_kNotificationsEnabled);
    await _prefs.remove(_kNotificationsContactAddRequests);
    await _prefs.remove(_kNotificationsContactDisconnection);
    await _prefs.remove(_kNotificationsContactInvitationExpiration);
    await _prefs.remove(_kNotificationsHousingPlanSubmission);
    await _prefs.remove(_kNotificationsHousingDecisionChange);
    await _prefs.remove(_kNotificationsHousingOfferExpiration);
    await _prefs.remove(_kNotificationsSoundEnabled);
    await _prefs.remove(_kNotificationsCountryStatsEnabled);
    await _prefs.remove(_kNotificationsCountryStatsCode);

    await _prefs.remove(_kHousingDefaultSummaryReached);
    await _prefs.remove(_kCarSharingPlanDraft);

    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
