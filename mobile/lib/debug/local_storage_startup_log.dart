import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';
import '../screens/housing/housing_module_entry_screen.dart';
import 'local_storage_startup_log_platform.dart' as platform_hints;
import 'web_dev_db_snapshot.dart';
import 'web_dev_host_session.dart' as host_session;

/// Debug-only snapshot of local persistence (Drift + prefs).
///
/// [logLocalStorageStartupDiagnostics] runs once at bootstrap.
/// [logLocalStorageCheckpoint] runs after milestones (onboarding, contact, …).
Future<void> logLocalStorageStartupDiagnostics(AppDatabase db) async {
  await logLocalStorageCheckpoint(db, 'startup');
}

Future<void> logLocalStorageCheckpoint(AppDatabase db, String reason) async {
  if (!kDebugMode) return;

  try {
    final prefs = await AppPreferences.load();
    final contacts = await db.select(db.contacts).get();
    final connected = contacts.where((c) => c.kind == 'connected').length;
    final plans = await db.select(db.plans).get();
    final housingPlans = await housingPlansWithSelfParticipant(db);
    final packages = await db.select(db.proposalPackages).get();
    final activePackages = packages
        .where((p) => p.activeRevisionId != null)
        .length;
    final pendingPackages = packages
        .where((p) => p.pendingRevisionId != null)
        .length;
    final handshakes = await db.select(db.pendingHandshakes).get();
    final tableCounts = await countDevHostDriftTables(db);

    debugPrint(
      'local_storage_checkpoint: reason=$reason '
      'platform=${kIsWeb ? 'web' : 'native'} '
      'onboardingComplete=${prefs.onboardingComplete} '
      'onboardingStep=${prefs.onboardingStep ?? '-'} '
      'contacts=${contacts.length} connected=$connected '
      'plans=${plans.length} '
      'housingWithSelf=${housingPlans.length} '
      'proposalPackages=${packages.length} '
      'activePackages=$activePackages '
      'pendingPackages=$pendingPackages '
      'pendingHandshakes=${handshakes.length} '
      'tables=$tableCounts',
    );
    if (kIsWeb) {
      await platform_hints.logWebLocalStorageKeyCount(reason: reason);
      if (reason == 'onboarding-complete') {
        await host_session.saveDevHostSessionNow(db);
      }
    }
    if (kIsWeb && reason == 'startup') {
      await platform_hints.logExtraWebPersistenceHints();
      final userVersion = await db
          .customSelect('PRAGMA user_version')
          .getSingleOrNull();
      final userVer = userVersion?.data.values.first;
      debugPrint(
        'local_storage_startup: sqliteUserVersion=$userVer '
        '(wasm file may exist while SQL tables are still empty until first save)',
      );
    }
  } catch (error, stack) {
    debugPrint(
      'local_storage_checkpoint: reason=$reason failed: $error\n$stack',
    );
  }
}
