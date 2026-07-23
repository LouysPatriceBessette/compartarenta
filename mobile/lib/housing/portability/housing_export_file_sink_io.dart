import '../../portability/bojairu_documents_layout.dart';
import '../../portability/public_documents_file_sink.dart';
import 'housing_export_file_name.dart';
import 'housing_export_file_sink.dart';

Future<HousingExportWriteResult> writeHousingExportJson({
  required String packageId,
  required String json,
  required String languageCode,
}) async {
  final fileName = housingExportFileName(languageCode: languageCode);
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
