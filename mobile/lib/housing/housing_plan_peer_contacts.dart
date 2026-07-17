import '../contacts/contact_display.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import 'plan_peer_establishment_service.dart';
import 'participation/housing_participation_membership_service.dart';
import 'realized_expense/realized_expense_participants.dart';

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
  Contact? uniqueAvatarMatch;
  for (final c in contacts) {
    if (!isRelayReachableContact(c)) continue;
    final nameMatches =
        name.isNotEmpty &&
        c.effectiveDisplayName.trim().toLowerCase() == name;
    if (nameMatches) return c;
    final avatarMatches = avatar.isNotEmpty && c.avatarId == avatar;
    if (avatarMatches) {
      if (uniqueAvatarMatch != null) {
        // Two peers share this avatar — do not guess.
        return null;
      }
      uniqueAvatarMatch = c;
    }
  }
  return uniqueAvatarMatch;
}

/// Relay contacts that should receive a housing proposal / response for one
/// roster slot.
///
/// When [selectedContact] is relay-reachable, returns only that contact.
/// Avatar-only expansion to every peer with the same icon is forbidden: it
/// delivers the same [Participant.id] as `targetParticipantId` to multiple
/// devices (sandbox avatar collisions → one invitee stays pending).
List<Contact> housingProposalDeliveryTargets({
  required Participant participant,
  required Contact? selectedContact,
  required List<Contact> relayReachableContacts,
}) {
  final targets = <Contact>[];
  final seenPeerMaterial = <String>{};

  void add(Contact? contact) {
    if (contact == null) return;
    if (contact.id.startsWith('contact:local:')) return;
    final peer = contact.peerPublicMaterial;
    if (peer == null || peer.isEmpty || !seenPeerMaterial.add(peer)) return;
    targets.add(contact);
  }

  if (selectedContact != null && isRelayReachableContact(selectedContact)) {
    add(selectedContact);
    return targets;
  }

  final participantName = participant.displayName.trim().toLowerCase();
  final participantAvatar = participant.avatarId.trim();
  final nameMatches = <Contact>[];
  final avatarMatches = <Contact>[];
  for (final contact in relayReachableContacts) {
    if (!isRelayReachableContact(contact)) continue;
    final nameOk =
        participantName.isNotEmpty &&
        contact.effectiveDisplayName.trim().toLowerCase() == participantName;
    final avatarOk =
        participantAvatar.isNotEmpty &&
        contact.avatarId == participantAvatar;
    if (nameOk) nameMatches.add(contact);
    if (avatarOk) avatarMatches.add(contact);
  }

  if (nameMatches.isNotEmpty) {
    for (final contact in nameMatches) {
      add(contact);
    }
    return targets;
  }

  if (avatarMatches.length == 1) {
    add(avatarMatches.single);
    return targets;
  }
  if (avatarMatches.length > 1) {
    // Ambiguous avatar collision — do not fan out one targetParticipantId.
    return targets;
  }

  // No bound contact / name / unique avatar: last-resort mesh delivery.
  if (relayReachableContacts.isNotEmpty) {
    for (final contact in relayReachableContacts) {
      add(contact);
    }
  }
  return targets;
}

/// Relay contacts for participation changes limited to active members.
///
/// Uses broadcast-to-all-reachable minus departed roster slots (reliable mesh
/// delivery) instead of per-participant contact resolution, which can fail
/// across devices when [Participant.contactId] is missing.
List<Contact> relayContactsExcludingDepartedPlanMembers({
  required List<Participant> roster,
  required Set<String> departedParticipantIds,
  required List<Contact> relayReachableContacts,
}) {
  final excludedPeerMaterial = <String>{};
  for (final participant in roster) {
    if (!departedParticipantIds.contains(participant.id)) continue;
    final contact = relayReachableContactForParticipant(
      participant,
      relayReachableContacts,
    );
    final peer = contact?.peerPublicMaterial;
    if (peer != null && peer.isNotEmpty) {
      excludedPeerMaterial.add(peer);
    }
  }
  return [
    for (final contact in relayReachableContacts)
      if (!excludedPeerMaterial.contains(contact.peerPublicMaterial)) contact,
  ];
}

/// Resolves relay targets limited to active plan members.
Future<List<Contact>> relayContactsForActivePlanMembers({
  required AppDatabase db,
  required String planId,
  required List<Contact> relayReachableContacts,
}) async {
  final membership = HousingParticipationMembershipService(db);
  final roster = await participantsForPlan(db, planId);
  final departedIds = <String>{};
  for (final participant in roster) {
    if (!await membership.isActiveMember(planId, participant.id)) {
      departedIds.add(participant.id);
    }
  }
  return relayContactsExcludingDepartedPlanMembers(
    roster: roster,
    departedParticipantIds: departedIds,
    relayReachableContacts: relayReachableContacts,
  );
}

/// Maps a relay [senderContactId] to a housing roster participant on this device.
///
/// Uses the same rules as [relayReachableContactForParticipant]: participant
/// [Participant.contactId], then display name / avatar match.
Future<String?> localParticipantIdForSenderContact({
  required AppDatabase db,
  required String planId,
  required String senderContactId,
}) async {
  if (senderContactId.isEmpty) return null;

  final roster = await participantsForPlan(db, planId);
  for (final p in roster) {
    if (p.contactId == senderContactId) return p.id;
  }

  final contacts = await db.listContacts();
  Contact? sender;
  for (final c in contacts) {
    if (c.id == senderContactId) {
      sender = c;
      break;
    }
  }
  if (sender == null) return null;

  for (final p in roster) {
    if (relayReachableContactForParticipant(p, [sender]) != null) {
      return p.id;
    }
  }
  return null;
}

/// One co-participant on a housing plan and whether they are a connected contact
/// on this device.
class PlanPeerContactRow {
  const PlanPeerContactRow({
    required this.participant,
    required this.isConnected,
    this.outboundPending = false,
    this.refusedAt,
    this.inboundPending = false,
    this.inboundRequesterDisplayName,
    this.establishmentId,
  });

  final Participant participant;
  final bool isConnected;
  final bool outboundPending;
  final DateTime? refusedAt;
  final bool inboundPending;
  final String? inboundRequesterDisplayName;
  final String? establishmentId;
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
  final establishmentRows =
      await PlanPeerEstablishmentService(db).listForPlan(planId);
  final establishmentByParticipant = {
    for (final row in establishmentRows) row.participantId: row,
  };
  final roster =
      (await db.listParticipants())
          .where(
            (p) => p.id.startsWith('$planId:p'),
          )
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
  final rows = <PlanPeerContactRow>[];
  for (final p in roster) {
    final est = establishmentByParticipant[p.id];
    rows.add(
      PlanPeerContactRow(
        participant: p,
        isConnected:
            relayReachableContactForParticipant(p, reachable) != null,
        outboundPending: est?.outboundPendingAt != null,
        refusedAt: est?.refusedAt,
        inboundPending: est?.inboundPendingAt != null,
        inboundRequesterDisplayName: est?.inboundRequesterDisplayName,
        establishmentId: est?.id,
      ),
    );
  }
  return rows;
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
