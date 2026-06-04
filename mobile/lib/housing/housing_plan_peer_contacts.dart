import '../contacts/contact_display.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';

/// Route extra for [/contacts/redeem] when housing sends the user to add a
/// co-participant who is not yet a relay-reachable contact.
class HousingMissingContactRedeemArgs {
  const HousingMissingContactRedeemArgs({
    required this.displayName,
    this.avatarId,
  });

  final String displayName;
  final String? avatarId;
}

/// Whether this contact row can receive steady-state relay envelopes.
bool isRelayReachableContact(Contact contact) {
  if (contact.id.startsWith('contact:local:')) return false;
  final peer = contact.peerPublicMaterial;
  return peer != null && peer.isNotEmpty;
}

/// Resolves a roster participant to a connected contact on this device, if any.
Contact? relayReachableContactForParticipant(
  Participant participant,
  List<Contact> contacts,
) {
  final contactId = participant.contactId;
  if (contactId != null && contactId.isNotEmpty) {
    for (final c in contacts) {
      if (c.id == contactId && isRelayReachableContact(c)) return c;
    }
  }
  final name = participant.displayName.trim().toLowerCase();
  final avatar = participant.avatarId.trim();
  for (final c in contacts) {
    if (!isRelayReachableContact(c)) continue;
    final nameMatches =
        name.isNotEmpty &&
        c.effectiveDisplayName.trim().toLowerCase() == name;
    final avatarMatches = avatar.isNotEmpty && c.avatarId == avatar;
    if (nameMatches || avatarMatches) return c;
  }
  return null;
}

/// One co-participant on a housing plan and whether they are a connected contact
/// on this device.
class PlanPeerContactRow {
  const PlanPeerContactRow({
    required this.participant,
    required this.isConnected,
  });

  final Participant participant;
  final bool isConnected;
}

/// All co-participants on [planId] except `:self`, with relay contact status.
///
/// Sorted by [Participant.displayName].
Future<List<PlanPeerContactRow>> listPlanPeerContactRows({
  required AppDatabase db,
  required String planId,
}) async {
  final contacts = await ContactsRepository(db).list();
  final reachable = contacts.where(isRelayReachableContact).toList();
  final roster =
      (await db.listParticipants())
          .where(
            (p) => p.id.startsWith('$planId:p'),
          )
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
  return [
    for (final p in roster)
      PlanPeerContactRow(
        participant: p,
        isConnected:
            relayReachableContactForParticipant(p, reachable) != null,
      ),
  ];
}

/// Co-participants on [planId] who are not yet relay-reachable contacts locally.
///
/// The plan author (roster `:self`) is excluded. Sorted by display name.
Future<List<Participant>> listMissingPlanPeerContacts({
  required AppDatabase db,
  required String planId,
}) async {
  final contacts = await ContactsRepository(db).list();
  final reachable = contacts.where(isRelayReachableContact).toList();
  final roster =
      (await db.listParticipants())
          .where(
            (p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'),
          )
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
  final missing = <Participant>[];
  for (final p in roster) {
    if (p.id == '$planId:self') continue;
    if (relayReachableContactForParticipant(p, reachable) == null) {
      missing.add(p);
    }
  }
  return missing;
}
