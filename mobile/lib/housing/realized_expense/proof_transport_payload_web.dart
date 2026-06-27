import '../../db/app_database.dart';
import 'proof_attachment_storage.dart';

Future<Map<String, dynamic>> buildSyncedProofAttachmentPayload(
  RealizedExpenseAttachment attachment,
) async {
  final out = <String, dynamic>{
    'display_file_name': attachment.displayFileName,
    if (attachment.contentHash != null) 'content_hash': attachment.contentHash,
  };
  final path = attachment.filePath.trim();
  if (path.startsWith('data:')) {
    final commaIndex = path.indexOf(',');
    final semicolonIndex = path.indexOf(';');
    if (commaIndex > 5 && semicolonIndex > 5 && semicolonIndex < commaIndex) {
      out['media_type'] = path.substring(5, semicolonIndex);
      out['bytes_b64'] = path.substring(commaIndex + 1);
    }
  }
  return out;
}

Future<String?> importSyncedProofAttachmentPath(
  Map<dynamic, dynamic> raw, {
  HousingProofStorageScope? scope,
}) async {
  final bytesBase64 = raw['bytes_b64'] as String?;
  if (bytesBase64 == null || bytesBase64.isEmpty) return null;
  final mediaType = raw['media_type'] as String?;
  if (mediaType == null || mediaType.isEmpty) return null;
  return 'data:$mediaType;base64,$bytesBase64';
}
