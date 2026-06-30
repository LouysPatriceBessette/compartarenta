import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_metrics.dart';
import 'package:compartarenta/vehicle/vehicle_fuel_tank_estimate.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses latest declared tank state from session end or fuel purchase', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    const vehicleId = 'vehicle:tank';
    final t0 = DateTime.utc(2026, 6, 30, 10);
    final t1 = DateTime.utc(2026, 6, 30, 11);
    final t2 = DateTime.utc(2026, 6, 30, 12);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            fuelTankCapacityLiters: const Value(80),
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t1,
            costMinor: 5000,
            currency: 'CAD',
            volumeLiters: const Value(80),
            meterReadingValue: const Value(1750000),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:end',
            vehicleId: vehicleId,
            value: 1750350,
            unit: 'odometer_km',
            photoPath: 'end.jpg',
            recordedAt: t2,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.sessionEnd.wire,
            isFullTank: const Value(false),
            tankFillFraction: const Value(62),
          ),
        );

    final snapshot =
        await VehicleFuelTankEstimate(db).forVehicle(vehicleId);

    expect(snapshot, isNotNull);
    expect(snapshot!.volumeLiters, closeTo(49.6, 0.01));
    expect(snapshot.isCalculated, isTrue);
  });

  test('shows full tank from fuel purchase when no session declaration', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    const vehicleId = 'vehicle:no_session';
    final t0 = DateTime.utc(2026, 6, 30, 10);
    final t1 = DateTime.utc(2026, 6, 30, 11);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            fuelTankCapacityLiters: const Value(80),
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t1,
            costMinor: 5000,
            currency: 'CAD',
            volumeLiters: const Value(80),
            meterReadingValue: const Value(1750000),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    final snapshot =
        await VehicleFuelTankEstimate(db).forVehicle(vehicleId);

    expect(snapshot, isNotNull);
    expect(snapshot!.volumeLiters, closeTo(80, 0.01));
    expect(snapshot.isCalculated, isTrue);
  });

  test('newer fuel purchase overrides older session end tank state', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    const vehicleId = 'vehicle:fuel_after_session';
    final t0 = DateTime.utc(2026, 6, 30, 10);
    final t1 = DateTime.utc(2026, 6, 30, 11);
    final t2 = DateTime.utc(2026, 6, 30, 12);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            fuelTankCapacityLiters: const Value(80),
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:end',
            vehicleId: vehicleId,
            value: 1750350,
            unit: 'odometer_km',
            photoPath: 'end.jpg',
            recordedAt: t1,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.sessionEnd.wire,
            isFullTank: const Value(false),
            tankFillFraction: const Value(62),
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t2,
            costMinor: 5000,
            currency: 'CAD',
            volumeLiters: const Value(80),
            meterReadingValue: const Value(1750400),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    final snapshot =
        await VehicleFuelTankEstimate(db).forVehicle(vehicleId);

    expect(snapshot, isNotNull);
    expect(snapshot!.volumeLiters, closeTo(80, 0.01));
  });

  test('latestMeterValue prefers newer fuel purchase meter over older reading',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    const vehicleId = 'vehicle:meter';
    final t0 = DateTime.utc(2026, 6, 30, 10);
    final t1 = DateTime.utc(2026, 6, 30, 11);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:init',
            vehicleId: vehicleId,
            value: 1750000,
            unit: 'odometer_km',
            photoPath: 'init.jpg',
            recordedAt: t0,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.standalone.wire,
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t1,
            costMinor: 5000,
            currency: 'CAD',
            meterReadingValue: const Value(1750100),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    expect(await repo.latestMeterValue(vehicleId), 1750100);
  });

  test('distanceTenthsSinceLastFuelPurchase uses latest purchase meter', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    const vehicleId = 'vehicle:delta';
    final t0 = DateTime.utc(2026, 6, 30, 10);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t0,
            costMinor: 5000,
            currency: 'CAD',
            meterReadingValue: const Value(1750000),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    expect(
      await repo.distanceTenthsSinceLastFuelPurchase(
        vehicleId,
        currentMeterTenths: 1750350,
      ),
      350,
    );
  });

  test('totalLifetimeUsage spans initial reading to fuel purchase meter', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    const vehicleId = 'vehicle:stats';
    final t0 = DateTime.utc(2026, 6, 30, 10);
    final t1 = DateTime.utc(2026, 6, 30, 11);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Test',
            createdAt: t0,
            updatedAt: t0,
          ),
        );

    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:init',
            vehicleId: vehicleId,
            value: 1750000,
            unit: 'odometer_km',
            photoPath: 'init.jpg',
            recordedAt: t0,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.standalone.wire,
          ),
        );

    await db.into(db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: 'fuel:1',
            vehicleId: vehicleId,
            purchasedAt: t1,
            costMinor: 5000,
            currency: 'CAD',
            meterReadingValue: const Value(1750100),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    final total =
        await VehicleConsumptionMetrics(db).totalLifetimeUsage(vehicleId);

    expect(total, 100);
  });
}
