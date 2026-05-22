import '../prefs/app_preferences.dart';

/// Reads/writes the housing plan mirror via [AppPreferences] (native / tests).
class HousingPlanDraftBackupPersist {
  const HousingPlanDraftBackupPersist._();

  static String? read(String planId, AppPreferences prefs) {
    var raw = prefs.housingPlanDraftBackupJson(planId);
    if ((raw == null || raw.isEmpty) && planId == 'housing:default') {
      raw = prefs.housingDefaultPlanDraftBackupJsonLegacy;
    }
    return raw;
  }

  static Future<void> write(
    String planId,
    String? json,
    AppPreferences prefs,
  ) async {
    await prefs.setHousingPlanDraftBackupJson(planId, json);
  }
}
