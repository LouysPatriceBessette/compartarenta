import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_status.dart';

/// Task 4.5 — agreement start date is immutable after published expense history.
Future<bool> planHasPublishedRealizedExpense(
  AppDatabase db,
  String planId,
) async {
  // Existence only: a plan may have many published expenses (cumulative QA).
  // Do not use getSingleOrNull — that throws Bad state: Too many elements.
  final rows = await (db.select(db.realizedExpenses)
        ..where((t) => t.planId.equals(planId))
        ..where((t) => t.status.equals(RealizedExpenseStatus.published))
        ..limit(1))
      .get();
  return rows.isNotEmpty;
}

bool agreementStartDateWouldChange({
  required DateTime existingStart,
  required DateTime proposedStart,
}) {
  final existing = DateUtils.dateOnly(existingStart.toLocal());
  final proposed = DateUtils.dateOnly(proposedStart.toLocal());
  return existing != proposed;
}

Future<bool> blocksAgreementStartDateChange({
  required AppDatabase db,
  required String planId,
  required DateTime? existingStart,
  required DateTime proposedStart,
}) async {
  if (existingStart == null) return false;
  if (!await planHasPublishedRealizedExpense(db, planId)) return false;
  return agreementStartDateWouldChange(
    existingStart: existingStart,
    proposedStart: proposedStart,
  );
}
