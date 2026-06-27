import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('com.compartarenta/public_documents');

class PublicDocumentWriteResult {
  const PublicDocumentWriteResult({
    required this.storageKey,
    required this.relativePath,
    required this.fileName,
  });

  final String storageKey;
  final String relativePath;
  final String fileName;
}

Future<PublicDocumentWriteResult> writePublicDocumentText({
  required String relativeSubDir,
  required String fileName,
  required String content,
  String mimeType = 'application/json',
}) async {
  if (Platform.isAndroid) {
    final relativePath = await _channel.invokeMethod<String>(
      'writeTextFile',
      <String, Object>{
        'subDir': relativeSubDir,
        'fileName': fileName,
        'content': content,
        'mimeType': mimeType,
      },
    );
    final storageKey = await _resolveStorageKeyAfterWrite(
      relativeSubDir: relativeSubDir,
      fileName: fileName,
      relativePath: relativePath,
    );
    return PublicDocumentWriteResult(
      storageKey: storageKey,
      relativePath: relativePath ?? '$relativeSubDir/$fileName',
      fileName: fileName,
    );
  }

  final dir = await _desktopDocumentsSubDir(relativeSubDir);
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(content, flush: true);
  return PublicDocumentWriteResult(
    storageKey: file.path,
    relativePath: p.join(relativeSubDir, fileName),
    fileName: fileName,
  );
}

Future<PublicDocumentWriteResult> writePublicDocumentBytes({
  required String relativeSubDir,
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  if (Platform.isAndroid) {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'writeBytesFile',
      <String, Object>{
        'subDir': relativeSubDir,
        'fileName': fileName,
        'bytes': Uint8List.fromList(bytes),
        'mimeType': mimeType,
      },
    );
    final map = Map<String, dynamic>.from(result ?? const {});
    final storageKey = map['storageKey'] as String? ?? '';
    final relativePath =
        map['relativePath'] as String? ?? p.join(relativeSubDir, fileName);
    if (storageKey.isEmpty) {
      throw StateError('writeBytesFile returned empty storageKey');
    }
    return PublicDocumentWriteResult(
      storageKey: storageKey,
      relativePath: relativePath,
      fileName: fileName,
    );
  }

  final dir = await _desktopDocumentsSubDir(relativeSubDir);
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  return PublicDocumentWriteResult(
    storageKey: file.path,
    relativePath: p.join(relativeSubDir, fileName),
    fileName: fileName,
  );
}

Future<List<int>> readPublicDocumentBytes(String storageKey) async {
  if (storageKey.startsWith('content://')) {
    if (!Platform.isAndroid) {
      throw StateError('content URI on non-Android: $storageKey');
    }
    final bytes = await _channel.invokeMethod<Uint8List>(
      'readBytesFile',
      <String, String>{'storageKey': storageKey},
    );
    if (bytes == null) {
      throw StateError('readBytesFile returned null for $storageKey');
    }
    return bytes;
  }
  return File(storageKey).readAsBytes();
}

Future<void> deletePublicDocument(String storageKey) async {
  if (storageKey.isEmpty) return;
  if (storageKey.startsWith('content://')) {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>(
        'deleteFile',
        <String, String>{'storageKey': storageKey},
      );
    }
    return;
  }
  final file = File(storageKey);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<bool> publicDocumentExists(String storageKey) async {
  if (storageKey.isEmpty) return false;
  if (storageKey.startsWith('content://')) {
    if (!Platform.isAndroid) return false;
    final exists = await _channel.invokeMethod<bool>(
      'fileExists',
      <String, String>{'storageKey': storageKey},
    );
    return exists ?? false;
  }
  return File(storageKey).exists();
}

Future<List<String>> listPublicDocumentFileNames({
  required String relativeSubDir,
}) async {
  if (Platform.isAndroid) {
    final names = await _channel.invokeMethod<List<Object?>>(
      'listFileNames',
      <String, String>{'subDir': relativeSubDir},
    );
    return [
      for (final n in names ?? const [])
        if (n is String) n,
    ];
  }
  final dir = await _desktopDocumentsSubDir(relativeSubDir);
  if (!await dir.exists()) return const [];
  return [
    for (final entity in dir.listSync(followLinks: false))
      if (entity is File) p.basename(entity.path),
  ];
}

Future<Directory> resolvePublicDocumentSubDir(String relativeSubDir) {
  return _desktopDocumentsSubDir(relativeSubDir);
}

Future<PublicDocumentWriteResult> renamePublicDocument({
  required String fromStorageKey,
  required String relativeSubDir,
  required String toFileName,
  required String mimeType,
}) async {
  final bytes = await readPublicDocumentBytes(fromStorageKey);
  final written = await writePublicDocumentBytes(
    relativeSubDir: relativeSubDir,
    fileName: toFileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  await deletePublicDocument(fromStorageKey);
  return written;
}

Future<PublicDocumentWriteResult> copyPublicDocumentBytes({
  required List<int> bytes,
  required String relativeSubDir,
  required String fileName,
  required String mimeType,
}) {
  return writePublicDocumentBytes(
    relativeSubDir: relativeSubDir,
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}

Future<Directory> _desktopDocumentsSubDir(String relativeSubDir) async {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return Directory(p.join(home, 'Documents', relativeSubDir));
  }
  final base = await getApplicationDocumentsDirectory();
  return Directory(p.join(base.path, relativeSubDir));
}

Future<String> _resolveStorageKeyAfterWrite({
  required String relativeSubDir,
  required String fileName,
  required String? relativePath,
}) async {
  if (Platform.isAndroid) {
    final key = await _channel.invokeMethod<String>(
      'resolveStorageKey',
      <String, String>{
        'subDir': relativeSubDir,
        'fileName': fileName,
      },
    );
    if (key != null && key.isNotEmpty) return key;
  }
  final dir = await _desktopDocumentsSubDir(relativeSubDir);
  return p.join(dir.path, fileName);
}
