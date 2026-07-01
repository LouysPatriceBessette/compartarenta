import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import '../vehicle/vehicle_consumption_estimation_mode.dart';
import '../vehicle/vehicle_kind.dart';
import '../vehicle/vehicle_meter_photo_path.dart';

/// Display label for vehicle E2E seeds and flows.
const kQaVehicleE2eDisplayLabel = 'QA Civic';

/// Initial odometer for vehicle E2E seeds: 50 000.0 km (stored tenths).
const kQaVehicleE2eInitialMeterTenths = 500000;

/// Oil-change interval for vehicle E2E seeds: 5 × 1000 km.
const kQaVehicleE2eOilChangeIntervalTenths = 50000;

Future<Vehicle> qaSeedE2eVehicle(AppDatabase db) {
  final repo = VehiclesRepository(db);
  return repo.createVehicle(
    kind: VehicleKind.car,
    displayLabel: kQaVehicleE2eDisplayLabel,
    make: 'Honda',
    model: 'Civic',
    color: 'Bleu',
    modelYear: 2020,
    oilChangeIntervalAmount: kQaVehicleE2eOilChangeIntervalTenths,
    initialMeterValue: kQaVehicleE2eInitialMeterTenths,
    initialMeterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
    fuelTankCapacityLiters: 60,
    consumptionEstimationMode: VehicleConsumptionEstimationMode.simple,
  );
}
