// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';

// ignore: deprecated_member_use
import 'dart:html' as html;

import '../db/app_database.dart';

/// Flushes Drift OPFS when the browser tab or window is hidden.
void installWebStorageFlushOnPageHide() {
  void flush() {
    try {
      unawaited(AppDatabase.processScope.syncWebStorageToDisk());
    } on StateError {
      // [AppDatabase.processScope] not bound yet (tests).
    }
  }

  html.window.onPageHide.listen((_) => flush());
  html.document.onVisibilityChange.listen((_) {
    if (html.document.hidden ?? false) {
      flush();
    }
  });
}
