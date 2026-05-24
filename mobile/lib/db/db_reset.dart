import '../prefs/app_preferences.dart';

import 'db_reset_io.dart' if (dart.library.html) 'db_reset_web.dart' as impl;

/// Development-only wipe of local app data (platform-specific implementation).
class DbReset {
  const DbReset._();

  /// Deletes the local database and housing draft mirrors.
  ///
  /// * **Native:** SQLite files under the app documents directory.
  /// * **Web:** Drift WASM storage (OPFS) plus `localStorage` housing mirrors.
  ///
  /// Call [HandshakeOrchestrator.releaseLocalDatabaseConnectionForDevReset]
  /// before this, then fully restart the app (on web: hard reload the page).
  static Future<void> deleteLocalDbFiles({AppPreferences? prefs}) =>
      impl.deleteLocalDbFiles(prefs: prefs);
}
