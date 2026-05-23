import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../activity/relay_activity_log_service.dart';
import '../../db/app_database.dart';
import 'housing_proposal_revision_state.dart';
import 'plan_agreement_proposal_service.dart';

class ReceivedHousingProposalImport {
  const ReceivedHousingProposalImport({
    required this.planId,
    required this.revisionId,
  });

  final String planId;
  final String revisionId;
}

class HousingProposalArchive {
  const HousingProposalArchive({
    required this.planId,
    required this.revisionId,
    required this.title,
    required this.status,
    required this.invalidatedAt,
    required this.canFork,
    this.isDraft = false,
    this.isPending = false,
    this.pendingResponseCount = 0,
    this.participantCount = 0,
    this.editorPlanId,
    this.isExpired = false,
  });

  final String planId;
  final String revisionId;
  final String title;
  final ProposalResponseStatus status;
  final DateTime invalidatedAt;
  final bool canFork;
  final bool isDraft;
  final bool isPending;
  final int pendingResponseCount;
  final int participantCount;
  final String? editorPlanId;
  final bool isExpired;
}

class HousingProposalTransportService {
  HousingProposalTransportService(this._db);

  final AppDatabase _db;

  Future<String> exportProposalForParticipant({
    required String planId,
    required String revisionId,
    required String targetParticipantId,
  }) async {
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(revisionId);
    final participants = await _participantsForPlan(planId);
    final enriched = Map<String, Object?>.from(payload)
      ..['targetParticipantId'] = targetParticipantId
      ..['participantSnapshots'] = [
        for (final p in participants)
          {
            'id': p.id,
            'displayName': p.displayName,
            'avatarId': p.avatarId,
            if (p.contactId != null) 'contactId': p.contactId,
          },
      ];
    return jsonEncode(enriched);
  }

  Future<ReceivedHousingProposalImport> importReceivedProposal({
    required String proposalJson,
    required String targetParticipantId,
    required String senderContactId,
    required String senderDisplayName,
    required String senderAvatarId,
  }) async {
    final payload = jsonDecode(proposalJson) as Map<String, dynamic>;
    final sourcePackageId = _string(
      payload['packageId'],
      fallback: 'pkg:unknown',
    );
    final sourceRevisionId = _string(
      payload['revisionId'],
      fallback: 'rev:${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
    final receivedPlanId = 'received:${_token(sourcePackageId)}';
    final receivedPackageId = 'pkg:$receivedPlanId';
    final receivedRevisionId =
        'rev:$receivedPlanId:${_token(sourceRevisionId)}';
    final createdAt = _date(payload['createdAt']) ?? DateTime.now().toUtc();

    final sourceToLocalParticipant = _participantIdMap(
      payload: payload,
      targetParticipantId: targetParticipantId,
    );
    final importedPayload = _remapPayload(
      payload,
      receivedPlanId: receivedPlanId,
      sourceToLocalParticipant: sourceToLocalParticipant,
      receivedPackageId: receivedPackageId,
      receivedRevisionId: receivedRevisionId,
    );

    await _deleteReceivedPlanData(receivedPlanId);
    await _upsertPlan(receivedPlanId, payload, createdAt);
    await _upsertParticipants(
      receivedPlanId: receivedPlanId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      senderContactId: senderContactId,
      senderDisplayName: senderDisplayName,
      senderAvatarId: senderAvatarId,
      createdAt: createdAt,
    );
    await _upsertGroups(receivedPlanId, payload, createdAt);
    await _upsertLines(
      receivedPlanId,
      payload,
      createdAt,
      sourceToLocalParticipant: sourceToLocalParticipant,
    );
    await _upsertRatios(
      receivedPlanId: receivedPlanId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      createdAt: createdAt,
    );
    await _upsertAgreement(receivedPlanId, payload, createdAt);
    await _db
        .into(_db.proposalPackages)
        .insertOnConflictUpdate(
          ProposalPackagesCompanion.insert(
            id: receivedPackageId,
            planId: receivedPlanId,
            pendingRevisionId: drift.Value(receivedRevisionId),
            createdAt: createdAt,
          ),
        );
    await _db
        .into(_db.proposalRevisions)
        .insertOnConflictUpdate(
          ProposalRevisionsCompanion.insert(
            id: receivedRevisionId,
            packageId: receivedPackageId,
            contentHash: _string(
              payload['contentHash'],
              fallback: 'received:$receivedRevisionId',
            ),
            proposerParticipantId:
                '$receivedPlanId:${sourceToLocalParticipant[_string(payload['proposerParticipantId'])] ?? 'p0'}',
            payloadJson: jsonEncode(importedPayload),
            createdAt: createdAt,
          ),
        );
    await _upsertResponses(
      receivedPlanId: receivedPlanId,
      revisionId: receivedRevisionId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      createdAt: createdAt,
    );

    return ReceivedHousingProposalImport(
      planId: receivedPlanId,
      revisionId: receivedRevisionId,
    );
  }

  Future<String?> pendingRevisionIdForPlan(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    return pkg?.pendingRevisionId;
  }

  Future<bool> hasActiveRevision(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    return pkg?.activeRevisionId != null;
  }

  Future<String?> localParticipantIdForSource({
    required String revisionId,
    required String sourceParticipantId,
  }) async {
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(revisionId);
    final map = _map(payload['participantSourceIds']);
    for (final entry in map.entries) {
      if (entry.value == sourceParticipantId) return entry.key;
    }
    final rows = await _db.listParticipants();
    if (rows.any((p) => p.id == sourceParticipantId)) {
      return sourceParticipantId;
    }
    return null;
  }

  Future<String> sourceParticipantIdForLocal({
    required String revisionId,
    required String localParticipantId,
  }) async {
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(revisionId);
    final map = _map(payload['participantSourceIds']);
    final targetParticipantId = _string(payload['targetParticipantId']);
    if (localParticipantId.endsWith(':self') &&
        targetParticipantId.isNotEmpty) {
      return targetParticipantId;
    }
    return _string(map[localParticipantId], fallback: localParticipantId);
  }

  Future<ProposalActivationOutcome> tryActivatePlanIfUnanimous({
    required String planId,
    required String revisionId,
  }) async {
    final participants = await _participantsForPlan(planId);
    return PlanAgreementProposalService(_db).tryActivateIfUnanimous(
      planId: planId,
      revisionId: revisionId,
      participantIds: [for (final p in participants) p.id],
    );
  }

  /// Closes an open revision when [responseExpiresAt] has passed (task 1.7 / 1.2).
  Future<bool> expireRevisionIfNeeded({
    required String planId,
    required String revisionId,
  }) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return false;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    final state = HousingProposalRevisionState.fromPayload(payload);
    if (!state.isOpen || !state.isExpiredByClock) return false;

    payload['lifecycleState'] = 'archived';
    payload['invalidatedByStatus'] = 'expired';
    payload.remove('invalidatedByParticipantId');
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
    await (_db.update(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).write(
      const ProposalPackagesCompanion(pendingRevisionId: drift.Value(null)),
    );
    await RelayActivityLogService(_db).append(
      kind: RelayActivityLogKinds.housingProposalExpired,
      initiatorKind: RelayActivityLogService.initiatorSystem,
      planId: planId,
      packageId: payload['packageId']?.toString(),
      revisionId: revisionId,
    );
    return true;
  }

  Future<void> expireOpenRevisionsForPlan(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    final pendingId = pkg?.pendingRevisionId;
    if (pendingId == null) return;
    await expireRevisionIfNeeded(planId: planId, revisionId: pendingId);
  }

  Future<void> updateRevisionPayload({
    required String revisionId,
    required void Function(Map<String, dynamic> payload) mutate,
  }) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    mutate(payload);
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
  }

  Future<void> archiveInvalidatedProposal({
    required String planId,
    required String revisionId,
    required ProposalResponseStatus status,
    required String responderParticipantId,
  }) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    if (payload['lifecycleState'] == 'archived') return;
    payload['lifecycleState'] = 'archived';
    payload['invalidatedByStatus'] = status.name;
    payload['invalidatedByParticipantId'] = responderParticipantId;
    if (status == ProposalResponseStatus.rejected) {
      final blocked = List<String>.from(
        (payload['forkBlockedParticipantIds'] as List?) ?? const <String>[],
      );
      if (!blocked.contains(responderParticipantId)) {
        blocked.add(responderParticipantId);
      }
      payload['forkBlockedParticipantIds'] = blocked;
    }
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
    await (_db.update(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).write(
      const ProposalPackagesCompanion(pendingRevisionId: drift.Value(null)),
    );
    await RelayActivityLogService(_db).append(
      kind: RelayActivityLogKinds.housingProposalInvalidated,
      initiatorKind: RelayActivityLogService.initiatorContact,
      initiatorContactId: null,
      planId: planId,
      packageId: payload['packageId']?.toString(),
      revisionId: revisionId,
      details: {
        'status': status.name,
        'responderParticipantId': responderParticipantId,
      },
    );
  }

  Future<List<HousingProposalArchive>> listArchivesForPlan(
    String planId,
  ) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (pkg == null) return const <HousingProposalArchive>[];
    final revisions = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.packageId.equals(pkg.id))).get();
    final out = <HousingProposalArchive>[];
    final pendingRevisionIds = <String>{};
    if (pkg.pendingRevisionId != null) {
      final pending = await (_db.select(
        _db.proposalRevisions,
      )..where((t) => t.id.equals(pkg.pendingRevisionId!))).getSingleOrNull();
      if (pending != null) {
        pendingRevisionIds.add(pending.id);
        final payload = jsonDecode(pending.payloadJson) as Map<String, dynamic>;
        final responses = await (_db.select(
          _db.proposalResponses,
        )..where((t) => t.revisionId.equals(pending.id))).get();
        out.add(
          HousingProposalArchive(
            planId: planId,
            revisionId: pending.id,
            title: _string(_map(payload['plan'])['title'], fallback: planId),
            status: ProposalResponseStatus.pending,
            invalidatedAt: pending.createdAt,
            canFork: false,
            isPending: true,
            pendingResponseCount: responses
                .where((r) => r.status == ProposalResponseStatus.pending.name)
                .length,
            editorPlanId: planId,
          ),
        );
      }
    }
    for (final rev in revisions) {
      if (rev.id == pkg.pendingRevisionId) continue;
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      if (payload['lifecycleState'] == 'draft') {
        final draftPlanId = _string(payload['draftPlanId'], fallback: planId);
        if (await _hasSubmittedProposalForPlan(draftPlanId)) continue;
        final sentDraft = await _pendingArchiveForPlan(
          listPlanId: planId,
          planId: draftPlanId,
        );
        if (sentDraft != null) {
          if (pendingRevisionIds.add(sentDraft.revisionId)) {
            out.add(sentDraft);
          }
          continue;
        }
        if (payload['hideUntilAbandoned'] == true) continue;
        out.add(
          HousingProposalArchive(
            planId: planId,
            revisionId: rev.id,
            title: _string(_map(payload['plan'])['title'], fallback: planId),
            status: ProposalResponseStatus.pending,
            invalidatedAt: _date(payload['draftStartedAt']) ?? rev.createdAt,
            canFork: false,
            isDraft: true,
            participantCount: await _participantCountForPlan(draftPlanId),
            editorPlanId: draftPlanId,
          ),
        );
        continue;
      }
      if (payload['lifecycleState'] != 'archived') continue;
      final statusName = _string(payload['invalidatedByStatus']);
      final status = switch (statusName) {
        'negotiate' => ProposalResponseStatus.negotiate,
        'expired' => ProposalResponseStatus.pending,
        _ => ProposalResponseStatus.rejected,
      };
      final isExpiredArchive = statusName == 'expired';
      final responderParticipantId = _string(
        payload['invalidatedByParticipantId'],
      );
      final response = responderParticipantId.isEmpty
          ? null
          : await (_db.select(_db.proposalResponses)
                  ..where((t) => t.revisionId.equals(rev.id))
                  ..where(
                    (t) => t.participantId.equals(responderParticipantId),
                  ))
                .getSingleOrNull();
      out.add(
        HousingProposalArchive(
          planId: planId,
          revisionId: rev.id,
          title: _string(_map(payload['plan'])['title'], fallback: planId),
          status: status,
          invalidatedAt: response?.respondedAt ?? rev.createdAt,
          canFork: await canForkRevision(
            revisionId: rev.id,
            localParticipantId: '$planId:self',
          ),
          isExpired: isExpiredArchive,
        ),
      );
    }
    out.sort((a, b) => b.invalidatedAt.compareTo(a.invalidatedAt));
    return out;
  }

  Future<HousingProposalArchive?> _pendingArchiveForPlan({
    required String listPlanId,
    required String planId,
  }) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (pkg?.pendingRevisionId == null) return null;
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(pkg!.pendingRevisionId!))).getSingleOrNull();
    if (rev == null) return null;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    final responses = await (_db.select(
      _db.proposalResponses,
    )..where((t) => t.revisionId.equals(rev.id))).get();
    return HousingProposalArchive(
      planId: listPlanId,
      revisionId: rev.id,
      title: _string(_map(payload['plan'])['title'], fallback: listPlanId),
      status: ProposalResponseStatus.pending,
      invalidatedAt: rev.createdAt,
      canFork: false,
      isPending: true,
      pendingResponseCount: responses
          .where((r) => r.status == ProposalResponseStatus.pending.name)
          .length,
      editorPlanId: planId,
    );
  }

  Future<bool> planHasArchives(String planId) async {
    return (await listArchivesForPlan(
      planId,
    )).any((a) => !a.isDraft && !a.isPending);
  }

  Future<bool> canForkRevision({
    required String revisionId,
    required String localParticipantId,
  }) async {
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(revisionId);
    final blocked =
        (payload['forkBlockedParticipantIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};
    return !blocked.contains(localParticipantId);
  }

  Future<void> prepareForkFromArchive({
    required String planId,
    required String revisionId,
  }) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (pkg == null) return;
    await (_db.update(
      _db.proposalPackages,
    )..where((t) => t.id.equals(pkg.id))).write(
      const ProposalPackagesCompanion(pendingRevisionId: drift.Value(null)),
    );
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    payload['forkPreparedAt'] = DateTime.now().toUtc().toIso8601String();
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
  }

  Future<void> createForkDraftFromArchive({
    required String listPlanId,
    required String revisionId,
    required String draftPlanId,
  }) async {
    final rev = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingleOrNull();
    if (rev == null) return;
    final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    final now = DateTime.now().toUtc();
    final sourceToDraftParticipant = _forkParticipantMap(payload, draftPlanId);

    await _deleteReceivedPlanData(draftPlanId);
    await _upsertPlan(draftPlanId, payload, now);
    await _upsertForkParticipants(
      draftPlanId: draftPlanId,
      payload: payload,
      sourceToDraftParticipant: sourceToDraftParticipant,
      createdAt: now,
    );
    await _upsertGroups(draftPlanId, payload, now);
    await _upsertLines(
      draftPlanId,
      payload,
      now,
      sourceToLocalParticipant: sourceToDraftParticipant,
    );
    await _upsertRatios(
      receivedPlanId: draftPlanId,
      payload: payload,
      sourceToLocalParticipant: sourceToDraftParticipant,
      createdAt: now,
    );
    await _upsertAgreement(draftPlanId, payload, now);

    final draftRevisionId = 'draft:$draftPlanId';
    final packageId = await PlanAgreementProposalService(
      _db,
    ).ensurePackageForPlan(listPlanId);
    await _db
        .into(_db.proposalRevisions)
        .insertOnConflictUpdate(
          ProposalRevisionsCompanion.insert(
            id: draftRevisionId,
            packageId: packageId,
            contentHash: 'local-draft:$draftRevisionId',
            proposerParticipantId: '$draftPlanId:self',
            payloadJson: jsonEncode({
              'kind': PlanAgreementProposalService.kind,
              'lifecycleState': 'draft',
              'hideUntilAbandoned': true,
              'draftPlanId': draftPlanId,
              'draftStartedAt': now.toIso8601String(),
              'sourcePackageId': _string(
                payload['sourcePackageId'],
                fallback: _string(payload['packageId']),
              ),
              'sourceRevisionId': _string(
                payload['sourceRevisionId'],
                fallback: _string(payload['revisionId'], fallback: revisionId),
              ),
              'plan': {
                'title': _string(
                  _map(payload['plan'])['title'],
                  fallback: draftPlanId,
                ),
              },
            }),
            createdAt: now,
          ),
        );
  }

  Future<void> startPreparedForkDraft(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (pkg == null) return;
    final revisions = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.packageId.equals(pkg.id))).get();
    DateTime? latest;
    ProposalRevision? selected;
    Map<String, dynamic>? selectedPayload;
    for (final rev in revisions) {
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      final raw = _string(payload['forkPreparedAt']);
      if (raw.isEmpty) continue;
      final preparedAt =
          DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (latest != null && !preparedAt.isAfter(latest)) continue;
      latest = preparedAt;
      selected = rev;
      selectedPayload = payload;
    }
    final selectedRevision = selected;
    final payload = selectedPayload;
    if (selectedRevision == null || payload == null) return;
    payload['forkDraftStartedAt'] ??= DateTime.now().toUtc().toIso8601String();
    payload['forkDraftPlanId'] = planId;
    await (_db.update(
      _db.proposalRevisions,
    )..where((t) => t.id.equals(selectedRevision.id))).write(
      ProposalRevisionsCompanion(payloadJson: drift.Value(jsonEncode(payload))),
    );
  }

  Future<void> revealDraftEntry({
    required String listPlanId,
    required String draftPlanId,
  }) async {
    if (await _hasSubmittedProposalForPlan(draftPlanId)) return;
    final packageId = await PlanAgreementProposalService(
      _db,
    ).ensurePackageForPlan(listPlanId);
    final revisions = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.packageId.equals(packageId))).get();
    for (final rev in revisions) {
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      if (payload['lifecycleState'] != 'draft') continue;
      if (_string(payload['draftPlanId']) != draftPlanId) continue;
      if (payload['hideUntilAbandoned'] != true) return;
      payload.remove('hideUntilAbandoned');
      await (_db.update(
        _db.proposalRevisions,
      )..where((t) => t.id.equals(rev.id))).write(
        ProposalRevisionsCompanion(
          payloadJson: drift.Value(jsonEncode(payload)),
        ),
      );
      return;
    }
  }

  Future<bool> isHiddenDraftPlan(String draftPlanId) async {
    if (await _hasSubmittedProposalForPlan(draftPlanId)) return false;
    final revisions = await _db.select(_db.proposalRevisions).get();
    for (final rev in revisions) {
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      if (payload['lifecycleState'] != 'draft') continue;
      if (_string(payload['draftPlanId']) != draftPlanId) continue;
      if (payload['hideUntilAbandoned'] == true) return true;
    }
    return false;
  }

  Future<bool> _hasSubmittedProposalForPlan(String planId) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    if (pkg == null) return false;
    if (pkg.pendingRevisionId != null || pkg.activeRevisionId != null) {
      return true;
    }
    final revisions = await (_db.select(
      _db.proposalRevisions,
    )..where((t) => t.packageId.equals(pkg.id))).get();
    for (final rev in revisions) {
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      if (payload['lifecycleState'] != 'draft') return true;
    }
    return false;
  }

  Future<void> createStandaloneDraftEntry({
    required String listPlanId,
    required String draftPlanId,
  }) async {
    final service = PlanAgreementProposalService(_db);
    final packageId = await service.ensurePackageForPlan(listPlanId);
    final now = DateTime.now().toUtc();
    final revisionId = 'draft:$draftPlanId';
    final payload = <String, Object?>{
      'kind': PlanAgreementProposalService.kind,
      'lifecycleState': 'draft',
      'draftPlanId': draftPlanId,
      'draftStartedAt': now.toIso8601String(),
      'plan': {'title': draftPlanId},
    };
    await _db
        .into(_db.proposalRevisions)
        .insertOnConflictUpdate(
          ProposalRevisionsCompanion.insert(
            id: revisionId,
            packageId: packageId,
            contentHash: 'local-draft:$revisionId',
            proposerParticipantId: '$draftPlanId:self',
            payloadJson: jsonEncode(payload),
            createdAt: now,
          ),
        );
  }

  Future<int> _participantCountForPlan(String planId) async {
    return (await _participantsForPlan(planId)).length;
  }

  Future<({String packageId, String revisionId})?> preparedForkLineage(
    String planId,
  ) async {
    final pkg = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    final revisions = pkg == null
        ? await _db.select(_db.proposalRevisions).get()
        : await (_db.select(
            _db.proposalRevisions,
          )..where((t) => t.packageId.equals(pkg.id))).get();
    DateTime? latest;
    ({String packageId, String revisionId})? out;
    for (final rev in revisions) {
      final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
      final isPreparedOnSource = _string(payload['forkPreparedAt']).isNotEmpty;
      final isDraftForPlan =
          payload['lifecycleState'] == 'draft' &&
          _string(payload['draftPlanId']) == planId;
      if (!isPreparedOnSource && !isDraftForPlan) continue;
      final raw = _string(
        payload['forkPreparedAt'],
        fallback: _string(payload['draftStartedAt']),
      );
      if (raw.isEmpty) continue;
      final preparedAt =
          DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (latest != null && !preparedAt.isAfter(latest)) continue;
      latest = preparedAt;
      out = (
        packageId: _string(payload['sourcePackageId'], fallback: rev.packageId),
        revisionId: _string(payload['sourceRevisionId'], fallback: rev.id),
      );
    }
    return out;
  }

  Future<List<Participant>> _participantsForPlan(String planId) async {
    final rows = await _db.listParticipants();
    return rows
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .toList(growable: false);
  }

  Future<void> _deleteReceivedPlanData(String planId) async {
    final pkgs = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).get();
    for (final pkg in pkgs) {
      final revs = await (_db.select(
        _db.proposalRevisions,
      )..where((t) => t.packageId.equals(pkg.id))).get();
      for (final rev in revs) {
        await (_db.delete(
          _db.proposalResponses,
        )..where((t) => t.revisionId.equals(rev.id))).go();
      }
      await (_db.delete(
        _db.proposalRevisions,
      )..where((t) => t.packageId.equals(pkg.id))).go();
      await (_db.delete(
        _db.proposalPackages,
      )..where((t) => t.id.equals(pkg.id))).go();
    }
    await (_db.delete(
      _db.planRatios,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.planLines,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.agreements,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.planGroups,
    )..where((t) => t.planId.equals(planId))).go();
    final participants = await _db.listParticipants();
    for (final p in participants) {
      if (p.id == '$planId:self' || p.id.startsWith('$planId:p')) {
        await (_db.delete(
          _db.participants,
        )..where((t) => t.id.equals(p.id))).go();
      }
    }
  }

  /// Maps a source participant id from the proposal payload to a local tail (`self`, `p0`, …).
  String? _localParticipantTail(
    String sourceId,
    Map<String, String> sourceToLocalParticipant,
  ) {
    if (sourceId.isEmpty) return null;
    final direct = sourceToLocalParticipant[sourceId];
    if (direct != null) return direct;
    final tail = sourceId.contains(':') ? sourceId.split(':').last : sourceId;
    final byTail = sourceToLocalParticipant[tail];
    if (byTail != null) return byTail;
    for (final entry in sourceToLocalParticipant.entries) {
      if (entry.key == tail || entry.key.endsWith(':$tail')) return entry.value;
    }
    return null;
  }

  Map<String, String> _participantIdMap({
    required Map<String, dynamic> payload,
    required String targetParticipantId,
  }) {
    final sourceIds = <String>[];
    void add(String value) {
      if (value.isNotEmpty && !sourceIds.contains(value)) sourceIds.add(value);
    }

    add(targetParticipantId);
    add(_string(payload['proposerParticipantId']));
    final snapshots = payload['participantSnapshots'];
    if (snapshots is List) {
      for (final item in snapshots) {
        if (item is Map) add(_string(item['id']));
      }
    }
    final plan = payload['plan'];
    if (plan is Map) {
      final ratios = plan['ratios'];
      if (ratios is List) {
        for (final item in ratios) {
          if (item is Map) add(_string(item['participantId']));
        }
      }
      final lines = plan['lines'];
      if (lines is List) {
        for (final item in lines) {
          if (item is Map) {
            add(_string(item['paymentResponsibleParticipantId']));
          }
        }
      }
    }

    final out = <String, String>{};
    if (targetParticipantId.isNotEmpty) out[targetParticipantId] = 'self';
    var n = 0;
    for (final id in sourceIds) {
      out.putIfAbsent(id, () => 'p${n++}');
    }
    return out;
  }

  Map<String, String> _forkParticipantMap(
    Map<String, dynamic> payload,
    String draftPlanId,
  ) {
    final sourceIds = <String>[];
    void add(String value) {
      if (value.isNotEmpty && !sourceIds.contains(value)) sourceIds.add(value);
    }

    add(_string(payload['proposerParticipantId']));
    final snapshots = payload['participantSnapshots'];
    if (snapshots is List) {
      for (final item in snapshots) {
        if (item is Map) add(_string(item['id']));
      }
    }
    final ratios = _list(_map(payload['plan'])['ratios']);
    for (final ratio in ratios.whereType<Map>()) {
      add(_string(ratio['participantId']));
    }

    final out = <String, String>{};
    var next = 0;
    for (final sourceId in sourceIds) {
      if (sourceId.endsWith(':self')) {
        out[sourceId] = 'self';
        continue;
      }
      final match = RegExp(r':p(\d+)$').firstMatch(sourceId);
      final tail = match == null ? 'p${next++}' : 'p${match.group(1)}';
      if (tail != 'self') out[sourceId] = tail;
    }
    if (!out.containsValue('self')) {
      out['$draftPlanId:self'] = 'self';
    }
    return out;
  }

  Future<void> _upsertForkParticipants({
    required String draftPlanId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToDraftParticipant,
    required DateTime createdAt,
  }) async {
    final snapshots = <String, Map>{};
    final raw = payload['participantSnapshots'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) snapshots[_string(item['id'])] = item;
      }
    }
    for (final entry in sourceToDraftParticipant.entries) {
      final sourceId = entry.key;
      final localTail = entry.value;
      final snap = snapshots[sourceId];
      final sourceParticipant = await (_db.select(
        _db.participants,
      )..where((t) => t.id.equals(sourceId))).getSingleOrNull();
      final contactId = _string(
        snap?['contactId'],
        fallback: sourceParticipant?.contactId ?? '',
      );
      await _db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$draftPlanId:$localTail',
          displayName: _string(
            snap?['displayName'],
            fallback: sourceParticipant?.displayName ?? sourceId,
          ),
          avatarId: _string(
            snap?['avatarId'],
            fallback: sourceParticipant?.avatarId ?? 'a01',
          ),
          contactId: contactId.isEmpty
              ? const drift.Value.absent()
              : drift.Value(contactId),
          createdAt: createdAt,
        ),
      );
    }
  }

  Map<String, Object?> _remapPayload(
    Map<String, dynamic> payload, {
    required String receivedPlanId,
    required Map<String, String> sourceToLocalParticipant,
    required String receivedPackageId,
    required String receivedRevisionId,
  }) {
    final copy = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    final sourcePackageId = _string(payload['sourcePackageId']).isEmpty
        ? _string(payload['packageId'])
        : _string(payload['sourcePackageId']);
    final sourceRevisionId = _string(payload['sourceRevisionId']).isEmpty
        ? _string(payload['revisionId'])
        : _string(payload['sourceRevisionId']);
    copy['packageId'] = receivedPackageId;
    copy['revisionId'] = receivedRevisionId;
    copy['sourcePackageId'] = sourcePackageId;
    copy['sourceRevisionId'] = sourceRevisionId;
    copy['participantSourceIds'] = {
      for (final entry in sourceToLocalParticipant.entries)
        '$receivedPlanId:${entry.value}': entry.key,
    };
    copy['responseMessages'] = Map<String, dynamic>.from(
      (copy['responseMessages'] as Map?) ?? const <String, dynamic>{},
    );
    final proposer = _string(copy['proposerParticipantId']);
    if (sourceToLocalParticipant.containsKey(proposer)) {
      copy['proposerParticipantId'] =
          '$receivedPlanId:${sourceToLocalParticipant[proposer]}';
    }
    final plan = copy['plan'];
    if (plan is Map) {
      final ratios = plan['ratios'];
      if (ratios is List) {
        for (final item in ratios) {
          if (item is Map) {
            final id = _string(item['participantId']);
            final localTail = sourceToLocalParticipant[id];
            item['participantId'] = localTail == null
                ? id
                : '$receivedPlanId:$localTail';
          }
        }
      }
    }
    return copy;
  }

  Future<void> _upsertPlan(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final plan = _map(payload['plan']);
    await _db.upsertPlan(
      PlansCompanion.insert(
        id: receivedPlanId,
        type: _string(plan['type'], fallback: 'housing'),
        title: drift.Value(_string(plan['title'], fallback: receivedPlanId)),
        currency: drift.Value(_string(plan['defaultCurrency'])),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> _upsertParticipants({
    required String receivedPlanId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required String senderContactId,
    required String senderDisplayName,
    required String senderAvatarId,
    required DateTime createdAt,
  }) async {
    final snapshots = <String, Map>{};
    final raw = payload['participantSnapshots'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) snapshots[_string(item['id'])] = item;
      }
    }
    for (final entry in sourceToLocalParticipant.entries) {
      final sourceId = entry.key;
      final localTail = entry.value;
      final snap = snapshots[sourceId];
      final isProposer = sourceId == _string(payload['proposerParticipantId']);
      await _db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$receivedPlanId:$localTail',
          displayName: isProposer
              ? senderDisplayName
              : _string(snap?['displayName'], fallback: sourceId),
          avatarId: isProposer
              ? senderAvatarId
              : _string(snap?['avatarId'], fallback: 'a01'),
          contactId: isProposer
              ? drift.Value(senderContactId)
              : const drift.Value.absent(),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertGroups(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final groups = _list(_map(payload['plan'])['groups']);
    for (final group in groups.whereType<Map>()) {
      final sourceId = _string(group['id']);
      await _db.upsertPlanGroup(
        PlanGroupsCompanion.insert(
          id: '$receivedPlanId:grp:$sourceId',
          planId: receivedPlanId,
          title: _string(group['title'], fallback: sourceId),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertLines(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt, {
    required Map<String, String> sourceToLocalParticipant,
  }) async {
    final lines = _list(_map(payload['plan'])['lines']);
    for (final line in lines.whereType<Map>()) {
      final sourceId = _string(line['id']);
      final sourceGroupId = _string(line['groupId']);
      final paySource = _string(line['paymentResponsibleParticipantId']);
      final payLocal = _localParticipantTail(paySource, sourceToLocalParticipant);
      await _db.upsertPlanLine(
        PlanLinesCompanion.insert(
          id: '$receivedPlanId:line:$sourceId',
          planId: receivedPlanId,
          isRecurring: _bool(line['isRecurring']),
          title: _string(line['title'], fallback: sourceId),
          currency: _string(line['currency']),
          amountUsesRange: drift.Value(_bool(line['amountUsesRange'])),
          amountMinor: _intValue(line['amountMinor']),
          minAmountMinor: _intValue(line['minAmountMinor']),
          maxAmountMinor: _intValue(line['maxAmountMinor']),
          description: drift.Value(_string(line['description'])),
          cadence: drift.Value(_string(line['cadence'], fallback: 'monthly')),
          recurrenceDayOfMonth: _intValue(line['recurrenceDayOfMonth']),
          sortOrder: drift.Value(_int(line['sortOrder'])),
          groupId: sourceGroupId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:grp:$sourceGroupId'),
          paymentResponsibleParticipantId: payLocal == null
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:$payLocal'),
          recurrenceSpecJson: drift.Value(
            _string(line['recurrenceSpecJson']),
          ),
          ratioTemplateId: drift.Value(_string(line['ratioTemplateId'])),
          amountIsBudgetCap: drift.Value(_bool(line['amountIsBudgetCap'])),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertRatios({
    required String receivedPlanId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required DateTime createdAt,
  }) async {
    final ratios = _list(_map(payload['plan'])['ratios']);
    for (final ratio in ratios.whereType<Map>()) {
      final participant =
          sourceToLocalParticipant[_string(ratio['participantId'])];
      if (participant == null) continue;
      final sourceLineId = _string(ratio['lineId']);
      final sourceGroupId = _string(ratio['groupId']);
      await _db.upsertPlanRatio(
        PlanRatiosCompanion.insert(
          id: 'ratio:$receivedPlanId:${sourceLineId.isEmpty ? 'grp:$sourceGroupId' : sourceLineId}:$participant',
          planId: receivedPlanId,
          participantId: '$receivedPlanId:$participant',
          lineId: sourceLineId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:line:$sourceLineId'),
          groupId: sourceGroupId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:grp:$sourceGroupId'),
          weight: _int(ratio['weight']),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertAgreement(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final agreement = _map(payload['agreement']);
    await _db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$receivedPlanId',
        planId: receivedPlanId,
        periodStart: _date(agreement['periodStart']) ?? createdAt,
        periodEnd:
            _date(agreement['periodEnd']) ??
            createdAt.add(const Duration(days: 30)),
        minNoticeDays: drift.Value(_int(agreement['minNoticeDays'])),
        penaltyMinor: drift.Value(
          _int(_map(agreement['penalty'])['amountMinor']),
        ),
        clauses: drift.Value(_string(agreement['clauses'])),
        withdrawalSameForAll: drift.Value(
          _string(agreement['withdrawalSameForAll'], fallback: 'true'),
        ),
        withdrawalPerParticipantJson: drift.Value(
          _string(agreement['withdrawalPerParticipantJson'], fallback: '{}'),
        ),
        agreementRulesJson: drift.Value(
          _string(agreement['agreementRulesJson'], fallback: '{}'),
        ),
        createdAt: createdAt,
        version: drift.Value(_int(agreement['version'], fallback: 1)),
      ),
    );
  }

  Future<void> _upsertResponses({
    required String receivedPlanId,
    required String revisionId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required DateTime createdAt,
  }) async {
    final proposer =
        sourceToLocalParticipant[_string(payload['proposerParticipantId'])];
    for (final localTail in sourceToLocalParticipant.values) {
      final fullParticipantId = '$receivedPlanId:$localTail';
      final accepted = localTail == proposer;
      await _db
          .into(_db.proposalResponses)
          .insertOnConflictUpdate(
            ProposalResponsesCompanion.insert(
              id: 'resp:$revisionId:$fullParticipantId',
              revisionId: revisionId,
              participantId: fullParticipantId,
              status: accepted
                  ? ProposalResponseStatus.accepted.name
                  : ProposalResponseStatus.pending.name,
              respondedAt: accepted
                  ? drift.Value(createdAt)
                  : const drift.Value.absent(),
            ),
          );
    }
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  List<Object?> _list(Object? value) =>
      value is List ? value.cast<Object?>() : const <Object?>[];

  String _string(Object? value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  drift.Value<int?> _intValue(Object? value) {
    if (value == null) return const drift.Value.absent();
    return drift.Value(_int(value));
  }

  bool _bool(Object? value) => value == true || value.toString() == 'true';

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _token(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
