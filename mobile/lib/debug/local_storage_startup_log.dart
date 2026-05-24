import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';
import '../screens/housing/housing_module_entry_screen.dart';

/// Debug-only snapshot of local persistence after [AppDatabase.warmUpStorage].
///
/// Correlate console output with "empty app" reports (web OPFS, prefs, contacts).
Future<void> logLocalStorageStartupDiagnostics(AppDatabase db) async {
  if (!kDebugMode) return;

  try {
    final prefs = await AppPreferences.load();
    final contacts = await db.select(db.contacts).get();
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

    debugPrint(
      'local_storage_startup: platform=${kIsWeb ? 'web' : 'native'} '
      'onboardingComplete=${prefs.onboardingComplete} '
      'onboardingStep=${prefs.onboardingStep ?? '-'} '
      'contacts=${contacts.length} '
      'plans=${plans.length} '
      'housingWithSelf=${housingPlans.length} '
      'proposalPackages=${packages.length} '
      'activePackages=$activePackages '
      'pendingPackages=$pendingPackages '
      'pendingHandshakes=${handshakes.length}',
    );
  } catch (error, stack) {
    debugPrint('local_storage_startup: failed to read diagnostics: $error\n$stack');
  }
}
