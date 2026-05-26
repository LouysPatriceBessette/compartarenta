import 'package:flutter/widgets.dart';

ImageProvider<Object>? localFileImageProvider(String filePath) {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('data:')) return null;
  return NetworkImage(trimmed);
}
