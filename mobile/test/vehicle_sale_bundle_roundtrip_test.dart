import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:compartarenta/portability/compartarenta_documents_layout.dart';
import 'package:compartarenta/vehicle/portability/vehicle_sale_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sale zip contains JSON under Compartarenta/ and media paths', () {
    final jsonName = '2026-07-14-Data-of-Test.json';
    final jsonPath =
        '${CompartarentaDocumentsLayout.rootFolderName}/$jsonName';
    final payload = <String, Object?>{
      'formatVersion': VehicleSaleBundle.formatVersion,
      'bundleKind': VehicleSaleBundle.bundleKind,
      'module': VehicleSaleBundle.moduleId,
      'vehicle': {
        'id': 'vehicle:src',
        'displayLabel': 'Test',
        'oilChangeIntervalAmount': 50000,
        'vehicleKind': 'car',
      },
      'meterReadings': <Object?>[],
      'fuelPurchases': <Object?>[],
      'maintenanceEvents': <Object?>[],
      'consumptionEstimateHistory': <Object?>[],
      'gallery': null,
    };
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final mediaPath =
        '${CompartarentaDocumentsLayout.rootFolderName}/'
        '${CompartarentaDocumentsLayout.carModuleFolderName}/'
        'vehicle:src/Odometer/photo.jpg';
    final archive = Archive()
      ..addFile(ArchiveFile(jsonPath, jsonBytes.length, jsonBytes))
      ..addFile(ArchiveFile(mediaPath, 3, [1, 2, 3]));
    final zip = ZipEncoder().encode(archive);
    final decoded = ZipDecoder().decodeBytes(zip, verify: true);
    final names = decoded.files.map((f) => f.name).toList();
    expect(names, contains(jsonPath));
    expect(names, contains(mediaPath));
  });
}
