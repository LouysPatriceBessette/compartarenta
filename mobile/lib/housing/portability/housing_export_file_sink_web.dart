import 'package:flutter/services.dart';

import 'housing_export_file_sink.dart';

Future<HousingExportWriteResult> writeHousingExportJson({
  required String packageId,
  required String json,
}) async {
  await Clipboard.setData(ClipboardData(text: json));
  return const HousingExportWriteResult(kind: HousingExportWriteKind.clipboard);
}
