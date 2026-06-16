import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

// QA grep: `housing_realized_expense qa:` (transfer import / review banner diagnosis)
import '../../db/app_database.dart';
import '../housing_participant_snapshot_map.dart';
import '../housing_plan_peer_contacts.dart';
import 'proof_transport_payload.dart';
import 'realized_expense_line_snapshot.dart';
import 'realized_expense_participants.dart';
import 'realized_expense_repository.dart';
import 'realized_expense_status.dart';

class _LocalAgreementTarget {
  const _LocalAgreementTarget({
    required this.planId,
    required this.packageId,
  });

  final String planId;
  final String packageId;
}

/// Steady-state JSON sync for realized expense proposals (client-only relay kind).
class RealizedExpenseSyncService {
  RealizedExpenseSyncService(this._db);

  final AppDatabase _db;

  Future<String> buildProposeJson({
    required RealizedExpense expense,
    required List<RealizedExpenseAttachment> attachments,
  }) async {
    final roster = await participantsForPlan(_db, expense.planId);
    String? lineTitle = expense.planLineTitleSnapshot?.trim();
    List<Map<String, dynamic>>? splitRatiosPayload;
    if (RealizedExpenseKind.usesPlanLine(expense.kind)) {
      final snapshotJson = expense.splitRatiosJson;
      if (snapshotJson != null && snapshotJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(snapshotJson);
          if (decoded is List) {
            splitRatiosPayload = [
              for (final entry in decoded)
                if (entry is Map)
                  {
                    'participantId': entry['participantId'],
                    'weight': entry['weight'],
                  },
            ];
          }
        } catch (_) {}
      }
      if (lineTitle == null || lineTitle.isEmpty) {
        final lines = await _db.listPlanLines(expense.planId);
        for (final line in lines) {
          if (line.id != expense.planLineId) continue;
          final t = line.title.trim();
          if (t.isNotEmpty) {
            lineTitle = t;
            break;
          }
        }
      }
      if (splitRatiosPayload == null || splitRatiosPayload.isEmpty) {
        final ratios = await currentRatiosForPlanLine(
          _db,
          expense.planId,
          expense.planLineId,
        );
        if (ratios.isNotEmpty) {
          splitRatiosPayload = [
            for (final ratio in ratios)
              {
                'participantId': ratio.participantId,
                'weight': ratio.weight,
              },
          ];
        }
      }
    }

    return jsonEncode({
      'expense_id': expense.id,
      'package_id': expense.packageId,
      'plan_id': expense.planId,
      'plan_line_id': expense.planLineId,
      'plan_line_title': ?lineTitle,
      if (splitRatiosPayload != null && splitRatiosPayload.isNotEmpty)
        'split_ratios': splitRatiosPayload,
      'amount_minor': expense.amountMinor,
      'payment_chart_carry_forward_minor': expense.paymentChartCarryForwardMinor,
      'currency': expense.currency,
      'payment_date': expense.paymentDate.toUtc().toIso8601String(),
      'kind': expense.kind,
      'beneficiary_participant_id': expense.beneficiaryParticipantId,
      if ((expense.description ?? '').trim().isNotEmpty)
        'description': expense.description!.trim(),
      'payer_participant_id': expense.payerParticipantId,
      'participant_snapshots': [
        for (final p in roster)
          {
            'id': p.id,
            'displayName': p.displayName,
            if (p.contactId != null) 'contactId': p.contactId,
          },
      ],
      'attachments': [
        for (final a in attachments)
          await buildSyncedProofAttachmentPayload(a),
      ],
    });
  }

  /// Imports a peer proposal if not already present; returns false when skipped.
  Future<bool> importProposedFromPeer({
    required String expenseJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(expenseJson) as Map<String, dynamic>;
    final expenseId = payload['expense_id'] as String? ?? '';
    if (expenseId.isEmpty) {
      _log('import skip: missing expense_id');
      return false;
    }

    final existing = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.id.equals(expenseId)))
        .getSingleOrNull();
    if (existing != null) {
      final acceptances = await RealizedExpenseRepository(_db).acceptancesFor(
        expenseId,
      );
      _logQaTransfer(
        'import duplicate expense=$expenseId kind=${existing.kind} '
        'localPayer=${existing.payerParticipantId} '
        'localBeneficiary=${existing.beneficiaryParticipantId} '
        'acceptances=${acceptances.length} '
        'rows=${_acceptanceRowsForLog(acceptances)}',
      );
      _log('import ok: duplicate $expenseId (idempotent)');
      return true;
    }

    final target = await _resolveLocalAgreementTarget(
      payloadPackageId: payload['package_id'] as String? ?? '',
      payloadPlanId: payload['plan_id'] as String? ?? '',
    );
    if (target == null) {
      _log(
        'import skip: no local active agreement for package='
        '${payload['package_id']} plan=${payload['plan_id']}',
      );
      return false;
    }

    final sourceToLocal = await mapSourceParticipantIdsFromSnapshots(
      db: _db,
      planId: target.planId,
      snapshots: payload['participant_snapshots'],
    );

    final sourcePayer = payload['payer_participant_id'] as String? ?? '';
    var payerId = sourcePayer.isEmpty
        ? null
        : await resolveImportedParticipantId(
          db: _db,
          planId: target.planId,
          sourceParticipantId: sourcePayer,
          sourceToLocal: sourceToLocal,
          senderContactId: senderContactId,
        );
    payerId ??= await localParticipantIdForSenderContact(
      db: _db,
      planId: target.planId,
      senderContactId: senderContactId,
    );
    if (payerId == null) {
      _log(
        'import skip: payer not in roster for plan ${target.planId} '
        '(sender contact $senderContactId, source payer $sourcePayer)',
      );
      return false;
    }

    final kind = payload['kind'] as String? ?? RealizedExpenseKind.normal;
    String planLineId = '';
    if (RealizedExpenseKind.usesPlanLine(kind)) {
      final resolvedPlanLineId = await _resolvePlanLineId(
        target.planId,
        payload,
      );
      if (resolvedPlanLineId == null) {
        _log('import skip: plan line not found on ${target.planId}');
        return false;
      }
      planLineId = resolvedPlanLineId;
    }

    final beneficiarySource =
        payload['beneficiary_participant_id'] as String?;
    final beneficiaryLocal =
        beneficiarySource == null || beneficiarySource.isEmpty
            ? null
            : kind == RealizedExpenseKind.transfer
            ? await _resolveTransferBeneficiaryLocalId(
                planId: target.planId,
                beneficiarySource: beneficiarySource,
                snapshots: payload['participant_snapshots'],
              )
            : await resolveImportedParticipantId(
              db: _db,
              planId: target.planId,
              sourceParticipantId: beneficiarySource,
              sourceToLocal: sourceToLocal,
            );
    if (kind == RealizedExpenseKind.transfer &&
        (beneficiaryLocal == null || beneficiaryLocal.isEmpty)) {
      _logQaTransfer(
        'import skip beneficiary expense=$expenseId plan=${target.planId} '
        'sourceBeneficiary=$beneficiarySource senderContact=$senderContactId',
      );
      _log('import skip: transfer beneficiary not found on ${target.planId}');
      return false;
    }

    _logQaTransfer(
      'import map expense=$expenseId kind=$kind plan=${target.planId} '
      'sourcePayer=$sourcePayer sourceBeneficiary=$beneficiarySource '
      'localPayer=$payerId localBeneficiary=$beneficiaryLocal '
      'self=${selfParticipantIdForPlan(target.planId)} '
      'senderContact=$senderContactId '
      'payerEqBeneficiary=${payerId == beneficiaryLocal}',
    );

    final paymentDate = DateTime.tryParse(
      payload['payment_date'] as String? ?? '',
    );
    if (paymentDate == null) {
      _log('import skip: invalid payment_date');
      return false;
    }

    final now = DateTime.now().toUtc();
    final roster = await participantsForPlan(_db, target.planId);
    final importedPlanLineTitle =
        (payload['plan_line_title'] as String?)?.trim();
    final importedSplitRatiosJson = remapSplitRatiosJsonForLocalPlan(
      planId: target.planId,
      lineId: planLineId,
      splitRatiosJson: _splitRatiosJsonFromPayload(payload['split_ratios']),
      roster: roster,
      sourceToLocal: sourceToLocal,
    );
    await _db.into(_db.realizedExpenses).insert(
          RealizedExpensesCompanion.insert(
            id: expenseId,
            packageId: target.packageId,
            planId: target.planId,
            planLineId: planLineId,
            status: RealizedExpenseStatus.proposed,
            amountMinor: payload['amount_minor'] as int? ?? 0,
            paymentChartCarryForwardMinor: drift.Value(
              payload['payment_chart_carry_forward_minor'] as int? ?? 0,
            ),
            currency: payload['currency'] as String? ?? '',
            paymentDate: paymentDate,
            payerParticipantId: payerId,
            kind: kind,
            beneficiaryParticipantId: drift.Value(beneficiaryLocal),
            description: drift.Value((payload['description'] as String?)?.trim()),
            planLineTitleSnapshot: importedPlanLineTitle == null ||
                    importedPlanLineTitle.isEmpty
                ? const drift.Value.absent()
                : drift.Value(importedPlanLineTitle),
            splitRatiosJson: importedSplitRatiosJson == null
                ? const drift.Value.absent()
                : drift.Value(importedSplitRatiosJson),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final repo = RealizedExpenseRepository(_db);
    final attachments = payload['attachments'];
    if (attachments is List) {
      for (final raw in attachments) {
        if (raw is! Map) continue;
        final name = raw['display_file_name'] as String? ?? 'proof';
        final persistedPath = await importSyncedProofAttachmentPath(raw);
        await _db.into(_db.realizedExpenseAttachments).insert(
              RealizedExpenseAttachmentsCompanion.insert(
                id: repo.newAttachmentId(),
                expenseId: expenseId,
                filePath: persistedPath ?? '',
                displayFileName: name,
                contentHash: drift.Value(raw['content_hash'] as String?),
                createdAt: now,
              ),
            );
      }
    }

    final importedExpense = await repo.getById(expenseId);
    if (importedExpense == null) {
      _log('import skip: stored expense missing after insert');
      return false;
    }
    for (final p in roster) {
      if (!repo.isTransferReviewParticipant(importedExpense, p.id)) continue;
      final isPayer = p.id == payerId;
      await _db.into(_db.realizedExpenseAcceptances).insert(
            RealizedExpenseAcceptancesCompanion.insert(
              expenseId: expenseId,
              participantId: p.id,
              decision: isPayer
                  ? RealizedExpenseDecision.accepted
                  : RealizedExpenseDecision.pending,
              decidedAt: drift.Value(isPayer ? now : null),
            ),
            mode: drift.InsertMode.insertOrIgnore,
          );
    }

    await captureLineSnapshotForExpense(_db, importedExpense);

    final acceptances = await repo.acceptancesFor(expenseId);
    _logQaTransfer(
      'import acceptances expense=$expenseId count=${acceptances.length} '
      'rows=${_acceptanceRowsForLog(acceptances)} '
      'storedPayer=${importedExpense.payerParticipantId} '
      'storedBeneficiary=${importedExpense.beneficiaryParticipantId}',
    );

    _log('import ok: $expenseId -> plan ${target.planId}');
    return true;
  }

  Future<String> buildDecisionJson({
    required String expenseId,
    required String packageId,
    required String participantId,
    required String decision,
    String? justification,
  }) async {
    final expense = await RealizedExpenseRepository(_db).getById(expenseId);
    final roster = expense == null
        ? <Participant>[]
        : await participantsForPlan(_db, expense.planId);
    return jsonEncode({
      'expense_id': expenseId,
      'package_id': packageId,
      'decision': decision,
      if (justification != null && justification.trim().isNotEmpty)
        'justification': justification.trim(),
      'participant_id': participantId,
      'participant_snapshots': [
        for (final p in roster)
          {
            'id': p.id,
            'displayName': p.displayName,
            if (p.contactId != null) 'contactId': p.contactId,
          },
      ],
    });
  }

  /// Applies a peer accept/reject; returns false when skipped.
  Future<bool> importDecisionFromPeer({
    required String decisionJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(decisionJson) as Map<String, dynamic>;
    final expenseId = payload['expense_id'] as String? ?? '';
    if (expenseId.isEmpty) return false;

    final expense = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.id.equals(expenseId)))
        .getSingleOrNull();
    if (expense == null) {
      _log('decision skip: unknown expense $expenseId');
      return false;
    }

    var localParticipantId = await localParticipantIdForSenderContact(
      db: _db,
      planId: expense.planId,
      senderContactId: senderContactId,
    );
    if (localParticipantId == null) {
      final sourceParticipantId = payload['participant_id'] as String? ?? '';
      localParticipantId = await resolveImportedParticipantId(
        db: _db,
        planId: expense.planId,
        sourceParticipantId: sourceParticipantId,
        sourceToLocal: await mapSourceParticipantIdsFromSnapshots(
          db: _db,
          planId: expense.planId,
          snapshots: payload['participant_snapshots'],
        ),
        senderContactId: senderContactId,
      );
    }
    if (localParticipantId == null) {
      _log('decision skip: participant not mapped for $expenseId');
      return false;
    }

    final decision = payload['decision'] as String? ?? '';
    if (decision != RealizedExpenseDecision.accepted &&
        decision != RealizedExpenseDecision.rejected) {
      return false;
    }

    await RealizedExpenseRepository(_db).applyPeerDecision(
      expenseId: expenseId,
      participantId: localParticipantId,
      decision: decision,
      justification: payload['justification'] as String?,
    );
    _log('decision ok: $decision on $expenseId by $localParticipantId');
    return true;
  }

  /// Maps a transfer beneficiary from relay snapshots by display name first.
  ///
  /// Peer slot ids (`:p1`, …) are device-local. [mapSourceParticipantIdsFromSnapshots]
  /// may match a routing [Contact.id] on the payer's roster slot (e.g. plan-est)
  /// when the receiver **is** the beneficiary — display name disambiguates.
  Future<String?> _resolveTransferBeneficiaryLocalId({
    required String planId,
    required String beneficiarySource,
    required Object? snapshots,
  }) async {
    final fromDisplayName = await _localParticipantIdForSnapshotDisplayName(
      planId: planId,
      sourceParticipantId: beneficiarySource,
      snapshots: snapshots,
    );
    if (fromDisplayName != null && fromDisplayName.isNotEmpty) {
      return fromDisplayName;
    }
    return localParticipantIdForSnapshotSource(
      db: _db,
      planId: planId,
      sourceParticipantId: beneficiarySource,
      snapshots: snapshots,
    );
  }

  Future<String?> _localParticipantIdForSnapshotDisplayName({
    required String planId,
    required String sourceParticipantId,
    required Object? snapshots,
  }) async {
    if (sourceParticipantId.isEmpty || snapshots is! List) return null;

    for (final raw in snapshots) {
      if (raw is! Map) continue;
      if ((raw['id'] as String?) != sourceParticipantId) continue;
      final name = (raw['displayName'] as String? ?? '').trim().toLowerCase();
      if (name.isEmpty) return null;
      final roster = await participantsForPlan(_db, planId);
      for (final participant in roster) {
        if (participant.displayName.trim().toLowerCase() == name) {
          return participant.id;
        }
      }
      return null;
    }
    return null;
  }

  void _log(String message) {
    debugPrint('housing_realized_expense $message');
  }

  void _logQaTransfer(String message) {
    debugPrint('housing_realized_expense qa: $message');
  }

  String _acceptanceRowsForLog(List<RealizedExpenseAcceptance> acceptances) {
    if (acceptances.isEmpty) return '(none)';
    return acceptances
        .map((a) => '${a.participantId}:${a.decision}')
        .join(',');
  }

  Future<_LocalAgreementTarget?> _resolveLocalAgreementTarget({
    required String payloadPackageId,
    required String payloadPlanId,
  }) async {
    if (payloadPackageId.isNotEmpty) {
      final byPkg = await (_db.select(_db.proposalPackages)
            ..where((t) => t.id.equals(payloadPackageId)))
          .getSingleOrNull();
      if (byPkg?.activeRevisionId != null) {
        return _LocalAgreementTarget(
          planId: byPkg!.planId,
          packageId: byPkg.id,
        );
      }
    }

    if (payloadPlanId.isNotEmpty) {
      final byPlan = await (_db.select(_db.proposalPackages)
            ..where((t) => t.planId.equals(payloadPlanId)))
          .get();
      for (final pkg in byPlan) {
        if (pkg.activeRevisionId != null) {
          return _LocalAgreementTarget(planId: pkg.planId, packageId: pkg.id);
        }
      }
    }

    final active = await (_db.select(_db.proposalPackages)
          ..where((t) => t.activeRevisionId.isNotNull()))
        .get();
    if (active.isEmpty) return null;
    if (active.length == 1) {
      final pkg = active.single;
      return _LocalAgreementTarget(planId: pkg.planId, packageId: pkg.id);
    }

    for (final pkg in active) {
      final plan = await (_db.select(_db.plans)
            ..where((t) => t.id.equals(pkg.planId)))
          .getSingleOrNull();
      if (plan?.type == 'housing') {
        return _LocalAgreementTarget(planId: pkg.planId, packageId: pkg.id);
      }
    }
    return null;
  }

  Future<String?> _resolvePlanLineId(
    String localPlanId,
    Map<String, dynamic> payload,
  ) async {
    final lines = await _db.listPlanLines(localPlanId);
    if (lines.isEmpty) return null;

    final title = (payload['plan_line_title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) {
      for (final line in lines) {
        if (line.title.trim() == title) return line.id;
      }
    }

    final sourceLineId = payload['plan_line_id'] as String? ?? '';
    for (final line in lines) {
      if (line.id == sourceLineId) return line.id;
    }

    return lines.first.id;
  }

  String? _splitRatiosJsonFromPayload(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final entries = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final participantId = item['participantId']?.toString() ?? '';
      final weight = item['weight'];
      if (participantId.isEmpty || weight is! num) continue;
      entries.add({
        'participantId': participantId,
        'weight': weight.toInt(),
      });
    }
    if (entries.isEmpty) return null;
    return jsonEncode(entries);
  }
}
