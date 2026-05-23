// Web-only implementation (conditional export); package:web is intentional here.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;

import '../prefs/app_preferences.dart';

const _legacyKey = 'housing.default.planDraftBackupJson';

String _storageKey(String planId) =>
    'compartarenta.housing.planDraftBackup.$planId';

/// Reads/writes the housing plan mirror via synchronous [localStorage] on web.
class HousingPlanDraftBackupPersist {
  const HousingPlanDraftBackupPersist._();

  static String? read(String planId, AppPreferences prefs) {
    var raw = web.window.localStorage.getItem(_storageKey(planId));
    if ((raw == null || raw.isEmpty) && planId == 'housing:default') {
      raw = web.window.localStorage.getItem(_legacyKey);
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
      web.window.localStorage.removeItem(key);
      if (planId == 'housing:default') {
        web.window.localStorage.removeItem(_legacyKey);
      }
      return;
    }
    web.window.localStorage.setItem(key, json);
    // Keep SharedPreferences in sync when the plugin works; localStorage is
    // the source of truth for abrupt dev-server restarts.
    await prefs.setHousingPlanDraftBackupJson(planId, json);
  }
}
