import '../../db/app_database.dart';

/// Local user's participant row for an active housing plan.
String selfParticipantIdForPlan(String planId) => '$planId:self';

/// Housing roster participants for [planId] (`:self` and `:p*` slots).
Future<List<Participant>> participantsForPlan(
  AppDatabase db,
  String planId,
) async {
  final rows = await db.listParticipants();
  return rows
      .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
      .toList(growable: false);
}

String displayNameForParticipant(String id, List<Participant> roster) {
  for (final p in roster) {
    if (p.id == id) return p.displayName.trim().isEmpty ? id : p.displayName;
  }
  return id;
}
