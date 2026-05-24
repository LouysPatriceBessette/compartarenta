import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import '../../prefs/app_preferences.dart';
import 'realized_expense_balance.dart';
import 'realized_expense_participants.dart';
import 'realized_expense_repository.dart';
import 'realized_expense_status.dart';

/// Review visibility for the local participant.
enum RealizedExpenseReviewVisibility {
  waitingForYou,
  waitingForOthers,
  published,
  rejected,
}

class RealizedExpenseReviewItem {
  const RealizedExpenseReviewItem({
    required this.expense,
    required this.visibility,
  });

  final RealizedExpense expense;
  final RealizedExpenseReviewVisibility visibility;
}

/// Ledger queries and balance helpers (pass 3).
class RealizedExpenseLedgerService {
  RealizedExpenseLedgerService(this._db);

  final AppDatabase _db;

  String selfIdForPlan(String planId) => selfParticipantIdForPlan(planId);

  Future<RealizedExpenseReviewVisibility> visibilityFor({
    required RealizedExpense expense,
    required String selfParticipantId,
  }) async {
    await RealizedExpenseRepository(_db).ensurePayerAcceptedIfPending(expense);
    final current = await RealizedExpenseRepository(_db).getById(expense.id);
    final row = current ?? expense;

    if (row.status == RealizedExpenseStatus.published) {
      return RealizedExpenseReviewVisibility.published;
    }
    if (row.status == RealizedExpenseStatus.rejected) {
      return RealizedExpenseReviewVisibility.rejected;
    }
    if (row.status == RealizedExpenseStatus.draft) {
      return RealizedExpenseReviewVisibility.waitingForOthers;
    }

    // The submitter does not review their own proposal.
    if (row.payerParticipantId == selfParticipantId) {
      return RealizedExpenseReviewVisibility.waitingForOthers;
    }

    final acceptances = await RealizedExpenseRepository(_db)
        .acceptancesFor(row.id);
    String? mine;
    for (final a in acceptances) {
      if (a.participantId == selfParticipantId) {
        mine = a.decision;
        break;
      }
    }
    if (mine == RealizedExpenseDecision.rejected) {
      return RealizedExpenseReviewVisibility.rejected;
    }
    if (mine == RealizedExpenseDecision.pending) {
      return RealizedExpenseReviewVisibility.waitingForYou;
    }
    if (acceptances.any((a) => a.decision == RealizedExpenseDecision.pending)) {
      return RealizedExpenseReviewVisibility.waitingForOthers;
    }
    if (acceptances.every((a) => a.decision == RealizedExpenseDecision.accepted)) {
      return RealizedExpenseReviewVisibility.published;
    }
    return RealizedExpenseReviewVisibility.waitingForOthers;
  }

  Future<List<RealizedExpenseReviewItem>> listReviewItems({
    required String packageId,
    required String planId,
  }) async {
    final selfId = selfIdForPlan(planId);
    final rows = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.packageId.equals(packageId))
          ..where(
            (t) => t.status.isIn([
              RealizedExpenseStatus.proposed,
              RealizedExpenseStatus.published,
              RealizedExpenseStatus.rejected,
            ]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    final out = <RealizedExpenseReviewItem>[];
    for (final expense in rows) {
      final visibility = await visibilityFor(
        expense: expense,
        selfParticipantId: selfId,
      );
      out.add(RealizedExpenseReviewItem(expense: expense, visibility: visibility));
    }
    return out;
  }

  Future<int> countWaitingForYou({
    required String packageId,
    required String planId,
  }) async {
    final items = await listReviewItems(packageId: packageId, planId: planId);
    return items
        .where(
          (i) => i.visibility == RealizedExpenseReviewVisibility.waitingForYou,
        )
        .length;
  }

  Future<List<RealizedExpense>> listPublishedForMonth({
    required String packageId,
    required int year,
    required int month,
  }) async {
    final start = DateTime.utc(year, month, 1);
    final end = month == 12
        ? DateTime.utc(year + 1, 1, 1)
        : DateTime.utc(year, month + 1, 1);
    final rows = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.packageId.equals(packageId))
          ..where((t) => t.status.equals(RealizedExpenseStatus.published))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
    return rows.where((e) {
      final d = e.paymentDate.toUtc();
      return !d.isBefore(start) && d.isBefore(end);
    }).toList(growable: false);
  }

  Future<int> sumPublishedMinorForLineMonth({
    required String packageId,
    required String planId,
    required String planLineId,
    required int year,
    required int month,
  }) async {
    final published = await listPublishedForMonth(
      packageId: packageId,
      year: year,
      month: month,
    );
    return published
        .where((e) => e.planId == planId && e.planLineId == planLineId)
        .fold<int>(0, (sum, e) => sum + e.amountMinor);
  }

  Future<List<PairwiseBalanceEntry>> pairwiseBalancesForPlan(
    String planId,
  ) async {
    final roster = await participantsForPlan(_db, planId);
    final participantIds = roster.map((p) => p.id).toList(growable: false);
    final published = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.planId.equals(planId))
          ..where((t) => t.status.equals(RealizedExpenseStatus.published)))
        .get();
    final ratios = await _db.listPlanRatios(planId);
    return computePairwiseBalances(
      publishedExpenses: published,
      planRatios: ratios,
      participantIds: participantIds,
    );
  }

  Future<void> markPlanActiveUseIfNeeded(String planId) async {
    final prefs = await AppPreferences.load();
    await prefs.markHousingPlanActiveUseStarted(planId);
  }
}
