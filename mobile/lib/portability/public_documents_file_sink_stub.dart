import 'dart:io';

/// Web / test stub — proofs use data URLs on web.
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
  throw UnsupportedError('public documents IO unavailable on this platform');
}

Future<PublicDocumentWriteResult> writePublicDocumentBytes({
  required String relativeSubDir,
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('public documents IO unavailable on this platform');
}

Future<List<int>> readPublicDocumentBytes(String storageKey) async {
  throw UnsupportedError('public documents IO unavailable on this platform');
}

Future<void> deletePublicDocument(String storageKey) async {}

Future<bool> publicDocumentExists(String storageKey) async => false;

Future<List<String>> listPublicDocumentFileNames({
  required String relativeSubDir,
}) async =>
    const [];

Future<Directory> resolvePublicDocumentSubDir(String relativeSubDir) async {
  throw UnsupportedError('public documents IO unavailable on this platform');
}

Future<PublicDocumentWriteResult> renamePublicDocument({
  required String fromStorageKey,
  required String relativeSubDir,
  required String toFileName,
  required String mimeType,
}) async {
  throw UnsupportedError('public documents IO unavailable on this platform');
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
