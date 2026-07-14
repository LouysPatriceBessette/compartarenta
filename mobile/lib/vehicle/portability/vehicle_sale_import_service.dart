import 'dart:convert';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../portability/compartarenta_documents_layout.dart';
import '../../portability/public_documents_file_sink.dart';
import '../../vehicle/vehicle_meter_photo_path.dart';
import '../../vehicle/vehicle_owned_active_cap.dart';
import '../../vehicle/vehicle_owner_contact.dart';
import 'vehicle_sale_bundle.dart';

/// Imports a sale/transfer zip into a new owned vehicle.
class VehicleSaleImportService {
  VehicleSaleImportService(this._db);

  final AppDatabase _db;

  Future<String> importZipBytes(List<int> zipBytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes, verify: true);
    } catch (e) {
      throw VehicleSaleImportException(
        VehicleSaleImportFailureKind.corruptArchive,
        e,
      );
    }

    final jsonEntry = _findJsonEntry(archive);
    if (jsonEntry == null) {
      throw const VehicleSaleImportException(
        VehicleSaleImportFailureKind.invalidBundle,
      );
    }

    final Map<String, Object?> payload;
    try {
      final text = utf8.decode(jsonEntry.content as List<int>);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('root not object');
      }
      payload = Map<String, Object?>.from(decoded);
    } catch (e) {
      throw VehicleSaleImportException(
        VehicleSaleImportFailureKind.invalidBundle,
        e,
      );
    }

    if (!_isValidSaleBundle(payload)) {
      throw const VehicleSaleImportException(
        VehicleSaleImportFailureKind.invalidBundle,
      );
    }

    final vehicleMap = Map<String, Object?>.from(payload['vehicle']! as Map);
    final sourceVehicleId = vehicleMap['id'] as String?;
    final displayLabel = (vehicleMap['displayLabel'] as String?)?.trim() ?? '';
    final oilAmount = vehicleMap['oilChangeIntervalAmount'];
    if (sourceVehicleId == null ||
        sourceVehicleId.isEmpty ||
        displayLabel.isEmpty ||
        oilAmount is! int) {
      throw const VehicleSaleImportException(
        VehicleSaleImportFailureKind.invalidBundle,
      );
    }

    final activeCount =
        await VehiclesRepository(_db).countActiveOwnedVehicles();
    if (activeCount >= kMaxActiveOwnedVehicles) {
      throw const VehicleActiveCapExceededException();
    }

    final newVehicleId = _newId('vehicle:');
    final pathRewrite = <String, String>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.replaceAll('\\', '/');
      if (name.toLowerCase().endsWith('.json')) continue;
      final rewritten = _rewriteArchivePath(
        archivePath: name,
        sourceVehicleId: sourceVehicleId,
        newVehicleId: newVehicleId,
      );
      if (rewritten == null) continue;
      final bytes = file.content as List<int>;
      final relativeSubDir = p.dirname(rewritten);
      final fileName = p.basename(rewritten);
      final mime = _mimeForFileName(fileName);
      try {
        final written = await writePublicDocumentBytes(
          relativeSubDir: relativeSubDir,
          fileName: fileName,
          bytes: bytes,
          mimeType: mime,
        );
        pathRewrite[name] = written.storageKey;
      } catch (e) {
        throw VehicleSaleImportException(
          VehicleSaleImportFailureKind.other,
          e,
        );
      }
    }

    try {
      return await _db.transaction(() async {
        final now = DateTime.now().toUtc();
        final createdAt = _parseDate(vehicleMap['createdAt']) ?? now;
        final updatedAt = _parseDate(vehicleMap['updatedAt']) ?? now;
        await _db.into(_db.vehicles).insert(
              VehiclesCompanion.insert(
                id: newVehicleId,
                ownerContactId: kVehicleOwnerSelfContactId,
                vehicleKind: vehicleMap['vehicleKind'] as String? ?? 'car',
                displayLabel: displayLabel,
                make: drift.Value(vehicleMap['make'] as String? ?? ''),
                model: drift.Value(vehicleMap['model'] as String? ?? ''),
                color: drift.Value(vehicleMap['color'] as String? ?? ''),
                modelYear: drift.Value(vehicleMap['modelYear'] as int?),
                licensePlate:
                    drift.Value(vehicleMap['licensePlate'] as String? ?? ''),
                vin: drift.Value(vehicleMap['vin'] as String? ?? ''),
                fuelTankCapacityLiters: drift.Value(
                  (vehicleMap['fuelTankCapacityLiters'] as num?)?.toDouble(),
                ),
                consumptionEstimationMode: drift.Value(
                  vehicleMap['consumptionEstimationMode'] as String? ??
                      'detailed',
                ),
                requireDetailedDrivingMixForBorrowers:
                    const drift.Value(false),
                createdAt: createdAt,
                updatedAt: updatedAt,
                saleImportUndoAvailable: const drift.Value(true),
              ),
            );

        final preview = (oilAmount ~/ 10).clamp(1, oilAmount);
        await _db.into(_db.vehicleMaintenanceRules).insert(
              VehicleMaintenanceRulesCompanion.insert(
                id: '$newVehicleId:rule:oil',
                vehicleId: newVehicleId,
                category:
                    vehicleMap['oilChangeCategory'] as String? ?? 'oil',
                intervalAmount: oilAmount,
                previewWindowAmount: drift.Value(preview),
              ),
            );

        final readingIdMap = <String, String>{};
        final readings = _asMapList(payload['meterReadings']);
        for (final row in readings) {
          final oldId = row['id'] as String? ?? '';
          if (oldId.isEmpty) continue;
          readingIdMap[oldId] = _newId('meter:');
        }
        for (final row in readings) {
          final oldId = row['id'] as String? ?? '';
          if (oldId.isEmpty) continue;
          final archivedPhoto = row['photoPath'] as String? ?? '';
          final photoPath = _resolveImportedPhotoPath(
            archivedPhoto: archivedPhoto,
            pathRewrite: pathRewrite,
          );
          final supersedesOld = row['supersedesReadingId'] as String?;
          await _db.into(_db.vehicleMeterReadings).insert(
                VehicleMeterReadingsCompanion.insert(
                  id: readingIdMap[oldId]!,
                  vehicleId: newVehicleId,
                  value: row['value'] as int? ?? 0,
                  unit: row['unit'] as String? ?? 'odometer_km',
                  photoPath: photoPath,
                  recordedAt: _parseDate(row['recordedAt']) ?? now,
                  recordedByContactId: kVehicleOwnerSelfContactId,
                  readingRole: row['readingRole'] as String? ?? 'standalone',
                  isCorrection:
                      drift.Value(row['isCorrection'] as bool? ?? false),
                  correctionNote:
                      drift.Value(row['correctionNote'] as String? ?? ''),
                  negativeGapAcknowledged: drift.Value(
                    row['negativeGapAcknowledged'] as bool? ?? false,
                  ),
                  isFullTank: drift.Value(row['isFullTank'] as bool?),
                  tankFillFraction:
                      drift.Value(row['tankFillFraction'] as int?),
                  resolvedAt: drift.Value(_parseDate(row['resolvedAt'])),
                  supersedesReadingId: drift.Value(
                    supersedesOld == null
                        ? null
                        : readingIdMap[supersedesOld],
                  ),
                ),
              );
        }

        for (final row in _asMapList(payload['fuelPurchases'])) {
          await _db.into(_db.fuelPurchases).insert(
                FuelPurchasesCompanion.insert(
                  id: _newId('fuel:'),
                  vehicleId: newVehicleId,
                  purchasedAt: _parseDate(row['purchasedAt']) ?? now,
                  costMinor: row['costMinor'] as int? ?? 0,
                  currency: row['currency'] as String? ?? 'CAD',
                  volumeLiters: drift.Value(
                    (row['volumeLiters'] as num?)?.toDouble(),
                  ),
                  meterReadingValue:
                      drift.Value(row['meterReadingValue'] as int?),
                  isFullTank: row['isFullTank'] as bool? ?? false,
                  tankFillFraction:
                      drift.Value(row['tankFillFraction'] as int?),
                  recordedByContactId: kVehicleOwnerSelfContactId,
                ),
              );
        }

        for (final row in _asMapList(payload['maintenanceEvents'])) {
          final archived = row['attachmentPath'] as String?;
          String? attachmentKey;
          if (archived != null && archived.isNotEmpty) {
            attachmentKey = pathRewrite[archived.replaceAll('\\', '/')];
          }
          await _db.into(_db.maintenanceEvents).insert(
                MaintenanceEventsCompanion.insert(
                  id: _newId('maint:'),
                  vehicleId: newVehicleId,
                  servicedAt: _parseDate(row['servicedAt']) ?? now,
                  category: row['category'] as String? ?? 'other',
                  costMinor: row['costMinor'] as int? ?? 0,
                  currency: row['currency'] as String? ?? 'CAD',
                  notes: drift.Value(row['notes'] as String? ?? ''),
                  attachmentPath: drift.Value(attachmentKey),
                  meterAtService: drift.Value(row['meterAtService'] as int?),
                  recordedByContactId: kVehicleOwnerSelfContactId,
                ),
              );
        }

        for (final row in _asMapList(payload['consumptionEstimateHistory'])) {
          await _db.into(_db.vehicleConsumptionEstimateHistory).insert(
                VehicleConsumptionEstimateHistoryCompanion.insert(
                  id: _newId('vest:'),
                  vehicleId: newVehicleId,
                  anchorEndAt: _parseDate(row['anchorEndAt']) ?? now,
                  recordedAt: _parseDate(row['recordedAt']) ?? now,
                  reliability: row['reliability'] as String? ?? 'unknown',
                  litersPer100Km:
                      (row['litersPer100Km'] as num?)?.toDouble() ?? 0,
                  litersPer100KmRoute: drift.Value(
                    (row['litersPer100KmRoute'] as num?)?.toDouble(),
                  ),
                  litersPer100KmCity: drift.Value(
                    (row['litersPer100KmCity'] as num?)?.toDouble(),
                  ),
                  litersPer100KmTraffic: drift.Value(
                    (row['litersPer100KmTraffic'] as num?)?.toDouble(),
                  ),
                  periodsInWindow: row['periodsInWindow'] as int? ?? 0,
                ),
              );
        }

        final galleryRaw = payload['gallery'];
        if (galleryRaw is Map) {
          final gallery = Map<String, Object?>.from(galleryRaw);
          final galleryIndex = gallery['galleryIndex'] as int? ?? 1;
          final relativeDirectory =
              CompartarentaDocumentsLayout.vehicleGalleryRelativeSubDir(
            vehicleId: newVehicleId,
            galleryIndex: galleryIndex,
          );
          final galleryId = _newId('vgal:');
          await _db.into(_db.vehiclePhotoGalleries).insert(
                VehiclePhotoGalleriesCompanion.insert(
                  id: galleryId,
                  vehicleId: newVehicleId,
                  galleryIndex: galleryIndex,
                  relativeDirectory: relativeDirectory,
                  createdAt: _parseDate(gallery['createdAt']) ?? now,
                ),
              );
          for (final row in _asMapList(gallery['photos'])) {
            final archived = row['relativeFilePath'] as String? ?? '';
            final storageKey = pathRewrite[archived.replaceAll('\\', '/')];
            if (storageKey == null || storageKey.isEmpty) continue;
            await _db.into(_db.vehicleGalleryPhotos).insert(
                  VehicleGalleryPhotosCompanion.insert(
                    id: _newId('vphoto:'),
                    galleryId: galleryId,
                    relativeFilePath: storageKey,
                    description:
                        drift.Value(row['description'] as String? ?? ''),
                    capturedAt: _parseDate(row['capturedAt']) ?? now,
                    sortOrder: drift.Value(row['sortOrder'] as int? ?? 0),
                  ),
                );
          }
        }

        return newVehicleId;
      });
    } on VehicleSaleImportException {
      rethrow;
    } on VehicleActiveCapExceededException {
      rethrow;
    } catch (e) {
      throw VehicleSaleImportException(
        VehicleSaleImportFailureKind.other,
        e,
      );
    }
  }

  ArchiveFile? _findJsonEntry(Archive archive) {
    ArchiveFile? fallback;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.replaceAll('\\', '/');
      if (!name.toLowerCase().endsWith('.json')) continue;
      if (name.startsWith('${CompartarentaDocumentsLayout.rootFolderName}/')) {
        return file;
      }
      fallback ??= file;
    }
    return fallback;
  }

  bool _isValidSaleBundle(Map<String, Object?> payload) {
    if (payload['bundleKind'] != VehicleSaleBundle.bundleKind) return false;
    if (payload['module'] != VehicleSaleBundle.moduleId) return false;
    final version = payload['formatVersion'];
    if (version is! int || version < 1) return false;
    if (payload['vehicle'] is! Map) return false;
    return true;
  }

  String? _rewriteArchivePath({
    required String archivePath,
    required String sourceVehicleId,
    required String newVehicleId,
  }) {
    final normalized = archivePath.replaceAll('\\', '/');
    final marker =
        '${CompartarentaDocumentsLayout.rootFolderName}/'
        '${CompartarentaDocumentsLayout.carModuleFolderName}/'
        '$sourceVehicleId/';
    if (!normalized.startsWith(marker)) return null;
    final rest = normalized.substring(marker.length);
    return '${CompartarentaDocumentsLayout.rootFolderName}/'
        '${CompartarentaDocumentsLayout.carModuleFolderName}/'
        '$newVehicleId/$rest';
  }

  String _resolveImportedPhotoPath({
    required String archivedPhoto,
    required Map<String, String> pathRewrite,
  }) {
    if (archivedPhoto.isEmpty) return '';
    if (isKnownUnchangedMeterPhotoPath(archivedPhoto)) {
      return archivedPhoto;
    }
    final key = archivedPhoto.replaceAll('\\', '/');
    return pathRewrite[key] ?? '';
  }

  List<Map<String, Object?>> _asMapList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, Object?>.from(item),
    ];
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  String _mimeForFileName(String fileName) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  String _newId(String prefix) {
    final bytes = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    return '$prefix${base64Url.encode(bytes).replaceAll('=', '')}';
  }
}
