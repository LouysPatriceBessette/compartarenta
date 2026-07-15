import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Zip written after a successful sale export for `adb run-as` pull.
const kQaVehicleSaleExportZipFileName =
    'compartarenta_qa_vehicle_sale_export.zip';

/// Zip pushed by the QA orchestrator before the import Maestro flow.
const kQaVehicleSaleImportZipFileName =
    'compartarenta_qa_vehicle_sale_import.zip';

/// Persists sale-export zip bytes under app documents (debug Android only).
Future<void> qaWriteVehicleSaleExportZip(List<int> zipBytes) async {
  if (!kDebugMode || kIsWeb) return;
  if (zipBytes.isEmpty) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$kQaVehicleSaleExportZipFileName');
    await file.writeAsBytes(zipBytes, flush: true);
    debugPrint(
      'vehicle_sale qa: export wrote ${zipBytes.length} bytes to '
      '$kQaVehicleSaleExportZipFileName',
    );
  } catch (e) {
    debugPrint('vehicle_sale qa: export zip write failed: $e');
  }
}

/// Returns import zip bytes when the orchestrator pushed a marker file.
Future<Uint8List?> qaReadVehicleSaleImportZipBytes() async {
  if (!kDebugMode || kIsWeb) return null;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$kQaVehicleSaleImportZipFileName');
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    debugPrint(
      'vehicle_sale qa: import using ${bytes.length} bytes from '
      '$kQaVehicleSaleImportZipFileName',
    );
    return bytes;
  } catch (e) {
    debugPrint('vehicle_sale qa: import zip read failed: $e');
    return null;
  }
}
