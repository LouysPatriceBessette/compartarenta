import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../portability/public_documents_file_sink.dart';

class VehicleStoredImage extends StatelessWidget {
  const VehicleStoredImage({super.key, required this.path, this.height = 220});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        height: height,
        child: const Center(child: Icon(Icons.image_outlined, size: 48)),
      );
    }
    return FutureBuilder<ImageProvider?>(
      future: _resolve(path),
      builder: (context, snap) {
        final provider = snap.data;
        if (provider == null) {
          return SizedBox(
            height: height,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return Image(
          image: provider,
          height: height,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      },
    );
  }

  static Future<ImageProvider?> _resolve(String path) async {
    if (path.startsWith('content://')) {
      try {
        final bytes = await readPublicDocumentBytes(path);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (_) {
        return null;
      }
    }
    if (p.isAbsolute(path)) {
      final file = File(path);
      if (await file.exists()) return FileImage(file);
    }
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, path));
    if (await file.exists()) return FileImage(file);
    try {
      final bytes = await readPublicDocumentBytes(path);
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }
}
