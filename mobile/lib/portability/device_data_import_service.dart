import 'dart:convert';

import '../db/app_database.dart';
import '../relay/envelopes.dart';
import '../relay/relay_client.dart';
import 'device_data_export_service.dart';
import 'device_data_snapshot_codec.dart';
import 'pending_installation_migration_store.dart';

class DeviceDataImportValidationException implements Exception {
  DeviceDataImportValidationException(this.code, [this.detail = '']);

  final String code;
  final String detail;

  @override
  String toString() => 'DeviceDataImportValidationException($code, $detail)';
}

class DeviceDataMigrationException implements Exception {
  DeviceDataMigrationException(this.code, [this.detail = '']);

  final String code;
  final String detail;

  bool get isTransportFailure => code == 'relay_unreachable';

  @override
  String toString() => 'DeviceDataMigrationException($code, $detail)';
}

/// Parses, validates, and applies a full-device backup; orchestrates migration.
class DeviceDataImportService {
  DeviceDataImportService({
    required AppDatabase db,
    required RelayClient relay,
    required PendingInstallationMigrationStore pendingStore,
  })  : _db = db,
        _relay = relay,
        _pendingStore = pendingStore;

  final AppDatabase _db;
  final RelayClient _relay;
  final PendingInstallationMigrationStore _pendingStore;

  static const supportedFormatVersion = DeviceDataExportService.formatVersion;

  Future<Map<String, Object?>> parseAndValidateBundle(String jsonText) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw DeviceDataImportValidationException('invalid_json');
    }
    if (decoded is! Map<String, dynamic>) {
      throw DeviceDataImportValidationException('invalid_json');
    }
    final bundle = Map<String, Object?>.from(decoded);

    final version = bundle['formatVersion'];
    if (version is! int || version > supportedFormatVersion) {
      throw DeviceDataImportValidationException('unsupported_format_version');
    }
    if (bundle['bundleKind'] != DeviceDataExportService.bundleKind) {
      throw DeviceDataImportValidationException('unsupported_bundle_kind');
    }
    if (!await DeviceDataExportService.verifyChecksum(bundle)) {
      throw DeviceDataImportValidationException('checksum_mismatch');
    }

    final migration = bundle['migration'];
    if (migration is! Map) {
      throw DeviceDataImportValidationException('missing_migration_metadata');
    }
    final oldId = migration['participantInstallationId'];
    if (oldId is! String || oldId.isEmpty) {
      throw DeviceDataImportValidationException('missing_installation_id');
    }
    final planIds = migration['housingPlanIds'];
    if (planIds is! List || planIds.isEmpty) {
      throw DeviceDataImportValidationException('missing_housing_plan_id');
    }
    final tables = bundle['tables'];
    if (tables is! Map) {
      throw DeviceDataImportValidationException('missing_tables');
    }

    return bundle;
  }

  String oldInstallationIdFromBundle(Map<String, Object?> bundle) {
    final migration = bundle['migration']! as Map;
    return migration['participantInstallationId'] as String;
  }

  String primaryHousingPlanIdFromBundle(Map<String, Object?> bundle) {
    final migration = bundle['migration']! as Map;
    final planIds = migration['housingPlanIds'] as List;
    return planIds.first as String;
  }

  List<CanonicalRestoreChoice> canonicalRestoreChoices(
    Map<String, Object?> bundle,
  ) {
    if (bundle['canonicalRestore'] != true) return const [];
    final raw = bundle['participantRestoreChoices'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          CanonicalRestoreChoice(
            participantId: entry['participantId'] as String? ?? '',
            displayName: entry['displayName'] as String? ?? '',
          ),
    ].where((c) => c.participantId.isNotEmpty).toList();
  }

  Future<void> applyLocalImport(Map<String, Object?> bundle) async {
    final tables = Map<String, dynamic>.from(bundle['tables']! as Map);
    await importDeviceDataTables(_db, tables);
    await _db.syncWebStorageToDisk();
  }

  Future<void> persistPendingMigration({
    required String oldParticipantInstallationId,
    required String planId,
  }) {
    return _pendingStore.save(
      PendingInstallationMigration(
        oldParticipantInstallationId: oldParticipantInstallationId,
        planId: planId,
      ),
    );
  }

  Future<void> requestInstallationMigration({
    required String oldParticipantInstallationId,
    required String newParticipantInstallationId,
    required String planId,
  }) async {
    try {
      await _relay.migrateParticipantInstallation(
        planId: planId,
        oldParticipantInstallationId: oldParticipantInstallationId,
        newParticipantInstallationId: newParticipantInstallationId,
        envelopeKind: EnvelopeKind.participantInstallationMigration,
      );
      await _pendingStore.clear();
    } on RelayClientError catch (e) {
      throw DeviceDataMigrationException(e.code, e.detail);
    } on RelayUnreachableException {
      throw DeviceDataMigrationException('relay_unreachable');
    }
  }

  Future<void> retryPendingMigration(String newParticipantInstallationId) async {
    final pending = _pendingStore.read();
    if (pending == null) {
      throw DeviceDataMigrationException('no_pending_migration');
    }
    await requestInstallationMigration(
      oldParticipantInstallationId: pending.oldParticipantInstallationId,
      newParticipantInstallationId: newParticipantInstallationId,
      planId: pending.planId,
    );
  }
}

class CanonicalRestoreChoice {
  const CanonicalRestoreChoice({
    required this.participantId,
    required this.displayName,
  });

  final String participantId;
  final String displayName;
}
