import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';

/// After Ctrl+C, Drift OPFS often survives while shared_preferences does not.
///
/// Avoids sending the user back through onboarding when contacts/plans remain.
Future<void> reconcileDevOnboardingIfNeeded(AppDatabase db) async {
  if (!kDebugMode || !kIsWeb) return;

  final prefs = await AppPreferences.load();
  if (prefs.onboardingComplete) return;

  final contacts = await db.select(db.contacts).get();
  final hasConnected = contacts.any((c) => c.kind == 'connected');
  final plans = await db.select(db.plans).get();
  if (!hasConnected && plans.isEmpty) return;

  await prefs.completeOnboarding();
  debugPrint(
    'web_dev_onboarding_reconcile: onboardingComplete=true '
    '(Drift had contacts=${contacts.length} plans=${plans.length}, prefs were false)',
  );
}
