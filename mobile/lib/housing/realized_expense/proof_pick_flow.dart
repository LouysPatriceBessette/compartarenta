import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/housing/housing_proof_crop_screen.dart';
import 'proof_attachment_storage.dart';

enum _ProofSource { camera, gallery, document }

/// Picks a proof (camera, gallery, or document), crops images, compresses, and stores.
Future<StoredProof?> pickAndStoreProof(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<_ProofSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.housingRealizedExpensePickCamera),
            onTap: () => Navigator.pop(ctx, _ProofSource.camera),
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
    case _ProofSource.gallery:
      return _pickImage(context, source == _ProofSource.camera);
    case _ProofSource.document:
      return _pickDocument(context);
  }
}

Future<StoredProof?> _pickImage(BuildContext context, bool fromCamera) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 95,
  );
  if (file == null || !context.mounted) return null;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  final cropped = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => HousingProofCropScreen(imageBytes: bytes),
    ),
  );
  if (cropped == null) return null;

  final name = file.name.trim().isEmpty ? 'proof.jpg' : file.name;
  return ProofAttachmentStorage.persistFromBytes(
    bytes: cropped,
    displayFileName: name.endsWith('.jpg') || name.endsWith('.jpeg')
        ? name
        : '$name.jpg',
  );
}

Future<StoredProof?> _pickDocument(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(withData: false);
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final path = picked.path;
  if (path == null) return null;
  final file = File(path);
  final name = picked.name.trim().isEmpty ? 'document' : picked.name;
  return ProofAttachmentStorage.persistFromFile(
    source: file,
    displayFileName: name,
    compressImage: false,
  );
}
