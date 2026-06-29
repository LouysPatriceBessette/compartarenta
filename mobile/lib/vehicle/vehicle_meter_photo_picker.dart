import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../portability/compartarenta_documents_layout.dart';
import '../portability/public_documents_file_sink.dart';
import 'vehicle_gallery_storage.dart';

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

/// Picks a meter photo from the device camera; returns a local source path.
Future<String?> pickVehicleMeterPhotoSource(BuildContext context) async {
  final picker = ImagePicker();
  final file =
      await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  if (file == null) return null;
  return file.path;
}

/// Writes under public `Documents/Compartarenta/Car/<vehicleId>/Odometer/`.
Future<String> storeVehicleMeterPhotoFromSource({
  required String vehicleId,
  required String sourcePath,
}) async {
  if (sourcePath.startsWith('content://') ||
      sourcePath.startsWith('web:')) {
    return sourcePath;
  }
  if (kIsWeb) {
    return p.join(
      CompartarentaDocumentsLayout.vehicleOdometerPhotosRelativeSubDir(
        vehicleId: vehicleId,
      ),
      p.basename(sourcePath),
    );
  }
  final bytes = await File(sourcePath).readAsBytes();
  final ext = p.extension(sourcePath);
  final fileName = vehicleGalleryTimestampFileName(ext.isEmpty ? '.jpg' : ext);
  final relativeSubDir =
      CompartarentaDocumentsLayout.vehicleOdometerPhotosRelativeSubDir(
    vehicleId: vehicleId,
  );
  final written = await writePublicDocumentBytes(
    relativeSubDir: relativeSubDir,
    fileName: fileName,
    bytes: bytes,
    mimeType: _mimeTypeForExtension(ext),
  );
  return written.storageKey;
}

Future<String?> pickAndStoreVehicleMeterPhoto(
  BuildContext context, {
  required String vehicleId,
}) async {
  final source = await pickVehicleMeterPhotoSource(context);
  if (source == null) return null;
  return storeVehicleMeterPhotoFromSource(
    vehicleId: vehicleId,
    sourcePath: source,
  );
}
