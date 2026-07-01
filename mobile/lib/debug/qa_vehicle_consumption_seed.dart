import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import '../vehicle/vehicle_consumption_estimation_mode.dart';
import '../vehicle/vehicle_kind.dart';
import '../vehicle/vehicle_meter_photo_path.dart';
import '../vehicle/vehicle_owner_contact.dart';
import 'qa_vehicle_seed_helpers.dart';

/// Odometer (stored tenths) after all seeded sessions in [qaSeedVehicleConsumptionScenario].
const kQaVehicleConsumptionFinalMeterTenths = 513970;

/// User entry #0 — point de départ odometer (50 000 km).
const kQaVehicleConsumptionEntry0MeterTenths = 500000;

/// User entry #0 — achat 60 L, 120 CAD, plein à 50 000 km.
const kQaVehicleConsumptionFuelPurchase0VolumeLiters = 60.0;
const kQaVehicleConsumptionFuelPurchase0CostMinor = 12000;

/// User entry #6 — 43 L, 86 CAD, full tank at 50 630 km.
const kQaVehicleConsumptionFuelPurchase6MeterTenths = 506300;
const kQaVehicleConsumptionFuelPurchase6VolumeLiters = 43.0;
const kQaVehicleConsumptionFuelPurchase6CostMinor = 8600;

/// User entry #11 — full-tank fuel purchase odometer (50 885 km).
const kQaVehicleConsumptionFuelPurchase11MeterTenths = 508850;

/// User entry #11 — 18 L, 36 CAD, full tank.
const kQaVehicleConsumptionFuelPurchase11VolumeLiters = 18.0;
const kQaVehicleConsumptionFuelPurchase11CostMinor = 3600;

/// User entry #16 — full-tank fuel purchase odometer (51 397 km).
const kQaVehicleConsumptionFuelPurchase16MeterTenths = 513970;

/// User entry #16 — 35.4 L, 70.80 CAD, full tank.
const kQaVehicleConsumptionFuelPurchase16VolumeLiters = 35.4;
const kQaVehicleConsumptionFuelPurchase16CostMinor = 7080;

/// Base timestamp for the chronological consumption E2E entries.
DateTime qaVehicleConsumptionSeedBaseTime() => DateTime.utc(2027, 6, 1, 12);

/// Seeds the QA Civic with detailed consumption mode and user entries #0–#16.
Future<Vehicle> qaSeedVehicleConsumptionScenario(AppDatabase db) async {
  final repo = VehiclesRepository(db);
  final vehicle = await repo.createVehicle(
    kind: VehicleKind.car,
    displayLabel: kQaVehicleE2eDisplayLabel,
    make: 'Honda',
    model: 'Civic',
    color: 'Bleu',
    modelYear: 2020,
    oilChangeIntervalAmount: kQaVehicleE2eOilChangeIntervalTenths,
    initialMeterValue: kQaVehicleConsumptionEntry0MeterTenths,
    initialMeterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
    fuelTankCapacityLiters: 60,
    consumptionEstimationMode: VehicleConsumptionEstimationMode.detailed,
  );

  final base = qaVehicleConsumptionSeedBaseTime();
  var dayOffset = 0;
  DateTime at(int days, {int hours = 0}) =>
      base.add(Duration(days: days, hours: hours));

  // #0 — achat 60 L, 120 $, plein à 50 000 km.
  await repo.saveFuelPurchase(
    vehicleId: vehicle.id,
    purchasedAt: at(dayOffset, hours: 7),
    costMinor: kQaVehicleConsumptionFuelPurchase0CostMinor,
    currency: 'CAD',
    isFullTank: true,
    recordedByContactId: kVehicleOwnerSelfContactId,
    volumeLiters: kQaVehicleConsumptionFuelPurchase0VolumeLiters,
    meterReadingValue: kQaVehicleConsumptionEntry0MeterTenths,
    meterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
  );

  var meter = kQaVehicleConsumptionEntry0MeterTenths;

  Future<void> seedSession({
    required int distanceTenths,
    required int routePercent,
    required int trafficPercent,
    required int cityPercent,
    required int endTankPercent,
    bool startFullTank = false,
  }) async {
    dayOffset += 1;
    final startAt = at(dayOffset, hours: 8);
    final endAt = at(dayOffset, hours: 18);
    final startReading = await repo.saveMeterReading(
      vehicleId: vehicle.id,
      value: meter,
      unit: repo.meterUnitForKind(VehicleKind.car),
      photoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionStart,
      isFullTank: startFullTank ? true : null,
      recordedAt: startAt,
    );
    final use = await repo.openUseSession(
      vehicleId: vehicle.id,
      attributedContactId: kVehicleOwnerSelfContactId,
      startReadingId: startReading.id,
    );
    meter += distanceTenths;
    final endReading = await repo.saveMeterReading(
      vehicleId: vehicle.id,
      value: meter,
      unit: repo.meterUnitForKind(VehicleKind.car),
      photoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionEnd,
      vehicleUseId: use.id,
      tankFillFraction: endTankPercent,
      recordedAt: endAt,
    );
    await repo.closeUseSession(
      useId: use.id,
      endReadingId: endReading.id,
      drivingRoutePercent: routePercent,
      drivingCityPercent: cityPercent,
      drivingTrafficPercent: trafficPercent,
      sessionConsumptionMode: VehicleConsumptionEstimationMode.detailed,
    );
  }

  // #1 — 150 km, 80 / 5 / 15 %, réservoir 87 %.
  await seedSession(
    distanceTenths: 1500,
    routePercent: 80,
    trafficPercent: 5,
    cityPercent: 15,
    endTankPercent: 87,
    startFullTank: true,
  );

  // #2 — 135 km, 70 / 10 / 20 %, réservoir 62 %.
  await seedSession(
    distanceTenths: 1350,
    routePercent: 70,
    trafficPercent: 10,
    cityPercent: 20,
    endTankPercent: 62,
  );

  // #3 — 220 km, 90 / 0 / 10 %, réservoir 50 %.
  await seedSession(
    distanceTenths: 2200,
    routePercent: 90,
    trafficPercent: 0,
    cityPercent: 10,
    endTankPercent: 50,
  );

  // #4 — 50 km, 100 / 0 / 0 %, réservoir 37 %.
  await seedSession(
    distanceTenths: 500,
    routePercent: 100,
    trafficPercent: 0,
    cityPercent: 0,
    endTankPercent: 37,
  );

  // #5 — 75 km, 50 / 0 / 50 %, réservoir 25 %.
  await seedSession(
    distanceTenths: 750,
    routePercent: 50,
    trafficPercent: 0,
    cityPercent: 50,
    endTankPercent: 25,
  );

  // #6 — achat 43 L, 86 $, plein (50 630 km).
  dayOffset += 1;
  await repo.saveFuelPurchase(
    vehicleId: vehicle.id,
    purchasedAt: at(dayOffset, hours: 9),
    costMinor: kQaVehicleConsumptionFuelPurchase6CostMinor,
    currency: 'CAD',
    isFullTank: true,
    recordedByContactId: kVehicleOwnerSelfContactId,
    volumeLiters: kQaVehicleConsumptionFuelPurchase6VolumeLiters,
    meterReadingValue: kQaVehicleConsumptionFuelPurchase6MeterTenths,
    meterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
  );

  // #7 — 80 km, 60 / 10 / 30 %, réservoir 87 %.
  await seedSession(
    distanceTenths: 800,
    routePercent: 60,
    trafficPercent: 10,
    cityPercent: 30,
    endTankPercent: 87,
    startFullTank: true,
  );

  // #8 — 95 km, 20 / 30 / 50 %, réservoir 75 %.
  await seedSession(
    distanceTenths: 950,
    routePercent: 20,
    trafficPercent: 30,
    cityPercent: 50,
    endTankPercent: 75,
  );

  // #9 — 60 km, 80 / 0 / 20 %, réservoir 75 %.
  await seedSession(
    distanceTenths: 600,
    routePercent: 80,
    trafficPercent: 0,
    cityPercent: 20,
    endTankPercent: 75,
  );

  // #10 — 20 km, 0 / 0 / 100 %, réservoir 75 %.
  await seedSession(
    distanceTenths: 200,
    routePercent: 0,
    trafficPercent: 0,
    cityPercent: 100,
    endTankPercent: 75,
  );

  // #11 — achat 18 L, 36 $, plein (50 885 km).
  dayOffset += 1;
  await repo.saveFuelPurchase(
    vehicleId: vehicle.id,
    purchasedAt: at(dayOffset, hours: 9),
    costMinor: kQaVehicleConsumptionFuelPurchase11CostMinor,
    currency: 'CAD',
    isFullTank: true,
    recordedByContactId: kVehicleOwnerSelfContactId,
    volumeLiters: kQaVehicleConsumptionFuelPurchase11VolumeLiters,
    meterReadingValue: kQaVehicleConsumptionFuelPurchase11MeterTenths,
    meterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
  );

  // #12 — 87 km, 60 / 20 / 20 %, réservoir 87 %.
  await seedSession(
    distanceTenths: 870,
    routePercent: 60,
    trafficPercent: 20,
    cityPercent: 20,
    endTankPercent: 87,
    startFullTank: true,
  );

  // #13 — 72 km, 40 / 10 / 50 %, réservoir 75 %.
  await seedSession(
    distanceTenths: 720,
    routePercent: 40,
    trafficPercent: 10,
    cityPercent: 50,
    endTankPercent: 75,
  );

  // #14 — 143 km, 80 / 5 / 15 %, réservoir 62 %.
  await seedSession(
    distanceTenths: 1430,
    routePercent: 80,
    trafficPercent: 5,
    cityPercent: 15,
    endTankPercent: 62,
  );

  // #15 — 210 km, 90 / 5 / 5 %, réservoir 37 %.
  await seedSession(
    distanceTenths: 2100,
    routePercent: 90,
    trafficPercent: 5,
    cityPercent: 5,
    endTankPercent: 37,
  );

  // #16 — achat 35.4 L, 70.80 $, plein (51 397 km).
  dayOffset += 1;
  await repo.saveFuelPurchase(
    vehicleId: vehicle.id,
    purchasedAt: at(dayOffset, hours: 9),
    costMinor: kQaVehicleConsumptionFuelPurchase16CostMinor,
    currency: 'CAD',
    isFullTank: true,
    recordedByContactId: kVehicleOwnerSelfContactId,
    volumeLiters: kQaVehicleConsumptionFuelPurchase16VolumeLiters,
    meterReadingValue: kQaVehicleConsumptionFuelPurchase16MeterTenths,
    meterPhotoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
  );

  return (await repo.getVehicle(vehicle.id)) ?? vehicle;
}
