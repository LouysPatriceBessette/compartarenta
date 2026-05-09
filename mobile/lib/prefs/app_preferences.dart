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

  /// Default housing draft plan reached the post-wizard summary at least once.
  static const _kHousingDefaultSummaryReached = 'housing.default.summaryReached';

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

    await _prefs.remove(_kHousingDefaultSummaryReached);

    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
