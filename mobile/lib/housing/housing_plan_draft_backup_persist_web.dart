import 'dart:html' as html;

import '../prefs/app_preferences.dart';

const _legacyKey = 'housing.default.planDraftBackupJson';

String _storageKey(String planId) =>
    'compartarenta.housing.planDraftBackup.$planId';

/// Reads/writes the housing plan mirror via synchronous [localStorage] on web.
class HousingPlanDraftBackupPersist {
  const HousingPlanDraftBackupPersist._();

  static String? read(String planId, AppPreferences prefs) {
    var raw = html.window.localStorage[_storageKey(planId)];
    if ((raw == null || raw.isEmpty) && planId == 'housing:default') {
      raw = html.window.localStorage[_legacyKey];
    }
    if (raw == null || raw.isEmpty) {
      raw = prefs.housingPlanDraftBackupJson(planId);
      if ((raw == null || raw.isEmpty) && planId == 'housing:default') {
        raw = prefs.housingDefaultPlanDraftBackupJsonLegacy;
      }
    }
    return raw;
  }

  static Future<void> write(
    String planId,
    String? json,
    AppPreferences prefs,
  ) async {
    final key = _storageKey(planId);
    if (json == null || json.isEmpty) {
      html.window.localStorage.remove(key);
      if (planId == 'housing:default') {
        html.window.localStorage.remove(_legacyKey);
      }
      return;
    }
    html.window.localStorage[key] = json;
    // Keep SharedPreferences in sync when the plugin works; localStorage is
    // the source of truth for abrupt dev-server restarts.
    await prefs.setHousingPlanDraftBackupJson(planId, json);
  }
}
