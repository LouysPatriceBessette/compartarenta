import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Installation identities that have consumed housing trial eligibility.
class HousingTrialConsumptionStore {
  HousingTrialConsumptionStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _consumedIdsKey =
      'entitlement.housing_trial_consumed_installations.v1';

  static Future<HousingTrialConsumptionStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HousingTrialConsumptionStore(prefs);
  }

  Set<String> consumedInstallationIds() {
    final raw = _prefs.getString(_consumedIdsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return {
        for (final entry in list)
          if (entry is String && entry.isNotEmpty) entry,
      };
    } catch (_) {
      return {};
    }
  }

  bool isConsumed(String installationId) {
    if (installationId.isEmpty) return false;
    return consumedInstallationIds().contains(installationId);
  }

  bool anyConsumed(Iterable<String> installationIds) {
    final consumed = consumedInstallationIds();
    for (final id in installationIds) {
      if (id.isNotEmpty && consumed.contains(id)) return true;
    }
    return false;
  }

  Future<void> markConsumed(String installationId) async {
    if (installationId.isEmpty) return;
    final next = consumedInstallationIds()..add(installationId);
    await _prefs.setString(_consumedIdsKey, jsonEncode(next.toList()..sort()));
  }

  static String _planTrialEligibleKey(String planId) =>
      'housing.plan_trial_eligible.$planId';

  Future<void> setPlanTrialEligible(String planId, bool eligible) async {
    await _prefs.setBool(_planTrialEligibleKey(planId), eligible);
  }

  bool? planTrialEligible(String planId) =>
      _prefs.getBool(_planTrialEligibleKey(planId));

  /// FOR TESTS ONLY.
  Future<void> clearForTesting() async {
    await _prefs.remove(_consumedIdsKey);
  }
}
