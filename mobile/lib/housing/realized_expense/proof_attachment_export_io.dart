import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../portability/public_documents_file_sink.dart';
import 'proof_attachment_storage.dart';

Future<bool> exportStoredProofCopy({
  required String displayFileName,
  required String filePath,
}) async {
  final trimmedPath = filePath.trim();
  if (trimmedPath.isEmpty) return false;
  try {
    final bytes = trimmedPath.startsWith('data:')
        ? null
        : await ProofAttachmentStorage.readProofBytes(trimmedPath);
    if (bytes == null || bytes.isEmpty) return false;
    final ext = p.extension(displayFileName).toLowerCase().replaceFirst('.', '');
    final saved = await FilePicker.platform.saveFile(
      fileName: displayFileName,
      type: ext.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: ext.isEmpty ? null : <String>[ext],
      bytes: Uint8List.fromList(bytes),
    );
    return saved != null && saved.isNotEmpty;
  } on Object {
    return false;
  }
}

Future<Uint8List?> loadProofImageBytes(String filePath) async {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('data:')) return null;
  try {
    final bytes = await readPublicDocumentBytes(trimmed);
    if (bytes.isEmpty) return null;
    return Uint8List.fromList(bytes);
  } on Object {
    return null;
  }
}
