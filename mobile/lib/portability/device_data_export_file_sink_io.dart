import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'device_data_export_file_name.dart';
import '../housing/portability/housing_export_file_sink.dart';

const _publicDocumentsChannel = MethodChannel('com.compartarenta/public_documents');
const _exportFolderName = 'Compartarenta';

Future<HousingExportWriteResult> writeDeviceDataExportJson({
  required String json,
}) async {
  final fileName = deviceDataExportFileName();
  if (Platform.isAndroid) {
    await _publicDocumentsChannel.invokeMethod<String>(
      'writeTextFile',
      <String, String>{
        'subDir': _exportFolderName,
        'fileName': fileName,
        'content': json,
      },
    );
    return HousingExportWriteResult(
      kind: HousingExportWriteKind.file,
      fileName: fileName,
    );
  }

  final dir = await _userDocumentsCompartarentaDir();
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(json, flush: true);
  return HousingExportWriteResult(
    kind: HousingExportWriteKind.file,
    fileName: fileName,
  );
}

Future<Directory> _userDocumentsCompartarentaDir() async {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return Directory(p.join(home, 'Documents', _exportFolderName));
  }
  final base = await getApplicationDocumentsDirectory();
  return Directory(p.join(base.path, _exportFolderName));
}
