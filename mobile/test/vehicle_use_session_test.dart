import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latestMeterValue tolerates duplicate recordedAt timestamps', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    const vehicleId = 'vehicle:test1';
    final sameTime = DateTime.utc(2026, 6, 28, 22, 37);

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Shyrka',
            createdAt: sameTime,
            updatedAt: sameTime,
          ),
        );

    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:1',
            vehicleId: vehicleId,
            value: 1750000,
            unit: 'odometer_km',
            photoPath: 'a.jpg',
            recordedAt: sameTime,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.standalone.wire,
          ),
        );
    await db.into(db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: 'meter:2',
            vehicleId: vehicleId,
            value: 1750000,
            unit: 'odometer_km',
            photoPath: 'b.jpg',
            recordedAt: sameTime,
            recordedByContactId: kVehicleOwnerSelfContactId,
            readingRole: MeterReadingRole.sessionStart.wire,
          ),
        );

    expect(await repo.latestMeterValue(vehicleId), 1750000);
  });

  test('start and close use session', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    final now = DateTime.now().toUtc();
    const vehicleId = 'vehicle:test2';
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Shyrka',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final startReading = await repo.saveMeterReading(
      vehicleId: vehicleId,
      value: 1750000,
      unit: 'odometer_km',
      photoPath: 'photos/start.jpg',
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionStart,
    );

    final use = await repo.openUseSession(
      vehicleId: vehicleId,
      attributedContactId: kVehicleOwnerSelfContactId,
      startReadingId: startReading.id,
    );

    final endReading = await repo.saveMeterReading(
      vehicleId: vehicleId,
      value: 1750050,
      unit: 'odometer_km',
      photoPath: 'photos/end.jpg',
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionEnd,
      vehicleUseId: use.id,
    );

    final closed = await repo.closeUseSession(
      useId: use.id,
      endReadingId: endReading.id,
    );
    expect(closed.endedAt, isNotNull);
    expect(closed.usageAmount, 50);
    expect(await repo.openUseForVehicle(vehicleId), isNull);
  });
}
