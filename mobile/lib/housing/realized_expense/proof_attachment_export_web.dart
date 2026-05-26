// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

Future<bool> exportStoredProofCopy({
  required String displayFileName,
  required String filePath,
}) async {
  final trimmedPath = filePath.trim();
  if (trimmedPath.isEmpty || !trimmedPath.startsWith('data:')) return false;
  final anchor = html.AnchorElement(href: trimmedPath)
    ..download = displayFileName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
