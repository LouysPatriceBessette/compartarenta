import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../vehicle/vehicle_meter_photo_path.dart';

/// SharedPreferences key set during [applyQaSharedPreferences] for Maestro runs.
const kQaE2eMeterPhotoOptionalPrefKey = 'qa.e2e.meterPhotoOptional';

/// Debug-only QA E2E flags applied by Android scenario seeding.
class QaE2eFlags {
  QaE2eFlags._();

  static bool _meterPhotoOptional = false;

  /// When true, vehicle meter photo pickers are optional and saves use
  /// [kVehicleMeterPhotoKnownUnchangedSentinel] when no photo was taken.
  static bool get meterPhotoOptional => kDebugMode && _meterPhotoOptional;

  static void setMeterPhotoOptional(bool value) {
    if (kDebugMode) {
      _meterPhotoOptional = value;
    }
  }

  static void syncMeterPhotoOptionalFromPrefs(SharedPreferences prefs) {
    setMeterPhotoOptional(
      prefs.getBool(kQaE2eMeterPhotoOptionalPrefKey) ?? false,
    );
  }
}

/// Loads QA E2E flags from SharedPreferences (debug builds).
///
/// Must run on every cold start — including Maestro [launchApp] after seeding,
/// when the in-memory flag would otherwise stay false.
Future<void> syncQaE2eFlagsFromPrefs() async {
  if (!kDebugMode) return;
  final prefs = await SharedPreferences.getInstance();
  QaE2eFlags.syncMeterPhotoOptionalFromPrefs(prefs);
}

/// Whether a meter photo must be present before enabling save.
bool qaE2eMeterPhotoRequired({required bool otherwiseRequired}) {
  if (QaE2eFlags.meterPhotoOptional) return false;
  return otherwiseRequired;
}

/// Resolves the persisted photo path, applying the QA E2E sentinel when needed.
String? qaE2eEffectiveMeterPhotoPath(String? pickedPath) {
  if (pickedPath != null && pickedPath.isNotEmpty) return pickedPath;
  if (QaE2eFlags.meterPhotoOptional) {
    return kVehicleMeterPhotoKnownUnchangedSentinel;
  }
  return null;
}
