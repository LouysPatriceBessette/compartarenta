import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'housing_export_file_sink.dart';

Future<HousingExportWriteResult> writeHousingExportJson({
  required String packageId,
  required String json,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName =
      'compartarenta-housing-${packageId.replaceAll(':', '-')}.json';
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(json, flush: true);
  return HousingExportWriteResult(
    kind: HousingExportWriteKind.file,
    path: file.path,
  );
}
