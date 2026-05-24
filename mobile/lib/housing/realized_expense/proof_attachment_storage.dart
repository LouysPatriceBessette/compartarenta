import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-device folder for expense proof files (under app documents).
const String kExpenseProofsFolderName = 'CompartarentaExpenseProofs';

/// Persisted proof artifact metadata.
class StoredProof {
  const StoredProof({
    required this.filePath,
    required this.displayFileName,
    this.contentHash,
  });

  final String filePath;
  final String displayFileName;
  final String? contentHash;
}

/// Writes proofs under [kExpenseProofsFolderName] with optional image compression.
class ProofAttachmentStorage {
  static Future<Directory> proofsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, kExpenseProofsFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> sha256Hex(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Persists [source] (image or document). Images are compressed when supported.
  static Future<StoredProof> persistFromFile({
    required File source,
    required String displayFileName,
    bool compressImage = true,
  }) async {
    final ext = p.extension(displayFileName).toLowerCase();
    final isImage = _imageExtensions.contains(ext);
    if (isImage && compressImage && !kIsWeb) {
      final compressed = await FlutterImageCompress.compressWithFile(
        source.absolute.path,
        minWidth: 1920,
        minHeight: 1920,
        quality: 82,
      );
      if (compressed != null && compressed.isNotEmpty) {
        return persistFromBytes(
          bytes: compressed,
          displayFileName: _jpegDisplayName(displayFileName),
        );
      }
    }
    final bytes = await source.readAsBytes();
    return persistFromBytes(bytes: bytes, displayFileName: displayFileName);
  }

  static Future<StoredProof> persistFromBytes({
    required List<int> bytes,
    required String displayFileName,
  }) async {
    final dir = await proofsDirectory();
    final safeName = _safeFileName(displayFileName);
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final outPath = p.join(dir.path, '$stamp-$safeName');
    final file = File(outPath);
    await file.writeAsBytes(bytes, flush: true);
    final hash = await sha256Hex(bytes);
    return StoredProof(
      filePath: outPath,
      displayFileName: displayFileName,
      contentHash: hash,
    );
  }

  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};

  static String _jpegDisplayName(String name) {
    final base = p.basenameWithoutExtension(name);
    return '$base.jpg';
  }

  static String _safeFileName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return base.isEmpty ? 'proof' : base;
  }
}
