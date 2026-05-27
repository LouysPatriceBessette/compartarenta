import '../../db/app_database.dart';

/// Local user's participant row for an active housing plan.
String selfParticipantIdForPlan(String planId) => '$planId:self';

/// Stable roster order for housing participants in [planId].
int rosterOrderForPlanParticipantId(String planId, String participantId) {
  if (participantId == selfParticipantIdForPlan(planId)) {
    return -1;
  }
  final peerPrefix = '$planId:p';
  if (!participantId.startsWith(peerPrefix)) {
    return 1 << 20;
  }
  final tail = participantId.substring(peerPrefix.length);
  return int.tryParse(tail) ?? (1 << 20);
}

/// Returns [participants] sorted in stable housing roster order.
List<Participant> sortParticipantsForPlan(
  String planId,
  Iterable<Participant> participants,
) {
  final out = participants.toList(growable: false);
  out.sort(
    (a, b) => rosterOrderForPlanParticipantId(
      planId,
      a.id,
    ).compareTo(rosterOrderForPlanParticipantId(planId, b.id)),
  );
  return out;
}

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
