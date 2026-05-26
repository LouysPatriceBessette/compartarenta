import '../../db/app_database.dart';

Future<Map<String, dynamic>> buildSyncedProofAttachmentPayload(
  RealizedExpenseAttachment attachment,
) async {
  return {
    'display_file_name': attachment.displayFileName,
    if (attachment.contentHash != null) 'content_hash': attachment.contentHash,
  };
}

Future<String?> importSyncedProofAttachmentPath(Map<dynamic, dynamic> raw) async {
  return null;
}
