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
  // Keep proof images comfortably below relay request limits after base64 + envelope overhead.
  static const int _targetCompressedImageBytes = 120 * 1024;
  static const List<({int maxDimension, int quality})> _compressionSteps = [
    (maxDimension: 960, quality: 60),
    (maxDimension: 800, quality: 50),
    (maxDimension: 640, quality: 42),
    (maxDimension: 512, quality: 35),
  ];

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
    final bytes = await source.readAsBytes();
    if (isImage && compressImage && !kIsWeb) {
      final compressed = await _compressImageBytesForRelay(bytes);
      if (compressed != null) {
        return persistFromBytes(
          bytes: compressed,
          displayFileName: _jpegDisplayName(displayFileName),
        );
      }
    }
    return persistFromBytes(bytes: bytes, displayFileName: displayFileName);
  }

  /// Persists picked/cropped image bytes after an explicit compression step.
  static Future<StoredProof> persistPickedImageBytes({
    required List<int> bytes,
    required String displayFileName,
  }) async {
    if (!kIsWeb) {
      final compressed = await _compressImageBytesForRelay(bytes);
      if (compressed != null) {
        return persistFromBytes(
          bytes: compressed,
          displayFileName: _jpegDisplayName(displayFileName),
        );
      }
    }
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

  static Future<Uint8List?> _compressImageBytesForRelay(List<int> bytes) async {
    Uint8List? smallest;
    for (final step in _compressionSteps) {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        minWidth: step.maxDimension,
        minHeight: step.maxDimension,
        quality: step.quality,
        format: CompressFormat.jpeg,
      );
      if (compressed.isEmpty) continue;
      final candidate = Uint8List.fromList(compressed);
      if (smallest == null || candidate.lengthInBytes < smallest.lengthInBytes) {
        smallest = candidate;
      }
      if (candidate.lengthInBytes <= _targetCompressedImageBytes) {
        return candidate;
      }
    }
    return smallest;
  }
}
