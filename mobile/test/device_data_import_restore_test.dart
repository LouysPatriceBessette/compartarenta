import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_plan_id.dart';
import 'package:compartarenta/portability/device_data_export_service.dart';
import 'package:compartarenta/portability/device_data_import_service.dart';
import 'package:compartarenta/portability/device_data_snapshot_codec.dart';
import 'package:compartarenta/portability/pending_installation_migration_store.dart';
import 'package:compartarenta/portability/store_import_gate.dart';
import 'package:compartarenta/relay/envelopes.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

Future<void> _seedPlan(_DbForTesting db) async {
  await db.upsertPlan(
    PlansCompanion.insert(
      id: 'plan:a',
      type: 'housing',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store_import_gate', () {
    test('dev fake allows import in debug mode', () async {
      final gate = DevFakeStoreImportGate();
      expect(await gate.hasActiveHousingSubscription(), isTrue);
    });

    test('release gate denies import', () async {
      expect(
        await ReleaseStoreImportGate().hasActiveHousingSubscription(),
        isFalse,
      );
    });
  });

  group('device_data_export_service', () {
    test('round-trip checksum and migration metadata', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPlan(db);
      final service = DeviceDataExportService(db);
      final bundle = await service.buildExportBundle(
        participantInstallationId: 'inst-export-test',
      );
      expect(bundle['formatVersion'], DeviceDataExportService.formatVersion);
      expect(bundle['bundleKind'], DeviceDataExportService.bundleKind);
      final migration = bundle['migration']! as Map;
      expect(migration['participantInstallationId'], 'inst-export-test');
      expect(migration['housingPlanIds'], [entitlementPlanIdForLocalPlan('plan:a')]);
      expect(await DeviceDataExportService.verifyChecksum(bundle), isTrue);
      bundle['tables'] = <String, dynamic>{};
      expect(await DeviceDataExportService.verifyChecksum(bundle), isFalse);
    });

    test('pretty-printed export file verifies checksum', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPlan(db);
      await db.into(db.participants).insert(
            ParticipantsCompanion.insert(
              id: 'participant:self',
              displayName: 'Louÿs',
              avatarId: 'avatar:1',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          );
      final service = DeviceDataExportService(db);
      final jsonText = await service.exportJsonString(
        participantInstallationId: 'inst-export-test',
      );
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final bundle = Map<String, Object?>.from(decoded);
      expect(await DeviceDataExportService.verifyChecksum(bundle), isTrue);
    });

    test('maps received local plan id to entitlement housing plan id', () async {
      const uuid = '613fc48d-6d8b-4055-8fee-1eace9e92678';
      final localPlanId = 'received:$uuid';
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertPlan(
        PlansCompanion.insert(
          id: localPlanId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final bundle = await DeviceDataExportService(db).buildExportBundle(
        participantInstallationId: 'inst-export-test',
      );
      final migration = bundle['migration']! as Map;
      expect(migration['housingPlanIds'], ['613fc48d-6d8b-4055-8fee-1eace9e92678']);
    });

    test('import migration uses entitlement plan id from received backup', () async {
      const uuid = '613fc48d-6d8b-4055-8fee-1eace9e92678';
      SharedPreferences.setMockInitialValues({});
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertPlan(
        PlansCompanion.insert(
          id: 'received:$uuid',
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final relay = FakeRelayClient();
      final pending = await PendingInstallationMigrationStore.load();
      final service = DeviceDataImportService(
        db: db,
        relay: relay,
        pendingStore: pending,
      );
      final json = await DeviceDataExportService(db).exportJsonString(
        participantInstallationId: 'inst-old',
      );
      final parsed = await service.parseAndValidateBundle(json);
      expect(
        service.primaryHousingPlanIdFromBundle(parsed),
        uuid,
      );
      await service.requestInstallationMigration(
        oldParticipantInstallationId: 'inst-old',
        newParticipantInstallationId: 'inst-new123456',
        planId: 'received:$uuid',
      );
      expect(relay.installationMigrations.single.planId, uuid);
    });
  });

  group('device_data_import_service', () {
    test('validation, local import, and migration envelope', () async {
      SharedPreferences.setMockInitialValues({});
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPlan(db);
      final relay = FakeRelayClient();
      final pending = await PendingInstallationMigrationStore.load();
      final service = DeviceDataImportService(
        db: db,
        relay: relay,
        pendingStore: pending,
      );

      expect(
        () => service.parseAndValidateBundle('not-json'),
        throwsA(isA<DeviceDataImportValidationException>()),
      );

      final validJson = await DeviceDataExportService(db).exportJsonString(
        participantInstallationId: 'inst-old',
      );
      final parsed = await service.parseAndValidateBundle(validJson);
      await service.applyLocalImport(parsed);
      expect(await deviceOperationalDataIsEmpty(db), isFalse);
      await service.persistPendingMigration(
        oldParticipantInstallationId: 'inst-old',
        planId: 'plan:a',
      );
      await service.requestInstallationMigration(
        oldParticipantInstallationId: 'inst-old',
        newParticipantInstallationId: 'inst-new123456',
        planId: 'plan:a',
      );
      expect(relay.installationMigrations, hasLength(1));
      expect(
        relay.installationMigrations.single.envelopeKind,
        EnvelopeKind.participantInstallationMigration,
      );
      expect(pending.read(), isNull);
    });

    test('import replaces existing operational rows', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPlan(db);
      final json = await DeviceDataExportService(db).exportJsonString(
        participantInstallationId: 'inst-old',
      );
      await db.upsertPlan(
        PlansCompanion.insert(
          id: 'plan:other',
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );
      final relay = FakeRelayClient();
      final pending = await PendingInstallationMigrationStore.load();
      final service = DeviceDataImportService(
        db: db,
        relay: relay,
        pendingStore: pending,
      );
      final parsed = await service.parseAndValidateBundle(json);
      await service.applyLocalImport(parsed);
      final plans = await db.select(db.plans).get();
      expect(plans.map((p) => p.id), ['plan:a']);
    });

    test('transport failure keeps pending migration', () async {
      SharedPreferences.setMockInitialValues({});
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPlan(db);
      final relay = FakeRelayClient()..migrationUnreachableOnce = true;
      final pending = await PendingInstallationMigrationStore.load();
      final service = DeviceDataImportService(
        db: db,
        relay: relay,
        pendingStore: pending,
      );
      await service.persistPendingMigration(
        oldParticipantInstallationId: 'inst-old',
        planId: 'plan:a',
      );
      await expectLater(
        service.requestInstallationMigration(
          oldParticipantInstallationId: 'inst-old',
          newParticipantInstallationId: 'inst-new123456',
          planId: 'plan:a',
        ),
        throwsA(
          isA<DeviceDataMigrationException>().having(
            (e) => e.isTransportFailure,
            'transport failure',
            isTrue,
          ),
        ),
      );
      expect(relay.installationMigrations, isEmpty);
      expect(pending.read()?.oldParticipantInstallationId, 'inst-old');
    });

    test('validation failure does not call relay migration', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final relay = FakeRelayClient();
      final pending = await PendingInstallationMigrationStore.load();
      final service = DeviceDataImportService(
        db: db,
        relay: relay,
        pendingStore: pending,
      );
      await expectLater(
        () => service.parseAndValidateBundle('{"formatVersion":99}'),
        throwsA(isA<DeviceDataImportValidationException>()),
      );
      expect(relay.installationMigrations, isEmpty);
    });
  });
}
