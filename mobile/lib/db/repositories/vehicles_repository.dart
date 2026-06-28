import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;

import '../app_database.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_maintenance_alerts.dart';
import '../../vehicle/vehicle_owner_contact.dart';

const String kVehicleGapAttributionUnknown = 'unknown';

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
    String make = '',
    String model = '',
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
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final rule
        in VehicleMaintenanceAlerts.defaultRulesForKind(id, kind)) {
      await _db.into(_db.vehicleMaintenanceRules).insert(
            VehicleMaintenanceRulesCompanion.insert(
              id: rule.id,
              vehicleId: rule.vehicleId,
              category: rule.category,
              intervalAmount: rule.intervalAmount,
              previewWindowAmount: drift.Value(rule.previewWindowAmount),
            ),
          );
    }
    return (await getVehicle(id)) ?? (throw StateError('vehicle missing after insert'));
  }

  Future<int?> latestMeterValue(String vehicleId) async {
    final row = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .getSingleOrNull();
    return row?.value;
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
  }) async {
    final id = _newVehicleId('meter:');
    final now = DateTime.now().toUtc();
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

  Future<VehicleUse?> openUseForVehicle(String vehicleId) async {
    return (_db.select(_db.vehicleUses)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) & t.endedAt.isNull(),
          ))
        .getSingleOrNull();
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
    return kind?.usesHorometer ?? false ? 'horometer_tenths' : 'odometer_km';
  }
}
