import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../housing/realized_expense/proof_attachment_export.dart';

/// Loads proof bytes (file path or Android content URI) for image preview.
ImageProvider<Object>? localFileImageProvider(String filePath) {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty || trimmed.startsWith('data:')) return null;
  return _ProofBytesImageProvider(storageKey: trimmed);
}

class _ProofBytesImageProvider extends ImageProvider<_ProofBytesImageProvider> {
  const _ProofBytesImageProvider({required this.storageKey});

  final String storageKey;

  @override
  Future<_ProofBytesImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ProofBytesImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: 1,
    );
  }

  Future<ui.Codec> _loadCodec(
    _ProofBytesImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await loadProofImageBytes(key.storageKey);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('proof image unavailable: ${key.storageKey}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is _ProofBytesImageProvider && other.storageKey == storageKey;
  }

  @override
  int get hashCode => storageKey.hashCode;
}
