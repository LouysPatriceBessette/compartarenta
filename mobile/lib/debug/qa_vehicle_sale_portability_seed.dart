import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import '../portability/bojairu_documents_layout.dart';
import '../portability/public_documents_file_sink.dart';
import '../vehicle/vehicle_consumption_estimation_mode.dart';
import '../vehicle/vehicle_kind.dart';
import '../vehicle/vehicle_maintenance_categories.dart';
import '../vehicle/vehicle_meter_photo_path.dart';
import '../vehicle/vehicle_owner_contact.dart';
import 'qa_vehicle_seed_helpers.dart';

/// Closed use sessions seeded for sale export/import E2E.
const kQaVehicleSalePortabilitySessionCount = 32;

/// Full-tank fuel purchases seeded for sale export/import E2E.
const kQaVehicleSalePortabilityFuelPurchaseCount = 8;

/// Oil-change maintenance events seeded for sale export/import E2E.
const kQaVehicleSalePortabilityOilChangeCount = 1;

/// Oil change cost: 40.00 CAD.
const kQaVehicleSalePortabilityOilChangeCostMinor = 4000;

/// Base timestamp: start of the ~2-month seller history window.
DateTime qaVehicleSalePortabilitySeedBaseTime() =>
    DateTime.utc(2026, 5, 15, 12);

/// Minimal 1×1 JPEG used as the single shared meter-photo placeholder.
const kQaVehicleSalePortabilityPlaceholderJpegBytes = <int>[
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
  0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
  0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
  0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
  0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
  0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
  0x00, 0x00, 0x3F, 0x00, 0x7F, 0xFF, 0xD9,
];

/// Writes the shared placeholder JPEG (or falls back to the QA sentinel in tests).
Future<String> qaWriteSalePortabilityPlaceholderMeterPhoto(
  String vehicleId,
) async {
  try {
    final written = await writePublicDocumentBytes(
      relativeSubDir:
          BojairuDocumentsLayout.vehicleOdometerPhotosRelativeSubDir(
        vehicleId: vehicleId,
      ),
      fileName: 'qa_sale_placeholder.jpg',
      bytes: kQaVehicleSalePortabilityPlaceholderJpegBytes,
      mimeType: 'image/jpeg',
    );
    return written.storageKey;
  } catch (_) {
    return kVehicleMeterPhotoKnownUnchangedSentinel;
  }
}

/// Seeds QA Civic with ~2 months of history for sale export/import E2E.
Future<Vehicle> qaSeedVehicleSalePortabilitySeller(AppDatabase db) async {
  final repo = VehiclesRepository(db);
  final vehicle = await repo.createVehicle(
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

  final photoPath =
      await qaWriteSalePortabilityPlaceholderMeterPhoto(vehicle.id);

  final base = qaVehicleSalePortabilitySeedBaseTime();
  var dayOffset = 0;
  DateTime at(int days, {int hours = 0}) =>
      base.add(Duration(days: days, hours: hours));

  var meter = kQaVehicleE2eInitialMeterTenths;
  var sessionsSeeded = 0;
  var fuelsSeeded = 0;

  Future<void> seedFuel({required double volumeLiters, required int costMinor}) async {
    dayOffset += 1;
    await repo.saveFuelPurchase(
      vehicleId: vehicle.id,
      purchasedAt: at(dayOffset, hours: 9),
      costMinor: costMinor,
      currency: 'CAD',
      isFullTank: true,
      recordedByContactId: kVehicleOwnerSelfContactId,
      volumeLiters: volumeLiters,
      meterReadingValue: meter,
      meterPhotoPath: photoPath,
    );
    fuelsSeeded += 1;
  }

  Future<void> seedSession({required int distanceTenths}) async {
    dayOffset += 1;
    final startAt = at(dayOffset, hours: 8);
    final endAt = at(dayOffset, hours: 18);
    final startReading = await repo.saveMeterReading(
      vehicleId: vehicle.id,
      value: meter,
      unit: repo.meterUnitForKind(VehicleKind.car),
      photoPath: photoPath,
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionStart,
      isFullTank: sessionsSeeded % 4 == 0 ? true : null,
      recordedAt: startAt,
    );
    final use = await repo.openUseSession(
      vehicleId: vehicle.id,
      attributedContactId: kVehicleOwnerSelfContactId,
      startReadingId: startReading.id,
    );
    meter += distanceTenths;
    final endTank = 87 - ((sessionsSeeded % 4) * 20);
    final endReading = await repo.saveMeterReading(
      vehicleId: vehicle.id,
      value: meter,
      unit: repo.meterUnitForKind(VehicleKind.car),
      photoPath: photoPath,
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.sessionEnd,
      vehicleUseId: use.id,
      tankFillFraction: endTank.clamp(12, 87),
      recordedAt: endAt,
    );
    await repo.closeUseSession(
      useId: use.id,
      endReadingId: endReading.id,
      drivingRoutePercent: 70,
      drivingCityPercent: 20,
      drivingTrafficPercent: 10,
      sessionConsumptionMode: VehicleConsumptionEstimationMode.simple,
    );
    sessionsSeeded += 1;
  }

  // Fuel #1 at the initial odometer, then 4 sessions per fuel for 8 fuels / 32 sessions.
  final fuelSpecs = <({double liters, int costMinor})>[
    (liters: 55.0, costMinor: 11000),
    (liters: 48.0, costMinor: 9600),
    (liters: 52.0, costMinor: 10400),
    (liters: 46.0, costMinor: 9200),
    (liters: 50.0, costMinor: 10000),
    (liters: 44.0, costMinor: 8800),
    (liters: 49.0, costMinor: 9800),
    (liters: 47.0, costMinor: 9400),
  ];

  // Distances (tenths) — ~45–70 km per session.
  final distances = <int>[
    for (var i = 0; i < kQaVehicleSalePortabilitySessionCount; i++)
      450 + ((i * 37) % 250),
  ];

  for (var fuelIndex = 0; fuelIndex < fuelSpecs.length; fuelIndex++) {
    final fuel = fuelSpecs[fuelIndex];
    await seedFuel(volumeLiters: fuel.liters, costMinor: fuel.costMinor);
    for (var s = 0; s < 4; s++) {
      final sessionIndex = fuelIndex * 4 + s;
      await seedSession(distanceTenths: distances[sessionIndex]);
      if (sessionsSeeded == 16) {
        dayOffset += 1;
        await repo.saveMaintenanceEvent(
          vehicleId: vehicle.id,
          servicedAt: at(dayOffset, hours: 11),
          category: VehicleMaintenanceCategoryWire.oil.wire,
          costMinor: kQaVehicleSalePortabilityOilChangeCostMinor,
          currency: 'CAD',
          recordedByContactId: kVehicleOwnerSelfContactId,
          notes: "Changement d'huile",
          meterAtService: meter,
        );
      }
    }
  }

  if (sessionsSeeded != kQaVehicleSalePortabilitySessionCount ||
      fuelsSeeded != kQaVehicleSalePortabilityFuelPurchaseCount) {
    throw StateError(
      'sale portability seed: expected '
      '$kQaVehicleSalePortabilitySessionCount sessions / '
      '$kQaVehicleSalePortabilityFuelPurchaseCount fuels, '
      'got $sessionsSeeded / $fuelsSeeded',
    );
  }

  return (await repo.getVehicle(vehicle.id)) ?? vehicle;
}
