import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../widgets/app_dialog.dart';
import '../l10n/app_localizations.dart';

/// Stores a meter photo under app documents and returns the relative path.
Future<String?> pickAndStoreVehicleMeterPhoto(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final source = await showAppModalBottomSheet<ImageSource>(
    context: context,
    guardKey: 'vehicleMeterPhotoSource',
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

  if (kIsWeb) {
    return 'web:${file.name}';
  }
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'vehicle_meter_photos'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final name =
      'meter_${DateTime.now().toUtc().millisecondsSinceEpoch}${p.extension(file.path)}';
  final dest = File(p.join(dir.path, name));
  await File(file.path).copy(dest.path);
  return p.join('vehicle_meter_photos', name);
}
