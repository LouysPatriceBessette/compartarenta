import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../widgets/app_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/housing/housing_proof_crop_screen.dart';
import 'proof_attachment_storage.dart';
import 'proof_expense_file_name.dart';
import 'proof_camera_capture.dart';
import 'proof_camera_permission.dart';

enum _ProofSource { camera, gallery, document }

// Browser safety guard only. Relay suitability is decided after compression.
const int _kWebImageSelectionAbsoluteLimitBytes = 20 * 1024 * 1024;

/// Picks a proof (camera, gallery, or document), crops images, compresses, and stores.
Future<StoredProof?> pickAndStoreProof(
  BuildContext context, {
  required HousingProofStorageScope scope,
}) async {
  final l10n = AppLocalizations.of(context);
  final cameraOptionState = await proofCameraOptionState();
  if (!context.mounted) return null;
  final source = await showAppModalBottomSheet<_ProofSource>(
    context: context,
    guardKey: 'proofPickSource',
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.housingRealizedExpensePickCamera),
            enabled: cameraOptionState != ProofCameraOptionState.unavailable,
            onTap: cameraOptionState == ProofCameraOptionState.unavailable
                ? null
                : () => Navigator.pop(ctx, _ProofSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.housingRealizedExpensePickGallery),
            onTap: () => Navigator.pop(ctx, _ProofSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file_outlined),
            title: Text(l10n.housingRealizedExpensePickDocument),
            onTap: () => Navigator.pop(ctx, _ProofSource.document),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  switch (source) {
    case _ProofSource.camera:
      return _pickCameraImage(context, scope: scope);
    case _ProofSource.gallery:
      return _pickGalleryImage(context, scope: scope);
    case _ProofSource.document:
      return _pickDocument(context, scope: scope);
  }
}

Future<StoredProof?> _pickCameraImage(
  BuildContext context, {
  required HousingProofStorageScope scope,
}) async {
  if (kIsWeb) {
    if (await proofCameraOptionState() == ProofCameraOptionState.unavailable) {
      return null;
    }
    if (!context.mounted) return null;
    final captured = await captureProofPhotoWeb(context);
    if (captured == null || !context.mounted) return null;
    if (captured.length > _kWebImageSelectionAbsoluteLimitBytes) {
      _showProofMessage(
        context,
        AppLocalizations.of(context).housingRealizedExpenseProofImageTooLarge,
      );
      return null;
    }
    final cropped = await _cropImageBytes(context, captured);
    if (cropped == null) return null;
    final name = 'proof-camera-${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _storeWebImageBytes(
      bytes: cropped,
      displayFileName: name,
    );
  }
  final granted = await ensureProofCameraPermission();
  if (!granted) return null;
  if (!context.mounted) return null;
  return _pickImageWithPicker(context, fromCamera: true, scope: scope);
}

Future<StoredProof?> _pickGalleryImage(
  BuildContext context, {
  required HousingProofStorageScope scope,
}) async {
  if (kIsWeb) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return null;
    final picked = result.files.single;
    if (!_isSupportedImageName(picked.name)) {
      _showProofMessage(
        context,
        AppLocalizations.of(context).housingRealizedExpenseProofImagesOnly,
      );
      return null;
    }
    if (picked.size > _kWebImageSelectionAbsoluteLimitBytes) {
      _showProofMessage(
        context,
        AppLocalizations.of(context).housingRealizedExpenseProofImageTooLarge,
      );
      return null;
    }
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    final cropped = await _cropImageBytes(context, bytes);
    if (cropped == null) return null;
    final name = _normalizedImageDisplayName(
      picked.name.trim().isEmpty ? 'proof.jpg' : picked.name,
    );
    return _storeWebImageBytes(
      bytes: cropped,
      displayFileName: name,
    );
  }
  return _pickImageWithPicker(context, fromCamera: false, scope: scope);
}

Future<StoredProof?> _pickImageWithPicker(
  BuildContext context, {
  required bool fromCamera,
  required HousingProofStorageScope scope,
}) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 95,
  );
  if (file == null || !context.mounted) return null;

  final bytes = await file.readAsBytes();
  if (kIsWeb &&
      bytes.length > _kWebImageSelectionAbsoluteLimitBytes &&
      context.mounted) {
    _showProofMessage(
      context,
      AppLocalizations.of(context).housingRealizedExpenseProofImageTooLarge,
    );
    return null;
  }
  if (!context.mounted) return null;
  final cropped = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => HousingProofCropScreen(imageBytes: bytes),
    ),
  );
  if (cropped == null) return null;

  final name = _normalizedImageDisplayName(
    file.name.trim().isEmpty ? 'proof.jpg' : file.name,
  );
  if (kIsWeb) {
    return _storeWebImageBytes(
      bytes: cropped,
      displayFileName: name,
    );
  }
  return ProofAttachmentStorage.persistPickedImageBytes(
    bytes: cropped,
    scope: scope,
  );
}

Future<Uint8List?> _cropImageBytes(
  BuildContext context,
  Uint8List bytes,
) async {
  if (!context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => HousingProofCropScreen(imageBytes: bytes),
    ),
  );
}

Future<StoredProof?> _pickDocument(
  BuildContext context, {
  required HousingProofStorageScope scope,
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: kIsWeb,
  );
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final name = picked.name.trim().isEmpty ? 'document' : picked.name;
  if (kIsWeb) {
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return _storeWebBytes(
      bytes: bytes,
      displayFileName: name,
      mediaType: _mediaTypeForName(name),
    );
  }
  final path = picked.path;
  if (path == null) {
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return ProofAttachmentStorage.persistFromBytes(
      bytes: bytes,
      scope: scope,
      sourceExtension: extensionFromProofFileName(name),
    );
  }
  final file = File(path);
  return ProofAttachmentStorage.persistFromFile(
    source: file,
    displayFileName: name,
    scope: scope,
    compressImage: true,
  );
}

String _normalizedImageDisplayName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.heic')) {
    return name;
  }
  return '$name.jpg';
}

bool _isSupportedImageName(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.heic');
}

void _showProofMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<StoredProof> _storeWebBytes({
  required List<int> bytes,
  required String displayFileName,
  required String mediaType,
}) async {
  final hash = await ProofAttachmentStorage.sha256Hex(bytes);
  final dataUrl = 'data:$mediaType;base64,${base64Encode(bytes)}';
  return StoredProof(
    filePath: dataUrl,
    displayFileName: displayFileName,
    contentHash: hash,
  );
}

Future<StoredProof> _storeWebImageBytes({
  required List<int> bytes,
  required String displayFileName,
}) async {
  final compressed = await ProofAttachmentStorage.compressImageBytesForRelay(
    bytes,
  );
  if (compressed != null && compressed.isNotEmpty) {
    final normalizedName = _normalizedImageDisplayName(displayFileName);
    final jpegName = normalizedName.replaceAll(
      RegExp(r'\.[^.]+$'),
      '.jpg',
    );
    return _storeWebBytes(
      bytes: compressed,
      displayFileName: jpegName,
      mediaType: 'image/jpeg',
    );
  }
  return _storeWebBytes(
    bytes: bytes,
    displayFileName: displayFileName,
    mediaType: _mediaTypeForName(displayFileName),
  );
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
