import 'package:flutter/services.dart';

import '../housing/portability/housing_export_file_sink.dart';
import 'device_data_export_file_name.dart';

Future<HousingExportWriteResult> writeDeviceDataExportJson({
  required String json,
}) async {
  final fileName = deviceDataExportFileName();
  await Clipboard.setData(ClipboardData(text: json));
  return HousingExportWriteResult(
    kind: HousingExportWriteKind.clipboard,
    fileName: fileName,
  );
}
