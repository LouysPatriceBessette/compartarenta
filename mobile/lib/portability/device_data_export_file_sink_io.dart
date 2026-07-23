import '../portability/bojairu_documents_layout.dart';
import '../portability/public_documents_file_sink.dart';
import 'device_data_export_file_name.dart';
import '../housing/portability/housing_export_file_sink.dart';

Future<HousingExportWriteResult> writeDeviceDataExportJson({
  required String json,
}) async {
  final fileName = deviceDataExportFileName();
  await writePublicDocumentText(
    relativeSubDir: BojairuDocumentsLayout.backupsRelativeSubDir(),
    fileName: fileName,
    content: json,
  );
  return HousingExportWriteResult(
    kind: HousingExportWriteKind.file,
    fileName: fileName,
  );
}
