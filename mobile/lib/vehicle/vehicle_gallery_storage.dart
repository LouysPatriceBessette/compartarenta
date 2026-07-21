import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../portability/compartarenta_documents_layout.dart';
import '../portability/public_documents_file_sink.dart';
import '../widgets/app_dialog.dart';

String vehicleGalleryTimestampFileName(String extension) {
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
  return '$stamp.$ext';
}

String vehicleGalleryRelativeSubDir({
  required String vehicleId,
  required int galleryIndex,
}) {
  return CompartarentaDocumentsLayout.vehicleGalleryRelativeSubDir(
    vehicleId: vehicleId,
    galleryIndex: galleryIndex,
  );
}

String _mimeTypeForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

/// Writes a gallery photo under public `Documents/Bojairũ/Car/…`.
Future<String> storeVehicleGalleryPhotoFromSource({
  required String vehicleId,
  required int galleryIndex,
  required String sourcePath,
}) async {
  if (kIsWeb) {
    return p.join(
      vehicleGalleryRelativeSubDir(
        vehicleId: vehicleId,
        galleryIndex: galleryIndex,
      ),
      p.basename(sourcePath),
    );
  }
  final bytes = await File(sourcePath).readAsBytes();
  final ext = p.extension(sourcePath);
  final fileName = vehicleGalleryTimestampFileName(ext.isEmpty ? '.jpg' : ext);
  final relativeSubDir = vehicleGalleryRelativeSubDir(
    vehicleId: vehicleId,
    galleryIndex: galleryIndex,
  );
  final written = await writePublicDocumentBytes(
    relativeSubDir: relativeSubDir,
    fileName: fileName,
    bytes: bytes,
    mimeType: _mimeTypeForExtension(ext),
  );
  return written.storageKey;
}

Future<ImageProvider?> vehicleGalleryPhotoImageProvider(String storageKey) async {
  if (kIsWeb || storageKey.isEmpty) return null;
  if (storageKey.startsWith('content://') ||
      !p.isAbsolute(storageKey) && !storageKey.contains('vehicle_meter_photos')) {
    try {
      final bytes = await readPublicDocumentBytes(storageKey);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }
  final file = File(storageKey);
  if (await file.exists()) return FileImage(file);
  return null;
}

Future<String?> pickVehicleGalleryPhotoSource(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final source = await showAppModalBottomSheet<ImageSource>(
    context: context,
    guardKey: 'vehicleGalleryPhotoSource',
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.vehicleMeterPhotoCamera),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.vehicleMeterPhotoGallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(source: source, imageQuality: 85);
  if (file == null) return null;
  return file.path;
}
