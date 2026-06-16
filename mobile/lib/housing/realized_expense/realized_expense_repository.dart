import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import 'realized_expense_line_snapshot.dart';
import 'realized_expense_participants.dart';
import 'realized_expense_status.dart';

/// Local persistence for realized expenses (draft save; sync in pass 3).
class RealizedExpenseRepository {
  RealizedExpenseRepository(this._db);

  final AppDatabase _db;
  static final _rng = Random();

  String newExpenseId() {
    final ms = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'realized:$ms-${_rng.nextInt(0x7fffffff)}';
  }

  String newAttachmentId() {
    final ms = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'realized_att:$ms-${_rng.nextInt(0x7fffffff)}';
  }

  Future<RealizedExpense?> getById(String id) => (_db.select(
        _db.realizedExpenses,
      )..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<RealizedExpense>> listDraftsForPackage(String packageId) =>
      (_db.select(_db.realizedExpenses)
            ..where((t) => t.packageId.equals(packageId))
            ..where((t) => t.status.equals(RealizedExpenseStatus.draft))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<List<RealizedExpenseAttachment>> attachmentsFor(String expenseId) =>
      (_db.select(_db.realizedExpenseAttachments)
            ..where((t) => t.expenseId.equals(expenseId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<List<RealizedExpenseAcceptance>> acceptancesFor(String expenseId) =>
      (_db.select(_db.realizedExpenseAcceptances)
            ..where((t) => t.expenseId.equals(expenseId)))
          .get();

  bool isTransferReviewParticipant(
    RealizedExpense expense,
    String participantId,
  ) {
    if (expense.kind != RealizedExpenseKind.transfer) return true;
    return participantId == expense.payerParticipantId ||
        participantId == expense.beneficiaryParticipantId;
  }

  /// Saves or updates a **draft** realized expense (local only, not synced).
  Future<RealizedExpense> saveDraft({
    required String packageId,
    required String planId,
    required String planLineId,
    required int amountMinor,
    required String currency,
    required DateTime paymentDate,
    required String payerParticipantId,
    required String kind,
    String? beneficiaryParticipantId,
    String? description,
    String? existingExpenseId,
    int paymentChartCarryForwardMinor = 0,
    List<RealizedExpenseAttachmentDraft>? attachments,
  }) async {
    final now = DateTime.now().toUtc();
    final id = existingExpenseId ?? newExpenseId();
    final existing = await getById(id);
    if (existing != null &&
        existing.status != RealizedExpenseStatus.draft) {
      throw StateError('Cannot save draft: expense is not in draft status');
    }

    await _db.into(_db.realizedExpenses).insertOnConflictUpdate(
          RealizedExpensesCompanion.insert(
            id: id,
            packageId: packageId,
            planId: planId,
            planLineId: planLineId,
            status: RealizedExpenseStatus.draft,
            amountMinor: amountMinor,
            currency: currency,
            paymentDate: paymentDate,
            payerParticipantId: payerParticipantId,
            kind: kind,
            beneficiaryParticipantId: drift.Value(beneficiaryParticipantId),
            description: drift.Value(description?.trim()),
            paymentChartCarryForwardMinor: drift.Value(
              paymentChartCarryForwardMinor,
            ),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    if (attachments != null) {
      await (_db.delete(_db.realizedExpenseAttachments)
            ..where((t) => t.expenseId.equals(id)))
          .go();
      for (final att in attachments) {
        await _db.into(_db.realizedExpenseAttachments).insert(
              RealizedExpenseAttachmentsCompanion.insert(
                id: att.id ?? newAttachmentId(),
                expenseId: id,
                filePath: att.filePath,
                displayFileName: att.displayFileName,
                contentHash: drift.Value(att.contentHash),
                createdAt: now,
              ),
            );
      }
    }

    return (await getById(id))!;
  }

  Future<void> deleteDraft(String expenseId) async {
    final row = await getById(expenseId);
    if (row == null) return;
    if (row.status != RealizedExpenseStatus.draft) {
      throw StateError('Only draft expenses can be deleted locally');
    }
    await (_db.delete(_db.realizedExpenseAcceptances)
          ..where((t) => t.expenseId.equals(expenseId)))
        .go();
    await (_db.delete(_db.realizedExpenseAttachments)
          ..where((t) => t.expenseId.equals(expenseId)))
        .go();
    await (_db.delete(_db.realizedExpenses)
          ..where((t) => t.id.equals(expenseId)))
        .go();
  }

  Future<List<RealizedExpense>> listRejectedBySelf({
    required String packageId,
    required String planId,
    required String selfParticipantId,
  }) async {
    final rows = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.packageId.equals(packageId))
          ..where((t) => t.planId.equals(planId))
          ..where((t) => t.status.equals(RealizedExpenseStatus.rejected))
          ..where((t) => t.payerParticipantId.equals(selfParticipantId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows;
  }

  /// Transitions a draft to `proposed` and seeds acceptance rows.
  Future<RealizedExpense> proposeLocally(String expenseId) async {
    final row = await getById(expenseId);
    if (row == null) {
      throw StateError('Expense not found: $expenseId');
    }
    if (row.status != RealizedExpenseStatus.draft) {
      throw StateError('Only draft expenses can be proposed');
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.realizedExpenses)..where((t) => t.id.equals(expenseId)))
        .write(
      RealizedExpensesCompanion(
        status: drift.Value(RealizedExpenseStatus.proposed),
        updatedAt: drift.Value(now),
      ),
    );

    final roster = await participantsForPlan(_db, row.planId);
    final payerId = row.payerParticipantId;
    final beneficiaryId = row.beneficiaryParticipantId;
    if (row.kind == RealizedExpenseKind.transfer &&
        (beneficiaryId == null || beneficiaryId.isEmpty)) {
      throw StateError('Transfer expenses require a beneficiary participant');
    }
    await (_db.delete(_db.realizedExpenseAcceptances)
          ..where((t) => t.expenseId.equals(expenseId)))
        .go();
    for (final p in roster) {
      if (!isTransferReviewParticipant(row, p.id)) continue;
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
          );
    }

    await _recomputeExpenseStatus(expenseId, now: now);
    final proposed = (await getById(expenseId))!;
    await captureLineSnapshotForExpense(_db, proposed);
    return (await getById(expenseId))!;
  }

  /// Repairs proposals created before payer auto-accept (e.g. pass #2 QA data).
  Future<void> ensurePayerAcceptedIfPending(RealizedExpense expense) async {
    if (expense.status != RealizedExpenseStatus.proposed) return;
    final acceptances = await acceptancesFor(expense.id);
    for (final a in acceptances) {
      if (a.participantId == expense.payerParticipantId &&
          a.decision == RealizedExpenseDecision.pending) {
        await recordLocalAccept(
          expenseId: expense.id,
          participantId: expense.payerParticipantId,
        );
        return;
      }
    }
  }

  Future<RealizedExpense> recordLocalAccept({
    required String expenseId,
    required String participantId,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.realizedExpenseAcceptances)
          ..where((t) => t.expenseId.equals(expenseId))
          ..where((t) => t.participantId.equals(participantId)))
        .write(
      RealizedExpenseAcceptancesCompanion(
        decision: drift.Value(RealizedExpenseDecision.accepted),
        decidedAt: drift.Value(now),
        rejectionJustification: const drift.Value(null),
      ),
    );
    await _recomputeExpenseStatus(expenseId, now: now);
    return (await getById(expenseId))!;
  }

  Future<RealizedExpense> recordLocalReject({
    required String expenseId,
    required String participantId,
    required String justification,
  }) async {
    final trimmed = justification.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Rejection justification is required');
    }
    final now = DateTime.now().toUtc();
    await (_db.update(_db.realizedExpenseAcceptances)
          ..where((t) => t.expenseId.equals(expenseId))
          ..where((t) => t.participantId.equals(participantId)))
        .write(
      RealizedExpenseAcceptancesCompanion(
        decision: drift.Value(RealizedExpenseDecision.rejected),
        decidedAt: drift.Value(now),
        rejectionJustification: drift.Value(trimmed),
      ),
    );
    await _recomputeExpenseStatus(expenseId, now: now);
    return (await getById(expenseId))!;
  }

  Future<RealizedExpense> applyPeerDecision({
    required String expenseId,
    required String participantId,
    required String decision,
    String? justification,
  }) async {
    final now = DateTime.now().toUtc();
    if (decision == RealizedExpenseDecision.accepted) {
      await (_db.update(_db.realizedExpenseAcceptances)
            ..where((t) => t.expenseId.equals(expenseId))
            ..where((t) => t.participantId.equals(participantId)))
          .write(
        RealizedExpenseAcceptancesCompanion(
          decision: drift.Value(RealizedExpenseDecision.accepted),
          decidedAt: drift.Value(now),
          rejectionJustification: const drift.Value(null),
        ),
      );
    } else if (decision == RealizedExpenseDecision.rejected) {
      final text = (justification ?? '').trim();
      await (_db.update(_db.realizedExpenseAcceptances)
            ..where((t) => t.expenseId.equals(expenseId))
            ..where((t) => t.participantId.equals(participantId)))
          .write(
        RealizedExpenseAcceptancesCompanion(
          decision: drift.Value(RealizedExpenseDecision.rejected),
          decidedAt: drift.Value(now),
          rejectionJustification: drift.Value(text.isEmpty ? '—' : text),
        ),
      );
    }
    await _recomputeExpenseStatus(expenseId, now: now);
    return (await getById(expenseId))!;
  }

  Future<RealizedExpense> createResubmitDraftFromRejected(
    String rejectedExpenseId,
  ) async {
    final row = await getById(rejectedExpenseId);
    if (row == null) {
      throw StateError('Expense not found: $rejectedExpenseId');
    }
    if (row.status != RealizedExpenseStatus.rejected) {
      throw StateError('Only rejected expenses can be resubmitted');
    }
    if (row.payerParticipantId !=
        selfParticipantIdForPlan(row.planId)) {
      throw StateError('Only the payer can resubmit this expense');
    }

    final newId = newExpenseId();
    final now = DateTime.now().toUtc();
    await _db.into(_db.realizedExpenses).insert(
          RealizedExpensesCompanion.insert(
            id: newId,
            packageId: row.packageId,
            planId: row.planId,
            planLineId: row.planLineId,
            status: RealizedExpenseStatus.draft,
            amountMinor: row.amountMinor,
            currency: row.currency,
            paymentDate: row.paymentDate,
            payerParticipantId: row.payerParticipantId,
            kind: row.kind,
            beneficiaryParticipantId: drift.Value(row.beneficiaryParticipantId),
            description: drift.Value(row.description),
            priorExpenseId: drift.Value(rejectedExpenseId),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final attachments = await attachmentsFor(rejectedExpenseId);
    for (final att in attachments) {
      if (att.filePath.isEmpty) continue;
      await _db.into(_db.realizedExpenseAttachments).insert(
            RealizedExpenseAttachmentsCompanion.insert(
              id: newAttachmentId(),
              expenseId: newId,
              filePath: att.filePath,
              displayFileName: att.displayFileName,
              contentHash: drift.Value(att.contentHash),
              createdAt: now,
            ),
          );
    }

    return (await getById(newId))!;
  }

  /// Inserts a published transfer without peer review (system ledger entry).
  Future<RealizedExpense> publishSystemTransfer({
    required String packageId,
    required String planId,
    required int amountMinor,
    required String currency,
    required DateTime paymentDate,
    required String payerParticipantId,
    required String beneficiaryParticipantId,
    String? description,
    String? expenseId,
  }) async {
    if (amountMinor == 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must not be zero');
    }
    final now = DateTime.now().toUtc();
    final id = expenseId ?? newExpenseId();
    await _db.into(_db.realizedExpenses).insertOnConflictUpdate(
          RealizedExpensesCompanion.insert(
            id: id,
            packageId: packageId,
            planId: planId,
            planLineId: '',
            status: RealizedExpenseStatus.published,
            amountMinor: amountMinor,
            currency: currency,
            paymentDate: paymentDate,
            payerParticipantId: payerParticipantId,
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: drift.Value(beneficiaryParticipantId),
            description: drift.Value(description?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final published = (await getById(id))!;
    await captureLineSnapshotForExpense(_db, published);
    return published;
  }

  Future<void> _recomputeExpenseStatus(
    String expenseId, {
    required DateTime now,
  }) async {
    final acceptances = await acceptancesFor(expenseId);
    if (acceptances.isEmpty) return;

    String nextStatus = RealizedExpenseStatus.proposed;
    if (acceptances.any((a) => a.decision == RealizedExpenseDecision.rejected)) {
      nextStatus = RealizedExpenseStatus.rejected;
    } else if (acceptances.every(
      (a) => a.decision == RealizedExpenseDecision.accepted,
    )) {
      nextStatus = RealizedExpenseStatus.published;
    }

    await (_db.update(_db.realizedExpenses)..where((t) => t.id.equals(expenseId)))
        .write(
      RealizedExpensesCompanion(
        status: drift.Value(nextStatus),
        updatedAt: drift.Value(now),
      ),
    );

    if (nextStatus == RealizedExpenseStatus.published) {
      final published = await getById(expenseId);
      if (published != null) {
        await captureLineSnapshotForExpense(_db, published);
      }
    }
  }
}

class RealizedExpenseAttachmentDraft {
  const RealizedExpenseAttachmentDraft({
    this.id,
    required this.filePath,
    required this.displayFileName,
    this.contentHash,
  });

  final String? id;
  final String filePath;
  final String displayFileName;
  final String? contentHash;
}
