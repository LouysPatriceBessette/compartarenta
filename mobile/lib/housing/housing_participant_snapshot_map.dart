import '../db/app_database.dart';
import 'realized_expense/realized_expense_participants.dart';

/// Maps sender-local participant ids to this device's roster ids using
/// relay participant snapshots (contactId, then displayName).
Future<Map<String, String>> mapSourceParticipantIdsFromSnapshots({
  required AppDatabase db,
  required String planId,
  required Object? snapshots,
}) async {
  final out = <String, String>{};
  if (snapshots is! List) return out;

  final roster = await participantsForPlan(db, planId);
  for (final raw in snapshots) {
    if (raw is! Map) continue;
    final sourceId = raw['id'] as String? ?? '';
    if (sourceId.isEmpty) continue;

    final contactId = raw['contactId'] as String?;
    if (contactId != null && contactId.isNotEmpty) {
      for (final p in roster) {
        if (p.contactId == contactId) {
          out[sourceId] = p.id;
          break;
        }
      }
    }

    if (out.containsKey(sourceId)) continue;
    final name = (raw['displayName'] as String? ?? '').trim().toLowerCase();
    if (name.isEmpty) continue;
    for (final p in roster) {
      if (p.displayName.trim().toLowerCase() == name) {
        out[sourceId] = p.id;
        break;
      }
    }
  }
  return out;
}

Future<String?> localParticipantIdForContact({
  required AppDatabase db,
  required String planId,
  required String contactId,
}) async {
  final roster = await participantsForPlan(db, planId);
  for (final p in roster) {
    if (p.contactId == contactId) return p.id;
  }
  return null;
}

/// Maps a sender-local participant id from steady-state JSON to this roster.
///
/// Never reuses [sourceParticipantId] when it ends with `:self`: on the receiver,
/// that slot is always *this device*, not the sender's self row.
Future<String?> resolveImportedParticipantId({
  required AppDatabase db,
  required String planId,
  required String sourceParticipantId,
  required Map<String, String> sourceToLocal,
  String? senderContactId,
}) async {
  if (sourceParticipantId.isEmpty) return null;

  final mapped = sourceToLocal[sourceParticipantId];
  if (mapped != null && mapped.isNotEmpty) return mapped;

  if (sourceParticipantId.endsWith(':self')) {
    if (senderContactId == null || senderContactId.isEmpty) return null;
    return localParticipantIdForContact(
      db: db,
      planId: planId,
      contactId: senderContactId,
    );
  }

  // Peer slots (`:p1`, `:p2`, …) are per-device; never reuse the raw source id.
  return null;
}
