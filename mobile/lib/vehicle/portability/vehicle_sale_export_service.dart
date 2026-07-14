import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:path/path.dart' as p;

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../portability/compartarenta_documents_layout.dart';
import '../../portability/public_documents_file_sink.dart';
import '../../vehicle/vehicle_maintenance_categories.dart';
import '../../vehicle/vehicle_meter_photo_path.dart';
import 'vehicle_sale_bundle.dart';
import 'vehicle_sale_export_file_name.dart';

class VehicleSaleExportWriteResult {
  const VehicleSaleExportWriteResult({required this.zipFileName});

  final String zipFileName;
}

/// Builds a sale/transfer zip (JSON + selected media) for one owned vehicle.
class VehicleSaleExportService {
  VehicleSaleExportService(this._db);

  final AppDatabase _db;

  Future<VehicleSaleExportWriteResult> exportToDocuments({
    required String vehicleId,
    required String dataOfSegment,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now();
    final built = await buildZipBytes(
      vehicleId: vehicleId,
      dataOfSegment: dataOfSegment,
      now: when,
    );
    await writePublicDocumentBytes(
      relativeSubDir: CompartarentaDocumentsLayout.moduleRootRelativeSubDir(),
      fileName: built.zipFileName,
      bytes: built.zipBytes,
      mimeType: 'application/zip',
    );
    return VehicleSaleExportWriteResult(zipFileName: built.zipFileName);
  }

  Future<({List<int> zipBytes, String zipFileName, String jsonFileName})>
      buildZipBytes({
    required String vehicleId,
    required String dataOfSegment,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now();
    final vehicle = await (_db.select(_db.vehicles)
          ..where((t) => t.id.equals(vehicleId)))
        .getSingleOrNull();
    if (vehicle == null) {
      throw const VehicleSaleExportException('vehicle not found');
    }
    if (vehicle.displayLabel.trim().isEmpty) {
      throw const VehicleSaleExportException('displayLabel must not be empty');
    }

    final jsonFileName = vehicleSaleExportJsonFileName(
      date: when,
      dataOfSegment: dataOfSegment,
      displayLabel: vehicle.displayLabel,
    );
    final zipFileName = vehicleSaleExportZipFileName(
      date: when,
      dataOfSegment: dataOfSegment,
      displayLabel: vehicle.displayLabel,
    );

    final media = <String, List<int>>{};
    final payload = await _buildPayload(
      vehicle: vehicle,
      mediaOut: media,
    );

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final jsonBytes = utf8.encode(jsonText);
    final archive = Archive();
    final jsonArchivePath =
        '${CompartarentaDocumentsLayout.rootFolderName}/$jsonFileName';
    archive.addFile(
      ArchiveFile(jsonArchivePath, jsonBytes.length, jsonBytes),
    );
    for (final entry in media.entries) {
      archive.addFile(
        ArchiveFile(entry.key, entry.value.length, entry.value),
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw const VehicleSaleExportException('zip encode failed');
    }
    return (
      zipBytes: encoded,
      zipFileName: zipFileName,
      jsonFileName: jsonFileName,
    );
  }

  Future<Map<String, Object?>> _buildPayload({
    required Vehicle vehicle,
    required Map<String, List<int>> mediaOut,
  }) async {
    final vehicleId = vehicle.id;
    final oilAmount = await VehiclesRepository(_db)
        .oilChangeIntervalAmountForVehicle(vehicleId);
    if (oilAmount == null) {
      throw const VehicleSaleExportException('oil change interval missing');
    }

    final readings = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();

    String? lastPhotoReadingId;
    String? lastOdometerArchivePath;
    for (var i = readings.length - 1; i >= 0; i--) {
      final r = readings[i];
      if (!meterReadingHasDisplayablePhoto(r.photoPath)) continue;
      lastPhotoReadingId = r.id;
      lastOdometerArchivePath = await _packBytes(
        storageKey: r.photoPath,
        archiveRelativePath: p.join(
          CompartarentaDocumentsLayout.vehicleOdometerPhotosRelativeSubDir(
            vehicleId: vehicleId,
          ),
          _fileNameForKey(r.photoPath, 'odometer_${r.id}.jpg'),
        ),
        mediaOut: mediaOut,
      );
      break;
    }

    final meterRows = <Map<String, Object?>>[];
    for (final r in readings) {
      final includePhoto =
          lastPhotoReadingId != null && r.id == lastPhotoReadingId;
      meterRows.add({
        'id': r.id,
        'value': r.value,
        'unit': r.unit,
        'photoPath': includePhoto
            ? (lastOdometerArchivePath ?? '')
            : (isKnownUnchangedMeterPhotoPath(r.photoPath) ? r.photoPath : ''),
        'recordedAt': r.recordedAt.toUtc().toIso8601String(),
        'readingRole': r.readingRole,
        'isCorrection': r.isCorrection,
        'correctionNote': r.correctionNote,
        'negativeGapAcknowledged': r.negativeGapAcknowledged,
        'isFullTank': r.isFullTank,
        'tankFillFraction': r.tankFillFraction,
        'resolvedAt': r.resolvedAt?.toUtc().toIso8601String(),
        'supersedesReadingId': r.supersedesReadingId,
      });
    }

    final fuels = await (_db.select(_db.fuelPurchases)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.asc(t.purchasedAt)]))
        .get();
    final fuelRows = [
      for (final f in fuels)
        <String, Object?>{
          'id': f.id,
          'purchasedAt': f.purchasedAt.toUtc().toIso8601String(),
          'costMinor': f.costMinor,
          'currency': f.currency,
          'volumeLiters': f.volumeLiters,
          'meterReadingValue': f.meterReadingValue,
          'isFullTank': f.isFullTank,
          'tankFillFraction': f.tankFillFraction,
        },
    ];

    final maints = await (_db.select(_db.maintenanceEvents)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.asc(t.servicedAt)]))
        .get();
    final maintRows = <Map<String, Object?>>[];
    for (final m in maints) {
      String? attachmentArchivePath;
      final attachment = m.attachmentPath;
      if (attachment != null && attachment.isNotEmpty) {
        attachmentArchivePath = await _packBytes(
          storageKey: attachment,
          archiveRelativePath: p.join(
            CompartarentaDocumentsLayout
                .vehicleMaintenanceAttachmentsRelativeSubDir(
              vehicleId: vehicleId,
            ),
            _fileNameForKey(attachment, 'maint_${m.id}${p.extension(attachment)}'),
          ),
          mediaOut: mediaOut,
        );
      }
      maintRows.add({
        'id': m.id,
        'servicedAt': m.servicedAt.toUtc().toIso8601String(),
        'category': m.category,
        'costMinor': m.costMinor,
        'currency': m.currency,
        'notes': m.notes,
        'attachmentPath': attachmentArchivePath,
        'meterAtService': m.meterAtService,
      });
    }

    final estimates = await (_db.select(_db.vehicleConsumptionEstimateHistory)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.asc(t.anchorEndAt)]))
        .get();
    final estimateRows = [
      for (final e in estimates)
        <String, Object?>{
          'id': e.id,
          'anchorEndAt': e.anchorEndAt.toUtc().toIso8601String(),
          'recordedAt': e.recordedAt.toUtc().toIso8601String(),
          'reliability': e.reliability,
          'litersPer100Km': e.litersPer100Km,
          'litersPer100KmRoute': e.litersPer100KmRoute,
          'litersPer100KmCity': e.litersPer100KmCity,
          'litersPer100KmTraffic': e.litersPer100KmTraffic,
          'periodsInWindow': e.periodsInWindow,
        },
    ];

    Map<String, Object?>? galleryPayload;
    final galleries = await VehiclesRepository(_db).listPhotoGalleries(vehicleId);
    if (galleries.isNotEmpty) {
      final newest = galleries.first; // ordered desc by galleryIndex
      final photos =
          await VehiclesRepository(_db).listGalleryPhotos(newest.id);
      final photoRows = <Map<String, Object?>>[];
      for (final photo in photos) {
        final archivePath = await _packBytes(
          storageKey: photo.relativeFilePath,
          archiveRelativePath: p.join(
            newest.relativeDirectory,
            _fileNameForKey(
              photo.relativeFilePath,
              'gallery_${photo.id}.jpg',
            ),
          ),
          mediaOut: mediaOut,
        );
        if (archivePath == null) continue;
        photoRows.add({
          'id': photo.id,
          'relativeFilePath': archivePath,
          'description': photo.description,
          'capturedAt': photo.capturedAt.toUtc().toIso8601String(),
          'sortOrder': photo.sortOrder,
        });
      }
      if (photoRows.isNotEmpty) {
        galleryPayload = {
          'id': newest.id,
          'galleryIndex': newest.galleryIndex,
          'relativeDirectory': newest.relativeDirectory,
          'createdAt': newest.createdAt.toUtc().toIso8601String(),
          'photos': photoRows,
        };
      }
    }

    return {
      'formatVersion': VehicleSaleBundle.formatVersion,
      'bundleKind': VehicleSaleBundle.bundleKind,
      'module': VehicleSaleBundle.moduleId,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'vehicle': {
        'id': vehicle.id,
        'vehicleKind': vehicle.vehicleKind,
        'displayLabel': vehicle.displayLabel,
        'make': vehicle.make,
        'model': vehicle.model,
        'color': vehicle.color,
        'modelYear': vehicle.modelYear,
        'licensePlate': vehicle.licensePlate,
        'vin': vehicle.vin,
        'fuelTankCapacityLiters': vehicle.fuelTankCapacityLiters,
        'consumptionEstimationMode': vehicle.consumptionEstimationMode,
        'createdAt': vehicle.createdAt.toUtc().toIso8601String(),
        'updatedAt': vehicle.updatedAt.toUtc().toIso8601String(),
        'oilChangeIntervalAmount': oilAmount,
        'oilChangeCategory': VehicleMaintenanceCategoryWire.oil.wire,
      },
      'meterReadings': meterRows,
      'fuelPurchases': fuelRows,
      'maintenanceEvents': maintRows,
      'consumptionEstimateHistory': estimateRows,
      'gallery': galleryPayload,
    };
  }

  Future<String?> _packBytes({
    required String storageKey,
    required String archiveRelativePath,
    required Map<String, List<int>> mediaOut,
  }) async {
    if (storageKey.isEmpty || isKnownUnchangedMeterPhotoPath(storageKey)) {
      return null;
    }
    try {
      final bytes = await readPublicDocumentBytes(storageKey);
      final normalized = archiveRelativePath.replaceAll('\\', '/');
      mediaOut[normalized] = bytes;
      return normalized;
    } catch (_) {
      return null;
    }
  }

  String _fileNameForKey(String storageKey, String fallback) {
    if (storageKey.startsWith('content://') || storageKey.startsWith('web:')) {
      return fallback;
    }
    final base = p.basename(storageKey);
    return base.isEmpty ? fallback : base;
  }
}
