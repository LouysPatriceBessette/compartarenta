import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import '../../db/app_database.dart';
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
      'currency': expense.currency,
      'payment_date': expense.paymentDate.toUtc().toIso8601String(),
      'kind': expense.kind,
      'beneficiary_participant_id': expense.beneficiaryParticipantId,
      if ((expense.description ?? '').trim().isNotEmpty)
        'description': expense.description!.trim(),
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

    final payerId = await _localParticipantIdForContact(
      planId: target.planId,
      contactId: senderContactId,
    );
    if (payerId == null) {
      _log(
        'import skip: payer not in roster for plan ${target.planId} '
        '(sender contact $senderContactId)',
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

    final sourceToLocal = await _mapSourceParticipantIds(
      planId: target.planId,
      snapshots: payload['participant_snapshots'],
    );
    final beneficiarySource =
        payload['beneficiary_participant_id'] as String?;
    final beneficiaryLocal = beneficiarySource == null
        ? null
        : sourceToLocal[beneficiarySource];
    if (kind == RealizedExpenseKind.transfer &&
        (beneficiaryLocal == null || beneficiaryLocal.isEmpty)) {
      _log('import skip: transfer beneficiary not found on ${target.planId}');
      return false;
    }

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

    var localParticipantId = await _localParticipantIdForContact(
      planId: expense.planId,
      contactId: senderContactId,
    );
    if (localParticipantId == null) {
      final sourceParticipantId = payload['participant_id'] as String? ?? '';
      final sourceToLocal = await _mapSourceParticipantIds(
        planId: expense.planId,
        snapshots: payload['participant_snapshots'],
      );
      localParticipantId = sourceToLocal[sourceParticipantId];
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

  void _log(String message) {
    debugPrint('housing_realized_expense $message');
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

  Future<String?> _localParticipantIdForContact({
    required String planId,
    required String contactId,
  }) async {
    final roster = await participantsForPlan(_db, planId);
    for (final p in roster) {
      if (p.contactId == contactId) return p.id;
    }
    return null;
  }

  Future<Map<String, String>> _mapSourceParticipantIds({
    required String planId,
    required Object? snapshots,
  }) async {
    final out = <String, String>{};
    if (snapshots is! List) return out;

    final roster = await participantsForPlan(_db, planId);
    for (final raw in snapshots) {
      if (raw is! Map) continue;
      final sourceId = raw['id'] as String? ?? '';
      if (sourceId.isEmpty) continue;

      final contactId = raw['contactId'] as String?;
      if (contactId != null) {
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
