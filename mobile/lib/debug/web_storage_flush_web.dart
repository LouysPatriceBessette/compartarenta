// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';

import 'package:flutter/foundation.dart';

// ignore: deprecated_member_use
import 'dart:html' as html;

import '../db/app_database.dart';
import '../relay/handshake_orchestrator.dart';
import 'web_dev_host_session.dart';

/// Flushes Drift OPFS when the browser tab or window is hidden.
void installWebStorageFlushOnPageHide() {
  Future<void> flush() async {
    try {
      final db = AppDatabase.processScope;
      await db.syncWebStorageToDisk();
      await flushDevHostSessionSave(db);
    } on StateError {
      // [AppDatabase.processScope] not bound yet (tests).
    }
  }

  html.window.onPageHide.listen((_) {
    unawaited(flush());
  });
  html.window.onBeforeUnload.listen((_) {
    unawaited(flush());
  });
  html.document.onVisibilityChange.listen((_) {
    final hidden = html.document.hidden ?? false;
    if (hidden) {
      unawaited(flush());
      return;
    }
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    unawaited(
      orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('steady inbox poll on tab visible failed: $e\n$st');
      }),
    );
  });
}
