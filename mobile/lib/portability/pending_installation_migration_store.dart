import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists pending installation migration after a successful local import.
class PendingInstallationMigrationStore {
  PendingInstallationMigrationStore(this._prefs);

  static const _key = 'device_data.pending_installation_migration.v1';

  final SharedPreferences _prefs;

  static Future<PendingInstallationMigrationStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PendingInstallationMigrationStore(prefs);
  }

  PendingInstallationMigration? read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PendingInstallationMigration(
        oldParticipantInstallationId:
            map['old_participant_installation_id'] as String,
        planId: map['plan_id'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PendingInstallationMigration pending) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'old_participant_installation_id':
            pending.oldParticipantInstallationId,
        'plan_id': pending.planId,
      }),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}

class PendingInstallationMigration {
  const PendingInstallationMigration({
    required this.oldParticipantInstallationId,
    required this.planId,
  });

  final String oldParticipantInstallationId;
  final String planId;
}
