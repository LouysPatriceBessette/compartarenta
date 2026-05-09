import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';

/// Local-only proposal/renegotiation support.
///
/// This is a stepping stone toward sync-backed proposals:
/// - We persist self-contained proposal package revisions (payload JSON).
/// - We persist per-participant responses.
/// - We activate a revision only when unanimity is reached.
class PlanContractProposalService {
  PlanContractProposalService(this._db);
  final AppDatabase _db;

  static const String kind = 'expensePlanContractProposal';

  Future<String> ensurePackageForPlan(String planId) async {
    final existing = await (_db.select(_db.proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = 'pkg:$planId';
    await _db.into(_db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: id,
            planId: planId,
            createdAt: DateTime.now().toUtc(),
            activeRevisionId: const drift.Value.absent(),
            pendingRevisionId: const drift.Value.absent(),
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );
    return id;
  }

  Future<String> createRevisionFromCurrentDraft({
    required String planId,
    required String proposerParticipantId,
  }) async {
    final packageId = await ensurePackageForPlan(planId);

    final plan = await (_db.select(_db.plans)..where((t) => t.id.equals(planId)))
        .getSingle();
    final contract = await _db.getContractForPlan(planId);
    if (contract == null) {
      throw StateError('No contract found for plan $planId');
    }
    final lines = await _db.listPlanLines(planId);
    final ratios = await (_db.select(_db.planRatios)
          ..where((t) => t.planId.equals(planId)))
        .get();
    final groups = await (_db.select(_db.planGroups)
          ..where((t) => t.planId.equals(planId)))
        .get();

    final revisionId = 'rev:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final createdAt = DateTime.now().toUtc();

    final payload = <String, Object?>{
      'kind': kind,
      'packageId': packageId,
      'revisionId': revisionId,
      'contentHash': 'local:$revisionId',
      'createdAt': createdAt.toIso8601String(),
      'proposerParticipantId': proposerParticipantId,
      'plan': {
        'type': plan.type,
        'title': plan.title,
        'defaultCurrency': plan.currency,
        'groups': [
          for (final g in groups) {'id': g.id, 'title': g.title}
        ],
        'lines': [
          for (final l in lines)
            {
              'id': l.id,
              'title': l.title,
              'currency': l.currency,
              if (l.isRecurring)
                'recurring': {'cadence': l.cadence, 'amountMinor': l.amountMinor ?? 0}
              else
                'oneOff': {
                  'minAmountMinor': l.minAmountMinor ?? 0,
                  'maxAmountMinor': l.maxAmountMinor ?? 0,
                },
              if (l.groupId != null) 'groupId': l.groupId,
            }
        ],
        'ratios': [
          for (final r in ratios)
            {
              'participantId': r.participantId,
              if (r.lineId != null) 'lineId': r.lineId,
              if (r.groupId != null) 'groupId': r.groupId,
              'weight': r.weight,
            }
        ],
      },
      'contract': {
        'version': contract.version,
        'periodStart': contract.periodStart.toIso8601String(),
        'periodEnd': contract.periodEnd.toIso8601String(),
        'minNoticeDays': contract.minNoticeDays,
        'penalty': {'currency': plan.currency, 'amountMinor': contract.penaltyMinor},
        'clauses': contract.clauses,
      },
    };

    await _db.transaction(() async {
      await _db.into(_db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: revisionId,
              packageId: packageId,
              contentHash: 'local:$revisionId',
              proposerParticipantId: proposerParticipantId,
              payloadJson: jsonEncode(payload),
              createdAt: createdAt,
            ),
          );

      await (_db.update(_db.proposalPackages)
            ..where((t) => t.id.equals(packageId)))
          .write(ProposalPackagesCompanion(
            pendingRevisionId: drift.Value(revisionId),
          ));

      // Proposer implicitly accepts locally.
      await recordResponse(
        revisionId: revisionId,
        participantId: proposerParticipantId,
        status: ProposalResponseStatus.accepted,
      );
    });

    return revisionId;
  }

  Future<void> recordResponse({
    required String revisionId,
    required String participantId,
    required ProposalResponseStatus status,
  }) async {
    final id = 'resp:$revisionId:$participantId';
    await _db.into(_db.proposalResponses).insertOnConflictUpdate(
          ProposalResponsesCompanion.insert(
            id: id,
            revisionId: revisionId,
            participantId: participantId,
            status: status.name,
            respondedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<bool> tryActivateIfUnanimous({
    required String planId,
    required String revisionId,
    required List<String> participantIds,
  }) async {
    final packageId = await ensurePackageForPlan(planId);

    final responses = await (_db.select(_db.proposalResponses)
          ..where((t) => t.revisionId.equals(revisionId)))
        .get();

    final byParticipant = {
      for (final r in responses) r.participantId: r.status,
    };

    final unanimous = participantIds.isNotEmpty &&
        participantIds.every((p) => byParticipant[p] == ProposalResponseStatus.accepted.name);

    if (!unanimous) return false;

    await _db.transaction(() async {
      await (_db.update(_db.proposalPackages)
            ..where((t) => t.id.equals(packageId)))
          .write(
        ProposalPackagesCompanion(
          activeRevisionId: drift.Value(revisionId),
          pendingRevisionId: const drift.Value.absent(),
        ),
      );
    });
    return true;
  }

  Future<Map<String, Object?>> loadRevisionPayload(String revisionId) async {
    final rev = await (_db.select(_db.proposalRevisions)
          ..where((t) => t.id.equals(revisionId)))
        .getSingle();
    return jsonDecode(rev.payloadJson) as Map<String, Object?>;
  }
}

enum ProposalResponseStatus {
  pending,
  accepted,
  rejected,
}

