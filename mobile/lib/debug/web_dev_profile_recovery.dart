import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';

/// When SharedPreferences were wiped but Drift still has housing data, copy the
/// self participant identity into prefs so Settings → Profile is not empty.
Future<bool> reconcileDevProfileFromDriftIfNeeded(
  AppDatabase db,
  AppPreferences prefs,
) async {
  if (!kDebugMode) return false;
  if (prefs.hasProfile) return false;

  final participants = await db.select(db.participants).get();
  Participant? self;
  for (final row in participants) {
    if (!row.id.endsWith(':self')) continue;
    if (row.displayName.trim().isEmpty) continue;
    self = row;
    break;
  }
  if (self == null) return false;

  final avatarId = self.avatarId.trim().isEmpty ? 'mdi:0' : self.avatarId.trim();
  await prefs.setProfileIdentity(displayName: self.displayName.trim(), avatarId: avatarId);
  debugPrint(
    'web_dev_profile_recovery: restored profile from ${self.id} '
    'displayName=${self.displayName.trim()} avatarId=$avatarId',
  );
  return true;
}
