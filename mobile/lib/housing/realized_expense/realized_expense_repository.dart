import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
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
    String? existingExpenseId,
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
