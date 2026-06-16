import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';

/// Updates every roster row linked to [contactId] after a contact profile change.
Future<void> syncParticipantRowsForContactProfile({
  required AppDatabase db,
  required String contactId,
  required String displayName,
  required String avatarId,
}) async {
  final participants = await db.listParticipants();
  for (final participant in participants) {
    if (participant.contactId != contactId) continue;
    await (db.update(db.participants)..where((t) => t.id.equals(participant.id)))
        .write(
      ParticipantsCompanion(
        displayName: drift.Value(displayName),
        avatarId: drift.Value(avatarId),
      ),
    );
  }
}

/// Updates every local `:self` roster row when the user changes their profile.
Future<void> syncSelfParticipantRowsForProfile({
  required AppDatabase db,
  required String displayName,
  required String avatarId,
}) async {
  final participants = await db.listParticipants();
  for (final participant in participants) {
    if (!participant.id.endsWith(':self')) continue;
    await (db.update(db.participants)..where((t) => t.id.equals(participant.id)))
        .write(
      ParticipantsCompanion(
        displayName: drift.Value(displayName),
        avatarId: drift.Value(avatarId),
      ),
    );
  }
}
