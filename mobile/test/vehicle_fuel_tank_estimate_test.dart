import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_metrics.dart';
import 'package:compartarenta/vehicle/vehicle_fuel_tank_estimate.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full tank shows capacity when consumption history is insufficient', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    const vehicleId = 'vehicle:tank';
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
            volumeLiters: const Value(35),
            meterReadingValue: const Value(1750100),
            isFullTank: true,
            recordedByContactId: kVehicleOwnerSelfContactId,
          ),
        );

    final snapshot =
        await VehicleFuelTankEstimate(db).forVehicle(vehicleId);

    expect(snapshot, isNotNull);
    expect(snapshot!.volumeLiters, 80);
    expect(snapshot.isCalculated, isTrue);
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
