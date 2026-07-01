import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa_e2e_meter_photo.dart';

/// File persisted under the app documents directory during QA scenario seeding.
///
/// Maestro cold-starts the app after seeding without re-running the seed
/// marker; this file restores E2E prefs (locale, optional meter photo).
const kQaE2eEnvFileName = 'compartarenta_qa_e2e_env.json';

/// SharedPreferences key recording the last seeded scenario (debug QA).
const kQaE2eLastScenarioIdPrefKey = 'qa.e2e.lastScenarioId';

class QaE2eEnvironmentSnapshot {
  const QaE2eEnvironmentSnapshot({
    required this.scenarioId,
    required this.languageCode,
    required this.meterPhotoOptional,
  });

  final String scenarioId;
  final String languageCode;
  final bool meterPhotoOptional;

  Map<String, Object?> toJson() => {
        'scenarioId': scenarioId,
        'languageCode': languageCode,
        'meterPhotoOptional': meterPhotoOptional,
      };

  static QaE2eEnvironmentSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final scenarioId = raw['scenarioId'];
    final languageCode = raw['languageCode'];
    final meterPhotoOptional = raw['meterPhotoOptional'];
    if (scenarioId is! String ||
        scenarioId.isEmpty ||
        languageCode is! String ||
        languageCode.isEmpty ||
        meterPhotoOptional is! bool) {
      return null;
    }
    return QaE2eEnvironmentSnapshot(
      scenarioId: scenarioId,
      languageCode: languageCode,
      meterPhotoOptional: meterPhotoOptional,
    );
  }
}

Future<File?> _qaE2eEnvFile() async {
  if (kIsWeb) return null;
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$kQaE2eEnvFileName');
  } catch (e) {
    debugPrint('qa e2e env: could not resolve documents directory: $e');
    return null;
  }
}

Future<void> applyQaE2eEnvironmentSnapshot(
  QaE2eEnvironmentSnapshot snapshot, {
  SharedPreferences? prefs,
}) async {
  final shared = prefs ?? await SharedPreferences.getInstance();
  await shared.setString(kQaE2eLastScenarioIdPrefKey, snapshot.scenarioId);
  await shared.setString('prefs.languageCode', snapshot.languageCode);
  await shared.setBool(
    kQaE2eMeterPhotoOptionalPrefKey,
    snapshot.meterPhotoOptional,
  );
  QaE2eFlags.setMeterPhotoOptional(snapshot.meterPhotoOptional);
}

/// Writes the durable QA E2E snapshot (locale + optional meter photo).
Future<void> persistQaE2eEnvironment({
  required String scenarioId,
  String languageCode = 'fr',
  bool meterPhotoOptional = true,
}) async {
  if (!kDebugMode || kIsWeb) return;
  final snapshot = QaE2eEnvironmentSnapshot(
    scenarioId: scenarioId,
    languageCode: languageCode,
    meterPhotoOptional: meterPhotoOptional,
  );
  await applyQaE2eEnvironmentSnapshot(snapshot);
  final file = await _qaE2eEnvFile();
  if (file == null) return;
  await file.writeAsString(jsonEncode(snapshot.toJson()));
  debugPrint('qa e2e env: persisted ${snapshot.scenarioId}');
}

/// Restores QA E2E prefs on cold start (e.g. Maestro relaunch after seed).
Future<void> restoreQaE2eEnvironmentIfPresent() async {
  if (!kDebugMode || kIsWeb) return;
  final file = await _qaE2eEnvFile();
  if (file == null || !await file.exists()) return;
  try {
    final snapshot = QaE2eEnvironmentSnapshot.fromJson(
      jsonDecode(await file.readAsString()),
    );
    if (snapshot == null) {
      debugPrint('qa e2e env: ignored invalid snapshot file');
      return;
    }
    await applyQaE2eEnvironmentSnapshot(snapshot);
    debugPrint('qa e2e env: restored ${snapshot.scenarioId}');
  } catch (e) {
    debugPrint('qa e2e env: restore failed: $e');
  }
}
