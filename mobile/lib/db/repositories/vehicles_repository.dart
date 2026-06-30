import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;

import '../app_database.dart';
import '../../vehicle/vehicle_gallery_storage.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../vehicle/vehicle_maintenance_categories.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_owner_contact.dart';

const String kVehicleGapAttributionUnknown = 'unknown';

class VehicleGalleryPhotoDraft {
  VehicleGalleryPhotoDraft({
    required this.sourcePath,
    this.description = '',
  });

  final String sourcePath;
  String description;
}

class VehicleGalleryDraft {
  VehicleGalleryDraft({
    List<VehicleGalleryPhotoDraft>? photos,
    this.displayTitle,
  }) : photos = photos ?? <VehicleGalleryPhotoDraft>[];

  final List<VehicleGalleryPhotoDraft> photos;
  final String? displayTitle;
}

String _newVehicleId(String prefix) {
  final bytes = List<int>.generate(12, (_) => Random.secure().nextInt(256));
  return '$prefix${base64Url.encode(bytes).replaceAll('=', '')}';
}

enum VehicleSharingLinkStatus {
  pending,
  active,
  expired,
  revoked;

  String get wire => name;

  static VehicleSharingLinkStatus? fromWire(String? raw) {
    if (raw == null) return null;
    for (final s in VehicleSharingLinkStatus.values) {
      if (s.name == raw) return s;
    }
    return null;
  }
}

enum MeterReadingRole {
  sessionStart,
  sessionEnd,
  standalone,
  fuelPurchase,
  correction;

  String get wire => name;

  static MeterReadingRole? fromWire(String? raw) {
    if (raw == null) return null;
    for (final r in MeterReadingRole.values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

class VehiclesRepository {
  VehiclesRepository(this._db);

  final AppDatabase _db;

  Future<List<Vehicle>> listOwnedVehicles() {
    return (_db.select(_db.vehicles)
          ..where((t) => t.ownerContactId.equals(kVehicleOwnerSelfContactId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.displayLabel)]))
        .get();
  }

  Future<Vehicle?> getVehicle(String id) =>
      (_db.select(_db.vehicles)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Vehicle> createVehicle({
    required VehicleKind kind,
    required String displayLabel,
    required String make,
    required String model,
    required String color,
    required int modelYear,
    String licensePlate = '',
    String vin = '',
    double? fuelTankCapacityLiters,
    required int oilChangeIntervalAmount,
    required int initialMeterValue,
    required String initialMeterPhotoPath,
    List<VehicleGalleryDraft> galleries = const [],
  }) async {
    final now = DateTime.now().toUtc();
    final id = _newVehicleId('vehicle:');
    await _db.into(_db.vehicles).insert(
          VehiclesCompanion.insert(
            id: id,
            ownerContactId: kVehicleOwnerSelfContactId,
            vehicleKind: kind.wire,
            displayLabel: displayLabel.trim(),
            make: drift.Value(make.trim()),
            model: drift.Value(model.trim()),
            color: drift.Value(color.trim()),
            modelYear: drift.Value(modelYear),
            licensePlate: drift.Value(licensePlate.trim()),
            vin: drift.Value(vin.trim()),
            fuelTankCapacityLiters: drift.Value(fuelTankCapacityLiters),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final preview = (oilChangeIntervalAmount ~/ 10)
        .clamp(1, oilChangeIntervalAmount);
    await _db.into(_db.vehicleMaintenanceRules).insert(
          VehicleMaintenanceRulesCompanion.insert(
            id: '$id:rule:oil',
            vehicleId: id,
            category: VehicleMaintenanceCategoryWire.oil.wire,
            intervalAmount: oilChangeIntervalAmount,
            previewWindowAmount: drift.Value(preview),
          ),
        );
    await saveMeterReading(
      vehicleId: id,
      value: initialMeterValue,
      unit: meterUnitForKind(kind),
      photoPath: await storeVehicleMeterPhotoFromSource(
        vehicleId: id,
        sourcePath: initialMeterPhotoPath,
      ),
      recordedByContactId: kVehicleOwnerSelfContactId,
      role: MeterReadingRole.standalone,
    );
    await _persistGalleryDrafts(id, galleries);
    return (await getVehicle(id)) ?? (throw StateError('vehicle missing after insert'));
  }

  String meterUnitForKind(VehicleKind kind) {
    return kind.usesHorometer ? 'horometer_tenths' : 'odometer_km';
  }

  Future<void> _persistGalleryDrafts(
    String vehicleId,
    List<VehicleGalleryDraft> galleries,
  ) async {
    var nextIndex = await _nextGalleryIndex(vehicleId);
    for (final draft in galleries) {
      if (draft.photos.isEmpty) continue;
      final relativeDirectory = vehicleGalleryRelativeSubDir(
        vehicleId: vehicleId,
        galleryIndex: nextIndex,
      );
      final galleryId = _newVehicleId('vgal:');
      final now = DateTime.now().toUtc();
      await _db.into(_db.vehiclePhotoGalleries).insert(
            VehiclePhotoGalleriesCompanion.insert(
              id: galleryId,
              vehicleId: vehicleId,
              galleryIndex: nextIndex,
              relativeDirectory: relativeDirectory,
              createdAt: now,
            ),
          );
      var sortOrder = 0;
      for (final photo in draft.photos) {
        final storageKey = await storeVehicleGalleryPhotoFromSource(
          vehicleId: vehicleId,
          galleryIndex: nextIndex,
          sourcePath: photo.sourcePath,
        );
        await _db.into(_db.vehicleGalleryPhotos).insert(
              VehicleGalleryPhotosCompanion.insert(
                id: _newVehicleId('vphoto:'),
                galleryId: galleryId,
                relativeFilePath: storageKey,
                description: drift.Value(photo.description.trim()),
                capturedAt: now,
                sortOrder: drift.Value(sortOrder),
              ),
            );
        sortOrder++;
      }
      nextIndex++;
    }
  }

  Future<void> addGalleryDrafts(
    String vehicleId,
    List<VehicleGalleryDraft> galleries,
  ) {
    return _persistGalleryDrafts(vehicleId, galleries);
  }

  Future<Vehicle> updateVehicleEditableDetails({
    required String vehicleId,
    required String displayLabel,
    required String color,
    String licensePlate = '',
    required int oilChangeIntervalAmount,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(vehicleId))).write(
          VehiclesCompanion(
            displayLabel: drift.Value(displayLabel.trim()),
            color: drift.Value(color.trim()),
            licensePlate: drift.Value(licensePlate.trim()),
            updatedAt: drift.Value(now),
          ),
        );
    await _upsertOilChangeInterval(
      vehicleId: vehicleId,
      intervalAmount: oilChangeIntervalAmount,
    );
    return (await getVehicle(vehicleId)) ??
        (throw StateError('vehicle missing after update'));
  }

  Future<int?> oilChangeIntervalAmountForVehicle(String vehicleId) async {
    final rule = await (_db.select(_db.vehicleMaintenanceRules)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.category.equals(VehicleMaintenanceCategoryWire.oil.wire),
          ))
        .getSingleOrNull();
    return rule?.intervalAmount;
  }

  Future<void> _upsertOilChangeInterval({
    required String vehicleId,
    required int intervalAmount,
  }) async {
    final preview = (intervalAmount ~/ 10).clamp(1, intervalAmount);
    final existing = await (_db.select(_db.vehicleMaintenanceRules)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.category.equals(VehicleMaintenanceCategoryWire.oil.wire),
          ))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.vehicleMaintenanceRules)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        VehicleMaintenanceRulesCompanion(
          intervalAmount: drift.Value(intervalAmount),
          previewWindowAmount: drift.Value(preview),
        ),
      );
      return;
    }
    await _db.into(_db.vehicleMaintenanceRules).insert(
          VehicleMaintenanceRulesCompanion.insert(
            id: '$vehicleId:rule:oil',
            vehicleId: vehicleId,
            category: VehicleMaintenanceCategoryWire.oil.wire,
            intervalAmount: intervalAmount,
            previewWindowAmount: drift.Value(preview),
          ),
        );
  }

  Future<List<VehicleMeterReading>> listMeterReadings(String vehicleId) {
    return (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<VehicleMeterReading?> getMeterReading(String id) =>
      (_db.select(_db.vehicleMeterReadings)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<FuelPurchase?> getFuelPurchase(String id) =>
      (_db.select(_db.fuelPurchases)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<MaintenanceEvent?> getMaintenanceEvent(String id) =>
      (_db.select(_db.maintenanceEvents)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<TrafficViolation?> getTrafficViolation(String id) =>
      (_db.select(_db.trafficViolations)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int?> initialMeterBaseline(String vehicleId) async {
    final rows = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.recordedAt),
            (t) => drift.OrderingTerm.asc(t.id),
          ])
          ..limit(1))
        .get();
    return rows.firstOrNull?.value;
  }

  Future<int> _nextGalleryIndex(String vehicleId) async {
    final rows = await (_db.select(_db.vehiclePhotoGalleries)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    if (rows.isEmpty) return 1;
    return rows.map((r) => r.galleryIndex).reduce(max) + 1;
  }

  Future<List<VehiclePhotoGallery>> listPhotoGalleries(String vehicleId) {
    return (_db.select(_db.vehiclePhotoGalleries)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.galleryIndex)]))
        .get();
  }

  Future<List<VehicleGalleryPhoto>> listGalleryPhotos(String galleryId) {
    return (_db.select(_db.vehicleGalleryPhotos)
          ..where((t) => t.galleryId.equals(galleryId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int?> latestMeterValue(String vehicleId) async {
    final anchor = await latestMeterAnchor(vehicleId);
    return anchor?.value;
  }

  /// Most recent meter value across canonical readings, fuel purchases, and
  /// maintenance events (by timestamp).
  Future<({DateTime recordedAt, int value})?> latestMeterAnchor(
    String vehicleId,
  ) async {
    ({DateTime recordedAt, int value})? best;

    void consider(DateTime recordedAt, int? value) {
      if (value == null) return;
      if (best == null || recordedAt.isAfter(best!.recordedAt)) {
        best = (recordedAt: recordedAt, value: value);
      }
    }

    final reading = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => drift.OrderingTerm.desc(t.recordedAt),
            (t) => drift.OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (reading != null) {
      consider(reading.recordedAt, reading.value);
    }

    final purchase = await (_db.select(_db.fuelPurchases)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.meterReadingValue.isNotNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.purchasedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (purchase != null) {
      consider(purchase.purchasedAt, purchase.meterReadingValue);
    }

    final maintenance = await (_db.select(_db.maintenanceEvents)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) & t.meterAtService.isNotNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.servicedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (maintenance != null) {
      consider(maintenance.servicedAt, maintenance.meterAtService);
    }

    return best;
  }

  /// Earliest meter value across canonical readings, fuel purchases, and
  /// maintenance events (by timestamp).
  Future<({DateTime recordedAt, int value})?> earliestMeterAnchor(
    String vehicleId,
  ) async {
    ({DateTime recordedAt, int value})? best;

    void consider(DateTime recordedAt, int? value) {
      if (value == null) return;
      if (best == null || recordedAt.isBefore(best!.recordedAt)) {
        best = (recordedAt: recordedAt, value: value);
      }
    }

    final reading = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.recordedAt),
            (t) => drift.OrderingTerm.asc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (reading != null) {
      consider(reading.recordedAt, reading.value);
    }

    final purchase = await (_db.select(_db.fuelPurchases)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.meterReadingValue.isNotNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.purchasedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (purchase != null) {
      consider(purchase.purchasedAt, purchase.meterReadingValue);
    }

    final maintenance = await (_db.select(_db.maintenanceEvents)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) & t.meterAtService.isNotNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.servicedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (maintenance != null) {
      consider(maintenance.servicedAt, maintenance.meterAtService);
    }

    return best;
  }

  Future<DateTime> _nextMeterRecordedAt(String vehicleId) async {
    final rows = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    final now = DateTime.now().toUtc();
    final latest = rows.firstOrNull?.recordedAt;
    if (latest == null || now.isAfter(latest)) return now;
    return latest.add(const Duration(milliseconds: 1));
  }

  Future<VehicleMeterReading> saveMeterReading({
    required String vehicleId,
    required int value,
    required String unit,
    required String photoPath,
    required String recordedByContactId,
    required MeterReadingRole role,
    String? vehicleUseId,
    bool isCorrection = false,
    String correctionNote = '',
    bool negativeGapAcknowledged = false,
    bool? isFullTank,
    int? tankFillFraction,
  }) async {
    final id = _newVehicleId('meter:');
    final now = await _nextMeterRecordedAt(vehicleId);
    await _db.into(_db.vehicleMeterReadings).insert(
          VehicleMeterReadingsCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            value: value,
            unit: unit,
            photoPath: photoPath,
            recordedAt: now,
            recordedByContactId: recordedByContactId,
            vehicleUseId: drift.Value(vehicleUseId),
            readingRole: role.wire,
            isCorrection: drift.Value(isCorrection),
            correctionNote: drift.Value(correctionNote),
            negativeGapAcknowledged: drift.Value(negativeGapAcknowledged),
            isFullTank: drift.Value(isFullTank),
            tankFillFraction: drift.Value(
              isFullTank == true ? null : tankFillFraction,
            ),
          ),
        );
    return (await (_db.select(_db.vehicleMeterReadings)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<VehicleOdometerGap> recordPositiveGap({
    required String vehicleId,
    required int latestBefore,
    required int startAfter,
    required String attributedContactId,
    required String recordedByContactId,
    String? vehicleUseId,
  }) async {
    final id = _newVehicleId('gap:');
    final now = DateTime.now().toUtc();
    final gap = startAfter - latestBefore;
    await _db.into(_db.vehicleOdometerGaps).insert(
          VehicleOdometerGapsCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            latestReadingBeforeGap: latestBefore,
            startReadingAfterGap: startAfter,
            gapAmount: gap,
            attributedContactId: attributedContactId,
            recordedByContactId: recordedByContactId,
            recordedAt: now,
            vehicleUseId: drift.Value(vehicleUseId),
          ),
        );
    return (await (_db.select(_db.vehicleOdometerGaps)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<VehicleUse> openUseSession({
    required String vehicleId,
    required String attributedContactId,
    required String startReadingId,
  }) async {
    final existing = await openUseForVehicle(vehicleId);
    if (existing != null) {
      return existing;
    }
    final reading = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.id.equals(startReadingId)))
        .getSingle();
    final id = _newVehicleId('use:');
    await _db.into(_db.vehicleUses).insert(
          VehicleUsesCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            attributedContactId: attributedContactId,
            startedAt: reading.recordedAt,
            startReadingId: startReadingId,
          ),
        );
    return (await (_db.select(_db.vehicleUses)..where((t) => t.id.equals(id)))
        .getSingle());
  }

  Future<VehicleUse?> getVehicleUse(String id) =>
      (_db.select(_db.vehicleUses)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<VehicleUse?> openUseForVehicle(String vehicleId) async {
    final rows = await (_db.select(_db.vehicleUses)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) & t.endedAt.isNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .get();
    return rows.firstOrNull;
  }

  Future<VehicleUse?> findAnyOpenUse() async {
    final rows = await (_db.select(_db.vehicleUses)
          ..where((t) => t.endedAt.isNull())
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .get();
    return rows.firstOrNull;
  }

  Future<VehicleUse> closeUseSession({
    required String useId,
    required String endReadingId,
  }) async {
    final use = await (_db.select(_db.vehicleUses)
          ..where((t) => t.id.equals(useId)))
        .getSingle();
    final start = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.id.equals(use.startReadingId)))
        .getSingle();
    final end = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.id.equals(endReadingId)))
        .getSingle();
    final amount = end.value - start.value;
    await (_db.update(_db.vehicleUses)..where((t) => t.id.equals(useId))).write(
      VehicleUsesCompanion(
        endedAt: drift.Value(end.recordedAt),
        endReadingId: drift.Value(endReadingId),
        usageAmount: drift.Value(amount),
      ),
    );
    return (await (_db.select(_db.vehicleUses)..where((t) => t.id.equals(useId)))
        .getSingle());
  }

  Future<FuelPurchase> saveFuelPurchase({
    required String vehicleId,
    required DateTime purchasedAt,
    required int costMinor,
    required String currency,
    required bool isFullTank,
    required String recordedByContactId,
    double? volumeLiters,
    int? meterReadingValue,
    String? meterPhotoPath,
    int? tankFillFraction,
  }) async {
    final id = _newVehicleId('fuel:');
    await _db.into(_db.fuelPurchases).insert(
          FuelPurchasesCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            purchasedAt: purchasedAt,
            costMinor: costMinor,
            currency: currency,
            isFullTank: isFullTank,
            recordedByContactId: recordedByContactId,
            volumeLiters: drift.Value(volumeLiters),
            meterReadingValue: drift.Value(meterReadingValue),
            meterPhotoPath: drift.Value(meterPhotoPath),
            tankFillFraction: drift.Value(
              isFullTank ? null : tankFillFraction,
            ),
          ),
        );
    return (await (_db.select(_db.fuelPurchases)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<MaintenanceEvent> saveMaintenanceEvent({
    required String vehicleId,
    required DateTime servicedAt,
    required String category,
    required int costMinor,
    required String currency,
    required String recordedByContactId,
    String notes = '',
    String? attachmentPath,
    int? meterAtService,
  }) async {
    final id = _newVehicleId('maint:');
    await _db.into(_db.maintenanceEvents).insert(
          MaintenanceEventsCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            servicedAt: servicedAt,
            category: category,
            costMinor: costMinor,
            currency: currency,
            recordedByContactId: recordedByContactId,
            notes: drift.Value(notes),
            attachmentPath: drift.Value(attachmentPath),
            meterAtService: drift.Value(meterAtService),
          ),
        );
    return (await (_db.select(_db.maintenanceEvents)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<TrafficViolation> saveTrafficViolation({
    required String vehicleId,
    required DateTime violatedAt,
    required String violationType,
    required int amountMinor,
    required String currency,
    required String recordedByContactId,
    String? responsibilityContactId,
    String notes = '',
  }) async {
    final id = _newVehicleId('violation:');
    await _db.into(_db.trafficViolations).insert(
          TrafficViolationsCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            violatedAt: violatedAt,
            violationType: violationType,
            amountMinor: amountMinor,
            currency: currency,
            recordedByContactId: recordedByContactId,
            responsibilityContactId: drift.Value(responsibilityContactId),
            notes: drift.Value(notes),
          ),
        );
    return (await (_db.select(_db.trafficViolations)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<List<FuelPurchase>> listFuelPurchases(String vehicleId) {
    return (_db.select(_db.fuelPurchases)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.purchasedAt)]))
        .get();
  }

  Future<List<MaintenanceEvent>> listMaintenanceEvents(String vehicleId) {
    return (_db.select(_db.maintenanceEvents)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.servicedAt)]))
        .get();
  }

  Future<List<TrafficViolation>> listViolations(String vehicleId) {
    return (_db.select(_db.trafficViolations)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.violatedAt)]))
        .get();
  }

  Future<List<VehicleUse>> listUses(String vehicleId) {
    return (_db.select(_db.vehicleUses)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  // --- Sharing ---

  Future<VehicleSharingLink> createSharingOffer({
    required String vehicleId,
    required String borrowerContactId,
  }) async {
    final id = _newVehicleId('vshare:');
    final now = DateTime.now().toUtc();
    await _db.into(_db.vehicleSharingLinks).insert(
          VehicleSharingLinksCompanion.insert(
            id: id,
            vehicleId: vehicleId,
            ownerContactId: kVehicleOwnerSelfContactId,
            borrowerContactId: borrowerContactId,
            status: VehicleSharingLinkStatus.pending.wire,
            createdAt: now,
          ),
        );
    return (await (_db.select(_db.vehicleSharingLinks)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  Future<void> acceptSharingLink(String linkId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.vehicleSharingLinks)
          ..where((t) => t.id.equals(linkId)))
        .write(
      VehicleSharingLinksCompanion(
        status: drift.Value(VehicleSharingLinkStatus.active.wire),
        acceptedAt: drift.Value(now),
      ),
    );
  }

  Future<void> revokeSharingLink(String linkId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.vehicleSharingLinks)
          ..where((t) => t.id.equals(linkId)))
        .write(
      VehicleSharingLinksCompanion(
        status: drift.Value(VehicleSharingLinkStatus.revoked.wire),
        revokedAt: drift.Value(now),
      ),
    );
  }

  Future<List<VehicleSharingLink>> listSharingLinksForVehicle(
    String vehicleId,
  ) {
    return (_db.select(_db.vehicleSharingLinks)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<VehicleSharingLink>> listPendingOffersForBorrower(
    String borrowerContactId,
  ) async {
    final rows = await (_db.select(_db.vehicleSharingLinks)
          ..where(
            (t) =>
                t.borrowerContactId.equals(borrowerContactId) &
                t.status.equals(VehicleSharingLinkStatus.pending.wire),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
    return _linksOnExternalOwnedVehicles(rows);
  }

  Future<List<VehicleSharingLink>> listPendingBorrowerOffers() async {
    final rows = await (_db.select(_db.vehicleSharingLinks)
          ..where(
            (t) => t.status.equals(VehicleSharingLinkStatus.pending.wire),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
    return _linksOnExternalOwnedVehicles(rows);
  }

  Future<List<VehicleSharingLink>> listActiveLinksAsBorrower(
    String borrowerContactId,
  ) {
    return (_db.select(_db.vehicleSharingLinks)
          ..where(
            (t) =>
                t.borrowerContactId.equals(borrowerContactId) &
                t.status.equals(VehicleSharingLinkStatus.active.wire),
          ))
        .get();
  }

  /// Active sharing links on vehicles **not** owned on this device (Emprunteur
  /// accessible vehicles — typically synced from another owner's instance).
  Future<List<({Vehicle vehicle, VehicleSharingLink link})>>
      listBorrowerAccessibleEntries() async {
    final rows = await (_db.select(_db.vehicleSharingLinks)
          ..where(
            (t) => t.status.equals(VehicleSharingLinkStatus.active.wire),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
    final out = <({Vehicle vehicle, VehicleSharingLink link})>[];
    for (final link in rows) {
      final v = await getVehicle(link.vehicleId);
      if (v == null) continue;
      if (v.ownerContactId == kVehicleOwnerSelfContactId) continue;
      out.add((vehicle: v, link: link));
    }
    return out;
  }

  Future<List<Vehicle>> listAccessibleVehiclesAsBorrower(
    String borrowerContactId,
  ) async {
    final links = await listActiveLinksAsBorrower(borrowerContactId);
    final out = <Vehicle>[];
    for (final link in links) {
      final v = await getVehicle(link.vehicleId);
      if (v == null) continue;
      if (v.ownerContactId == kVehicleOwnerSelfContactId) continue;
      out.add(v);
    }
    return out;
  }

  Future<List<VehicleSharingLink>> _linksOnExternalOwnedVehicles(
    List<VehicleSharingLink> links,
  ) async {
    final out = <VehicleSharingLink>[];
    for (final link in links) {
      final v = await getVehicle(link.vehicleId);
      if (v == null) continue;
      if (v.ownerContactId == kVehicleOwnerSelfContactId) continue;
      out.add(link);
    }
    return out;
  }

  Future<List<VehicleSharingLink>> listActiveLinksAsOwner() {
    return (_db.select(_db.vehicleSharingLinks)
          ..where(
            (t) =>
                t.ownerContactId.equals(kVehicleOwnerSelfContactId) &
                t.status.equals(VehicleSharingLinkStatus.active.wire),
          ))
        .get();
  }

  String meterUnitForVehicle(Vehicle vehicle) {
    final kind = VehicleKind.fromWire(vehicle.vehicleKind);
    return meterUnitForKind(kind ?? VehicleKind.car);
  }
}
