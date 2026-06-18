import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local map of plan participant id → entitlement installation id.
///
/// Populated from proposal snapshots and the local installation store.
class PlanParticipantInstallationRegistry {
  PlanParticipantInstallationRegistry(this._prefs);

  final SharedPreferences _prefs;

  static Future<PlanParticipantInstallationRegistry> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PlanParticipantInstallationRegistry(prefs);
  }

  static String _key(String planId) =>
      'entitlement.participant_installations.$planId';

  Future<void> setInstallationId({
    required String planId,
    required String participantId,
    required String installationId,
  }) async {
    if (installationId.isEmpty) return;
    final map = _readMap(planId);
    if (map[participantId] == installationId) return;
    map[participantId] = installationId;
    await _prefs.setString(_key(planId), jsonEncode(map));
  }

  String? installationIdFor({
    required String planId,
    required String participantId,
  }) {
    return _readMap(planId)[participantId];
  }

  /// Returns installation ids in roster order when every [participantIds] entry
  /// is mapped; otherwise null.
  List<String>? rosterInstallationIds({
    required String planId,
    required List<String> participantIds,
  }) {
    if (participantIds.length < 2) return null;
    final map = _readMap(planId);
    final out = <String>[];
    for (final pid in participantIds) {
      final inst = map[pid];
      if (inst == null || inst.isEmpty) return null;
      out.add(inst);
    }
    return out;
  }

  Map<String, String> _readMap(String planId) {
    final raw = _prefs.getString(_key(planId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          e.key: (e.value as String?) ?? '',
      }..removeWhere((_, v) => v.isEmpty);
    } catch (_) {
      return {};
    }
  }
}
