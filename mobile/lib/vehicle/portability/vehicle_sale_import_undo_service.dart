import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../portability/public_documents_file_sink.dart';
import '../../vehicle/vehicle_meter_photo_path.dart';
import '../../vehicle/vehicle_owner_contact.dart';

/// Fully reverts a sale import: DB rows for the vehicle + public media files.
class VehicleSaleImportUndoService {
  VehicleSaleImportUndoService(this._db);

  final AppDatabase _db;

  Future<Vehicle?> latestOwnedUndoableImport() async {
    final rows = await (_db.select(_db.vehicles)
          ..where(
            (t) =>
                t.ownerContactId.equals(kVehicleOwnerSelfContactId) &
                t.saleImportUndoAvailable.equals(true),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.firstOrNull;
  }

  Future<void> undoImport(String vehicleId) async {
    final vehicle = await VehiclesRepository(_db).getVehicle(vehicleId);
    if (vehicle == null) {
      throw StateError('vehicle missing: $vehicleId');
    }
    if (!vehicle.saleImportUndoAvailable) {
      throw StateError('sale import undo not available: $vehicleId');
    }
    if (vehicle.ownerContactId != kVehicleOwnerSelfContactId) {
      throw StateError('only the owner may undo this import');
    }

    final mediaKeys = <String>{};
    final readings = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    for (final r in readings) {
      if (meterReadingHasDisplayablePhoto(r.photoPath)) {
        mediaKeys.add(r.photoPath);
      }
    }
    final fuels = await (_db.select(_db.fuelPurchases)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    for (final f in fuels) {
      final path = f.meterPhotoPath;
      if (path != null && path.isNotEmpty) mediaKeys.add(path);
    }
    final maints = await (_db.select(_db.maintenanceEvents)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    for (final m in maints) {
      final path = m.attachmentPath;
      if (path != null && path.isNotEmpty) mediaKeys.add(path);
    }
    final galleries = await (_db.select(_db.vehiclePhotoGalleries)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    for (final g in galleries) {
      final photos = await (_db.select(_db.vehicleGalleryPhotos)
            ..where((t) => t.galleryId.equals(g.id)))
          .get();
      for (final p in photos) {
        if (p.relativeFilePath.isNotEmpty) {
          mediaKeys.add(p.relativeFilePath);
        }
      }
    }

    for (final key in mediaKeys) {
      try {
        await deletePublicDocument(key);
      } catch (_) {
        // Best-effort media cleanup; DB revert still proceeds.
      }
    }

    await _db.transaction(() async {
      final galleryIds = galleries.map((g) => g.id).toList();
      if (galleryIds.isNotEmpty) {
        await (_db.delete(_db.vehicleGalleryPhotos)
              ..where((t) => t.galleryId.isIn(galleryIds)))
            .go();
      }
      await (_db.delete(_db.vehiclePhotoGalleries)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleSharingLinks)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.trafficViolations)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleMaintenanceRules)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.maintenanceEvents)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.fuelPurchases)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleOdometerGaps)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleConsumptionEstimateHistory)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleUses)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicleMeterReadings)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .go();
      await (_db.delete(_db.vehicles)..where((t) => t.id.equals(vehicleId)))
          .go();
    });
  }
}
