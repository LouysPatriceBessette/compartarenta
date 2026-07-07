import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File written under app documents for multi-device QA orchestrators to pull
/// via `adb run-as … cat app_flutter/…`.
const kQaHandshakeCodeExportFileName = 'compartarenta_qa_handshake_code.txt';

/// Persists the invitation short code for shell/Maestro coordination.
Future<void> qaExportHandshakeInvitationCode(String shortCode) async {
  if (!kDebugMode || kIsWeb) return;
  final trimmed = shortCode.trim();
  if (trimmed.isEmpty) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$kQaHandshakeCodeExportFileName');
    await file.writeAsString(trimmed);
    debugPrint('qa handshake export: wrote ${trimmed.length} chars');
  } catch (e) {
    debugPrint('qa handshake export: failed: $e');
  }
}

/// Clears any prior exported code before a new multi-device run.
Future<void> qaClearExportedHandshakeInvitationCode() async {
  if (!kDebugMode || kIsWeb) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$kQaHandshakeCodeExportFileName');
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    debugPrint('qa handshake export: clear failed: $e');
  }
}
