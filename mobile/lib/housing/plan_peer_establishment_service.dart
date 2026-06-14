import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import 'housing_plan_peer_contacts.dart';

/// Persists and queries plan-mediated peer contact establishment state
/// (watch list, outbound pending, inbound pending, refusal timestamps).
class PlanPeerEstablishmentService {
  PlanPeerEstablishmentService(this._db);

  final AppDatabase _db;

  /// Rebuilds watch-list rows from the latest revision payload for [planId].
  ///
  /// Removes rows for peers who became relay-reachable contacts. Adds or
  /// updates rows for missing peers that include `peerPublicMaterialB64`
  /// in `participantSnapshots`.
  Future<void> syncWatchListForPlan(String planId) async {
    final revision = await _latestRevisionPayload(planId);
    if (revision == null) return;

    final payload = jsonDecode(revision.payloadJson) as Map<String, dynamic>;
    final revisionId = revision.id;
    final proposerDisplayName = await _proposerDisplayName(planId, payload);
    final snapshots = _snapshotMap(payload);
    final contacts = await ContactsRepository(_db).list();
    final reachable = contacts.where(isRelayReachableContact).toList();

    final roster =
        (await _db.listParticipants())
            .where(
              (p) => p.id.startsWith('$planId:') && p.id != '$planId:self',
            )
            .toList();

    final now = DateTime.now().toUtc();
    final activePeerKeys = <String>{};

    for (final participant in roster) {
      if (relayReachableContactForParticipant(participant, reachable) !=
          null) {
        continue;
      }
      final snap = _snapshotForParticipant(
        participant: participant,
        snapshots: snapshots,
        payload: payload,
      );
      final peerB64 = _string(snap?['peerPublicMaterialB64']);
      if (peerB64.isEmpty) continue;

      activePeerKeys.add(peerB64);
      final rowId = '$planId:${participant.id.split(':').last}';
      final existing = await _db.getPlanPeerEstablishment(rowId);
      await _db.upsertPlanPeerEstablishment(
        PlanPeerEstablishmentsCompanion.insert(
          id: rowId,
          planId: planId,
          participantId: participant.id,
          peerPublicMaterialB64: peerB64,
          peerDisplayName: _string(
            snap?['displayName'],
            fallback: participant.displayName,
          ),
          peerAvatarId: _string(
            snap?['avatarId'],
            fallback: participant.avatarId,
          ),
          proposerDisplayName: proposerDisplayName,
          revisionId: drift.Value(revisionId),
          outboundPendingAt: drift.Value(existing?.outboundPendingAt),
          refusedAt: drift.Value(existing?.refusedAt),
          inboundPendingAt: drift.Value(existing?.inboundPendingAt),
          inboundRequesterDisplayName: drift.Value(
            existing?.inboundRequesterDisplayName,
          ),
          inboundRequesterAvatarId: drift.Value(
            existing?.inboundRequesterAvatarId,
          ),
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    final existingRows = await _db.listPlanPeerEstablishmentsForPlan(planId);
    for (final row in existingRows) {
      if (!activePeerKeys.contains(row.peerPublicMaterialB64)) {
        await _db.deletePlanPeerEstablishment(row.id);
      }
    }
  }

  Future<PlanPeerEstablishment?> rowForParticipant({
    required String planId,
    required String participantId,
  }) async {
    final tail = participantId.split(':').last;
    return _db.getPlanPeerEstablishment('$planId:$tail');
  }

  Future<void> markOutboundPending(String establishmentId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.planPeerEstablishments)
          ..where((t) => t.id.equals(establishmentId)))
        .write(
      PlanPeerEstablishmentsCompanion(
        outboundPendingAt: drift.Value(now),
        refusedAt: const drift.Value(null),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> markRefused(String establishmentId, DateTime refusedAt) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.planPeerEstablishments)
          ..where((t) => t.id.equals(establishmentId)))
        .write(
      PlanPeerEstablishmentsCompanion(
        outboundPendingAt: const drift.Value(null),
        refusedAt: drift.Value(refusedAt),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> markInboundPending({
    required String establishmentId,
    required String requesterDisplayName,
    required String requesterAvatarId,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.planPeerEstablishments)
          ..where((t) => t.id.equals(establishmentId)))
        .write(
      PlanPeerEstablishmentsCompanion(
        inboundPendingAt: drift.Value(now),
        inboundRequesterDisplayName: drift.Value(requesterDisplayName),
        inboundRequesterAvatarId: drift.Value(requesterAvatarId),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> clearInboundPending(String establishmentId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.planPeerEstablishments)
          ..where((t) => t.id.equals(establishmentId)))
        .write(
      PlanPeerEstablishmentsCompanion(
        inboundPendingAt: const drift.Value(null),
        inboundRequesterDisplayName: const drift.Value(null),
        inboundRequesterAvatarId: const drift.Value(null),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> clearOutboundPending(String establishmentId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.planPeerEstablishments)
          ..where((t) => t.id.equals(establishmentId)))
        .write(
      PlanPeerEstablishmentsCompanion(
        outboundPendingAt: const drift.Value(null),
        updatedAt: drift.Value(now),
      ),
    );
  }

  Future<void> removeRow(String establishmentId) async {
    await _db.deletePlanPeerEstablishment(establishmentId);
  }

  Future<List<PlanPeerEstablishment>> listForPlan(String planId) =>
      _db.listPlanPeerEstablishmentsForPlan(planId);

  Future<ProposalRevision?> _latestRevisionPayload(String planId) async {
    final pkg = await (_db.select(_db.proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .getSingleOrNull();
    if (pkg == null) return null;

    final revId = pkg.pendingRevisionId?.isNotEmpty == true
        ? pkg.pendingRevisionId!
        : pkg.activeRevisionId;
    if (revId == null || revId.isEmpty) return null;

    return (_db.select(_db.proposalRevisions)
          ..where((t) => t.id.equals(revId)))
        .getSingleOrNull();
  }

  Future<String> _proposerDisplayName(
    String planId,
    Map<String, dynamic> payload,
  ) async {
    final proposerSourceId = _string(payload['proposerParticipantId']);
    final self = await (_db.select(_db.participants)
          ..where((t) => t.id.equals('$planId:self')))
        .getSingleOrNull();
    if (self != null && proposerSourceId.endsWith(':self')) {
      return self.displayName;
    }
    final snapshots = _snapshotMap(payload);
    final snap = snapshots[proposerSourceId];
    if (snap != null) {
      return _string(snap['displayName'], fallback: proposerSourceId);
    }
    return proposerSourceId.isEmpty ? 'Unknown' : proposerSourceId;
  }

  Map<String, Map<String, dynamic>> _snapshotMap(
    Map<String, dynamic> payload,
  ) {
    final out = <String, Map<String, dynamic>>{};
    final raw = payload['participantSnapshots'];
    if (raw is! List) return out;
    for (final item in raw) {
      if (item is Map) {
        out[_string(item['id'])] = Map<String, dynamic>.from(item);
      }
    }
    return out;
  }

  Map<String, dynamic>? _snapshotForParticipant({
    required Participant participant,
    required Map<String, Map<String, dynamic>> snapshots,
    required Map<String, dynamic> payload,
  }) {
    final sourceIds = payload['participantSourceIds'];
    if (sourceIds is Map) {
      final sourceId = sourceIds[participant.id];
      if (sourceId != null) {
        final snap = snapshots[sourceId.toString()];
        if (snap != null) return snap;
      }
    }
    for (final entry in snapshots.entries) {
      final tail = entry.key.contains(':')
          ? entry.key.split(':').last
          : entry.key;
      if (participant.id.endsWith(':$tail')) return entry.value;
    }
    for (final entry in snapshots.entries) {
      final snap = entry.value;
      final name = _string(snap['displayName']).trim().toLowerCase();
      if (name.isNotEmpty &&
          name == participant.displayName.trim().toLowerCase()) {
        return snap;
      }
    }
    return null;
  }

  String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }
}
