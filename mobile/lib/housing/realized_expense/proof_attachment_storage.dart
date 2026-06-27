import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import '../../portability/compartarenta_documents_layout.dart';
import '../../portability/public_documents_file_sink.dart';
import 'proof_expense_file_name.dart';

/// Scope for housing expense proof files under public Documents.
class HousingProofStorageScope {
  const HousingProofStorageScope({
    required this.agreementPeriodStart,
    required this.agreementPeriodEnd,
  });

  final DateTime agreementPeriodStart;
  final DateTime agreementPeriodEnd;

  String get relativeSubDir =>
      CompartarentaDocumentsLayout.housingExpenseProofsRelativeSubDir(
        agreementPeriodStart: agreementPeriodStart,
        agreementPeriodEnd: agreementPeriodEnd,
      );
}

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

/// Writes proofs under public Documents/Compartarenta/Housing/…/ExpenseProofs.
class ProofAttachmentStorage {
  // Keep proof images comfortably below relay request limits after base64 + envelope overhead.
  static const int _targetCompressedImageBytes = 120 * 1024;
  static const List<({int maxDimension, int quality})> _compressionSteps = [
    (maxDimension: 960, quality: 60),
    (maxDimension: 800, quality: 50),
    (maxDimension: 640, quality: 42),
    (maxDimension: 512, quality: 35),
  ];

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
    required HousingProofStorageScope scope,
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
          scope: scope,
          sourceExtension: '.jpg',
        );
      }
    }
    return persistFromBytes(
      bytes: bytes,
      scope: scope,
      sourceExtension: ext.isEmpty ? extensionFromProofFileName(displayFileName) : ext,
    );
  }

  /// Persists picked/cropped image bytes after an explicit compression step.
  static Future<StoredProof> persistPickedImageBytes({
    required List<int> bytes,
    required HousingProofStorageScope scope,
  }) async {
    final compressed = await compressImageBytesForRelay(bytes);
    if (compressed != null) {
      return persistFromBytes(
        bytes: compressed,
        scope: scope,
        sourceExtension: '.jpg',
      );
    }
    return persistFromBytes(
      bytes: bytes,
      scope: scope,
      sourceExtension: '.jpg',
    );
  }

  static Future<Uint8List?> compressImageBytesForRelay(List<int> bytes) {
    return _compressImageBytesForRelay(bytes);
  }

  /// Writes a temporary proof file while the expense form is open.
  static Future<StoredProof> persistFromBytes({
    required List<int> bytes,
    required HousingProofStorageScope scope,
    required String sourceExtension,
    String? fileNameOverride,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('persistFromBytes requires native IO');
    }
    final fileName = fileNameOverride ??
        temporaryProofFileName(extension: sourceExtension);
    final mimeType = mimeTypeForProofFileName(fileName);
    final written = await writePublicDocumentBytes(
      relativeSubDir: scope.relativeSubDir,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    final hash = await sha256Hex(bytes);
    return StoredProof(
      filePath: written.storageKey,
      displayFileName: fileName,
      contentHash: hash,
    );
  }

  /// Renames temporary proofs to final names at expense submission (immutable after).
  static Future<List<StoredProof>> finalizeProofsForSubmission({
    required List<StoredProof> proofs,
    required HousingProofStorageScope scope,
    required DateTime paymentDate,
    required DateTime submittedAt,
    required String lineTitleLabel,
    required int amountMinor,
  }) async {
    if (proofs.isEmpty) return proofs;
    if (kIsWeb) return proofs;

    final existingNames = await listPublicDocumentFileNames(
      relativeSubDir: scope.relativeSubDir,
    );
    final usedNames = existingNames.toSet();
    final finalized = <StoredProof>[];

    for (final proof in proofs) {
      if (!isTemporaryProofFileName(proof.displayFileName)) {
        finalized.add(proof);
        continue;
      }
      final ext = extensionFromProofFileName(proof.displayFileName);
      var suffix = 0;
      late String targetName;
      while (true) {
        suffix++;
        targetName = finalProofFileName(
          paymentDate: paymentDate,
          submittedAt: submittedAt,
          lineTitleLabel: lineTitleLabel,
          amountMinor: amountMinor,
          extension: ext,
          collisionSuffix: suffix,
        );
        if (!usedNames.contains(targetName)) break;
      }
      usedNames.add(targetName);
      final mimeType = mimeTypeForProofFileName(targetName);
      final renamed = await renamePublicDocument(
        fromStorageKey: proof.filePath,
        relativeSubDir: scope.relativeSubDir,
        toFileName: targetName,
        mimeType: mimeType,
      );
      finalized.add(
        StoredProof(
          filePath: renamed.storageKey,
          displayFileName: targetName,
          contentHash: proof.contentHash,
        ),
      );
    }
    return finalized;
  }

  /// Peer import: write submitted proof bytes under local Housing folder.
  static Future<StoredProof> persistImportedSubmittedProof({
    required List<int> bytes,
    required HousingProofStorageScope scope,
    required String submittedFileName,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('persistImportedSubmittedProof requires native IO');
    }
    final fileName = p.basename(submittedFileName.trim());
    final safeName =
        fileName.isEmpty ? 'proof.bin' : fileName.replaceAll('/', '_');
    final mimeType = mimeTypeForProofFileName(safeName);
    final written = await writePublicDocumentBytes(
      relativeSubDir: scope.relativeSubDir,
      fileName: safeName,
      bytes: bytes,
      mimeType: mimeType,
    );
    final hash = await sha256Hex(bytes);
    return StoredProof(
      filePath: written.storageKey,
      displayFileName: safeName,
      contentHash: hash,
    );
  }

  static Future<List<int>> readProofBytes(String storageKey) {
    return readPublicDocumentBytes(storageKey);
  }

  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};

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
