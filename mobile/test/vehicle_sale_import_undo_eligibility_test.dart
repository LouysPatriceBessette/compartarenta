import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_meter_photo_path.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late VehiclesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VehiclesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('manual create is not sale-import undoable', () async {
    final v = await repo.createVehicle(
      kind: VehicleKind.car,
      displayLabel: 'Manual',
      make: 'Toyota',
      model: 'Corolla',
      color: 'Blue',
      modelYear: 2020,
      fuelTankCapacityLiters: 50,
      oilChangeIntervalAmount: 50000,
      initialMeterValue: 1000,
      initialMeterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
    );
    expect(v.saleImportUndoAvailable, isFalse);
    expect(v.ownerContactId, kVehicleOwnerSelfContactId);
  });

  test('clearSaleImportUndoAvailable flips the flag', () async {
    final id = 'vehicle:undo-test';
    final now = DateTime.now().toUtc();
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: id,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: VehicleKind.car.wire,
            displayLabel: 'Imported',
            createdAt: now,
            updatedAt: now,
            saleImportUndoAvailable: const Value(true),
          ),
        );
    expect((await repo.getVehicle(id))!.saleImportUndoAvailable, isTrue);
    await repo.clearSaleImportUndoAvailable(id);
    expect((await repo.getVehicle(id))!.saleImportUndoAvailable, isFalse);
  });
}
