import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
  if (path.isEmpty) return out;
  if (path.startsWith('data:')) return out;
  try {
    final List<int> bytes;
    if (path.startsWith('content://')) {
      bytes = await ProofAttachmentStorage.readProofBytes(path);
    } else {
      final file = File(path);
      if (!await file.exists()) return out;
      bytes = await file.readAsBytes();
    }
    if (bytes.isEmpty) return out;
    out['bytes_b64'] = base64Encode(bytes);
    out['media_type'] = _mediaTypeForName(attachment.displayFileName);
  } on Object {
    return out;
  }
  return out;
}

Future<String?> importSyncedProofAttachmentPath(
  Map<dynamic, dynamic> raw, {
  required HousingProofStorageScope scope,
}) async {
  final bytesBase64 = raw['bytes_b64'] as String?;
  if (bytesBase64 == null || bytesBase64.isEmpty) return null;
  final displayFileName = raw['display_file_name'] as String? ?? 'proof';
  try {
    final stored = await ProofAttachmentStorage.persistImportedSubmittedProof(
      bytes: base64Decode(bytesBase64),
      scope: scope,
      submittedFileName: displayFileName,
    );
    return stored.filePath;
  } on Object {
    return null;
  }
}

String _mediaTypeForName(String displayFileName) {
  return switch (p.extension(displayFileName).toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    '.pdf' => 'application/pdf',
    '.txt' => 'text/plain',
    '.json' => 'application/json',
    _ => 'application/octet-stream',
  };
}
