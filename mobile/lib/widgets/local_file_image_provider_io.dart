import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? localFileImageProvider(String filePath) {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty) return null;
  return FileImage(File(trimmed));
}
