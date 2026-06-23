import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';

import '../db/app_database.dart';
import '../housing/housing_plan_id.dart';
import 'device_data_snapshot_codec.dart';

/// Full-device operational export (`device-data-import-restore`).
class DeviceDataExportService {
  DeviceDataExportService(this._db);

  static const formatVersion = 1;
  static const bundleKind = 'device_full';

  final AppDatabase _db;

  Future<Map<String, Object?>> buildExportBundle({
    required String participantInstallationId,
  }) async {
    final tables = await exportDeviceDataTables(_db);
    final housingPlanIds = <String>[];
    for (final row in (tables['plans'] ?? const <Map<String, dynamic>>[])) {
      if (row['type'] != 'housing') continue;
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) continue;
      housingPlanIds.add(entitlementPlanIdForLocalPlan(id));
    }

    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'bundleKind': bundleKind,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'migration': <String, Object?>{
        'participantInstallationId': participantInstallationId,
        'housingPlanIds': housingPlanIds,
      },
      'tables': tables,
    };

    final checksum = await checksumForPayload(payload);
    return {...payload, 'checksum': checksum};
  }

  Future<String> exportJsonString({
    required String participantInstallationId,
  }) async {
    final bundle = await buildExportBundle(
      participantInstallationId: participantInstallationId,
    );
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  static Future<String> checksumForPayload(Map<String, Object?> payload) async {
    final canonical = jsonEncode(payload);
    final hash = await Sha256().hash(utf8.encode(canonical));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<bool> verifyChecksum(Map<String, Object?> bundle) async {
    final expected = bundle.remove('checksum');
    if (expected is! String || expected.isEmpty) return false;
    final actual = await checksumForPayload(bundle);
    bundle['checksum'] = expected;
    return actual == expected;
  }
}
