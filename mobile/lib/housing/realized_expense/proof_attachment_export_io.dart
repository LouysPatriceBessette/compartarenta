import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

Future<bool> exportStoredProofCopy({
  required String displayFileName,
  required String filePath,
}) async {
  final trimmedPath = filePath.trim();
  if (trimmedPath.isEmpty) return false;
  final file = File(trimmedPath);
  if (!await file.exists()) return false;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return false;
  final ext = p.extension(displayFileName).toLowerCase().replaceFirst('.', '');
  final saved = await FilePicker.platform.saveFile(
    fileName: displayFileName,
    type: ext.isEmpty ? FileType.any : FileType.custom,
    allowedExtensions: ext.isEmpty ? null : <String>[ext],
    bytes: Uint8List.fromList(bytes),
  );
  return saved != null && saved.isNotEmpty;
}
