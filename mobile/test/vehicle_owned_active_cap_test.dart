import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_meter_photo_path.dart';
import 'package:compartarenta/vehicle/vehicle_owned_active_cap.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Vehicle> _createSample(
  VehiclesRepository repo, {
  required String label,
}) {
  return repo.createVehicle(
    kind: VehicleKind.car,
    displayLabel: label,
    make: 'Make',
    model: 'Model',
    color: 'Blue',
    modelYear: 2020,
    oilChangeIntervalAmount: 50000,
    initialMeterValue: 100000,
    initialMeterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
  );
}

void main() {
  test('blocks fourth active owned vehicle then allows after deactivate',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    final a = await _createSample(repo, label: 'A');
    final b = await _createSample(repo, label: 'B');
    await _createSample(repo, label: 'C');
    expect(await repo.countActiveOwnedVehicles(), kMaxActiveOwnedVehicles);

    await expectLater(
      _createSample(repo, label: 'D'),
      throwsA(isA<VehicleActiveCapExceededException>()),
    );

    await repo.deactivateOwnedVehicle(b.id);
    expect(vehicleIsActive((await repo.getVehicle(b.id))!), isFalse);
    expect(await repo.countActiveOwnedVehicles(), 2);

    final d = await _createSample(repo, label: 'D');
    expect(d.displayLabel, 'D');
    expect(await repo.countActiveOwnedVehicles(), 3);

    final listed = await repo.listOwnedVehicles();
    expect(listed.map((v) => v.displayLabel).toList(), ['A', 'C', 'D', 'B']);
    expect(listed.last.id, b.id);

    await expectLater(
      repo.saveFuelPurchase(
        vehicleId: b.id,
        purchasedAt: DateTime.now().toUtc(),
        costMinor: 100,
        currency: 'CAD',
        isFullTank: true,
        recordedByContactId: kVehicleOwnerSelfContactId,
      ),
      throwsA(isA<VehicleDeactivatedException>()),
    );

    await repo.saveFuelPurchase(
      vehicleId: a.id,
      purchasedAt: DateTime.now().toUtc(),
      costMinor: 100,
      currency: 'CAD',
      isFullTank: true,
      recordedByContactId: kVehicleOwnerSelfContactId,
    );
  });

  test('deactivate refused while use session is open', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final repo = VehiclesRepository(db);
    final vehicle = await _createSample(repo, label: 'Open');
    final reading = (await repo.listMeterReadings(vehicle.id)).first;
    await repo.openUseSession(
      vehicleId: vehicle.id,
      attributedContactId: kVehicleOwnerSelfContactId,
      startReadingId: reading.id,
    );

    await expectLater(
      repo.deactivateOwnedVehicle(vehicle.id),
      throwsA(isA<VehicleHasOpenUseException>()),
    );
  });
}
