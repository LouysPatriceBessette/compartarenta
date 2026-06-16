import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import 'proposals/housing_proposal_transport_service.dart';

/// Reconciles plan-mediated peer identity when the same public key arrives with
/// a different display name (rename/proposal race during missing-contact flow).
Future<void> reconcilePlanMediatedPeerIdentity({
  required AppDatabase db,
  required String peerPublicMaterialB64,
  required String displayName,
  required String avatarId,
  String? planId,
  String? participantId,
}) async {
  final dn = displayName.trim();
  final av = avatarId.trim();
  if (peerPublicMaterialB64.isEmpty || dn.isEmpty) return;

  final establishmentRows = <PlanPeerEstablishment>[];
  if (planId != null && planId.isNotEmpty) {
    establishmentRows.addAll(
      await db.listPlanPeerEstablishmentsForPlan(planId),
    );
  } else {
    establishmentRows.addAll(
      await (db.select(db.planPeerEstablishments)).get(),
    );
  }

  final matchedEstablishments = establishmentRows
      .where((row) => row.peerPublicMaterialB64 == peerPublicMaterialB64)
      .toList();
  if (matchedEstablishments.isEmpty && participantId == null) return;

  final participantIds = <String>{
    if (participantId != null && participantId.isNotEmpty) participantId,
    for (final row in matchedEstablishments) row.participantId,
  };

  final now = DateTime.now().toUtc();
  for (final row in matchedEstablishments) {
    if (_sameIdentity(row.peerDisplayName, row.peerAvatarId, dn, av)) {
      continue;
    }
    await (db.update(db.planPeerEstablishments)..where((t) => t.id.equals(row.id)))
        .write(
      PlanPeerEstablishmentsCompanion(
        peerDisplayName: drift.Value(dn),
        peerAvatarId: drift.Value(av.isEmpty ? row.peerAvatarId : av),
        inboundRequesterDisplayName: drift.Value(
          row.inboundPendingAt != null ? dn : row.inboundRequesterDisplayName,
        ),
        inboundRequesterAvatarId: drift.Value(
          row.inboundPendingAt != null
              ? (av.isEmpty ? row.inboundRequesterAvatarId : av)
              : row.inboundRequesterAvatarId,
        ),
        updatedAt: drift.Value(now),
      ),
    );
  }

  for (final pid in participantIds) {
    final participant = await (db.select(db.participants)
          ..where((t) => t.id.equals(pid)))
        .getSingleOrNull();
    if (participant == null) continue;
    if (_sameIdentity(participant.displayName, participant.avatarId, dn, av)) {
      continue;
    }
    await (db.update(db.participants)..where((t) => t.id.equals(pid))).write(
      ParticipantsCompanion(
        displayName: drift.Value(dn),
        avatarId: drift.Value(av.isEmpty ? participant.avatarId : av),
      ),
    );

    final planIdForParticipant = pid.contains(':')
        ? pid.substring(0, pid.lastIndexOf(':'))
        : null;
    if (planIdForParticipant != null) {
      await _updateParticipantSnapshotsForPeerKey(
        db: db,
        planId: planIdForParticipant,
        peerPublicMaterialB64: peerPublicMaterialB64,
        displayName: dn,
        avatarId: av.isEmpty ? participant.avatarId : av,
      );
    }
  }

  final contacts = await ContactsRepository(db).list();
  for (final contact in contacts) {
    if (contact.peerPublicMaterial != peerPublicMaterialB64) continue;
    if (_sameIdentity(contact.displayName, contact.avatarId, dn, av)) {
      continue;
    }
    await ContactsRepository(db).rename(
      id: contact.id,
      displayName: dn,
      avatarId: av.isEmpty ? contact.avatarId : av,
    );
  }
}

bool _sameIdentity(
  String storedName,
  String storedAvatar,
  String newName,
  String newAvatar,
) {
  final nameMatches =
      storedName.trim().toLowerCase() == newName.trim().toLowerCase();
  if (!nameMatches) return false;
  if (newAvatar.trim().isEmpty) return true;
  return storedAvatar.trim() == newAvatar.trim();
}

Future<void> _updateParticipantSnapshotsForPeerKey({
  required AppDatabase db,
  required String planId,
  required String peerPublicMaterialB64,
  required String displayName,
  required String avatarId,
}) async {
  final transport = HousingProposalTransportService(db);
  final packages = await transport.proposalPackagesForPlan(planId);
  final revisionIds = <String>{};
  for (final pkg in packages) {
    final pending = pkg.pendingRevisionId;
    final active = pkg.activeRevisionId;
    if (pending != null && pending.isNotEmpty) revisionIds.add(pending);
    if (active != null && active.isNotEmpty) revisionIds.add(active);
  }

  for (final revisionId in revisionIds) {
    await transport.updateRevisionPayload(
      revisionId: revisionId,
      mutate: (payload) {
        final raw = payload['participantSnapshots'];
        if (raw is! List) return;
        for (final item in raw) {
          if (item is! Map) continue;
          if (item['peerPublicMaterialB64'] != peerPublicMaterialB64) continue;
          item['displayName'] = displayName;
          if (avatarId.isNotEmpty) {
            item['avatarId'] = avatarId;
          }
        }
      },
    );
  }
}

/// Returns true when [incomingName] differs from [storedName] (case-insensitive).
bool planMediatedPeerNameMismatch({
  required String storedName,
  required String incomingName,
}) {
  final stored = storedName.trim().toLowerCase();
  final incoming = incomingName.trim().toLowerCase();
  if (stored.isEmpty || incoming.isEmpty) return false;
  return stored != incoming;
}
