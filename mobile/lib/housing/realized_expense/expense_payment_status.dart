import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../projection/plan_projection.dart';
import 'expense_payment_chart_carry.dart';
import 'realized_expense_ledger_service.dart';
import 'realized_expense_participants.dart';
import 'realized_expense_status.dart';

/// One published payment row shown in the expense payment detail dialog.
final class ExpensePaymentRecord {
  const ExpensePaymentRecord({
    required this.amountMinor,
    required this.paymentDate,
    required this.payerDisplayName,
  });

  final int amountMinor;
  final DateTime paymentDate;
  final String payerDisplayName;
}

/// One vertical band in the payment-status chart.
final class ExpensePaymentStatusBar {
  const ExpensePaymentStatusBar({
    required this.letter,
    required this.lineId,
    required this.title,
    required this.totalMinor,
    required this.paidMinor,
    required this.color,
    required this.payments,
    required this.heightPixels,
  });

  final String letter;
  final String lineId;
  final String title;
  final int totalMinor;
  final int paidMinor;
  final Color color;
  final List<ExpensePaymentRecord> payments;

  /// Band height in logical pixels (scaled from flattened amounts).
  final double heightPixels;

  double get paidFraction =>
      totalMinor <= 0 ? 0.0 : paidMinor / totalMinor;
}

final class ExpensePaymentStatusData {
  const ExpensePaymentStatusData({
    required this.bars,
    required this.currency,
  });

  final List<ExpensePaymentStatusBar> bars;
  final String currency;
}

/// Exponent applied to each expense amount before band-height scaling.
const double expensePaymentBandFlattenExponent = 0.25;

/// Reference height in pixels for the largest flattened expense amount.
const double expensePaymentBandReferenceHeightPx = 100;

/// Step 1: flatten [amountMinor] with [expensePaymentBandFlattenExponent].
double expensePaymentFlattenedAmount(int amountMinor) {
  if (amountMinor <= 0) {
    return 0;
  }
  return math.pow(
    amountMinor.toDouble(),
    expensePaymentBandFlattenExponent,
  ).toDouble();
}

/// Step 2: band height in pixels for [amountMinor] given [maxFlattenedAmount].
double expensePaymentBandHeightPixels({
  required int amountMinor,
  required double maxFlattenedAmount,
  double referenceHeightPx = expensePaymentBandReferenceHeightPx,
}) {
  if (maxFlattenedAmount <= 0) {
    return 0;
  }
  final flattened = expensePaymentFlattenedAmount(amountMinor);
  return referenceHeightPx * flattened / maxFlattenedAmount;
}

Future<ExpensePaymentStatusData> loadExpensePaymentStatusData({
  required AppDatabase db,
  required RealizedExpenseLedgerService ledger,
  required String planId,
  required String packageId,
  required int year,
  required int month,
  required List<Color> palette,
  required String fallbackTitle,
}) async {
  final lines = await db.listPlanLines(planId);
  if (lines.isEmpty) {
    return ExpensePaymentStatusData(bars: const [], currency: '');
  }

  final roster = await participantsForPlan(db, planId);
  final published = await ledger.listPublishedForMonth(
    packageId: packageId,
    year: year,
    month: month,
  );
  final planPublished = published
      .where((e) => e.planId == planId)
      .toList(growable: false);

  final totals = <int>[];
  for (final line in lines) {
    totals.add(PlanProjection.monthlyChartUnitMinor(line));
  }
  final maxFlattened = totals.isEmpty
      ? 0.0
      : totals
            .map(expensePaymentFlattenedAmount)
            .reduce((a, b) => a > b ? a : b);

  final bars = <ExpensePaymentStatusBar>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final totalMinor = PlanProjection.monthlyChartUnitMinor(line);
    final linePayments = planPublished
        .where(
          (e) =>
              e.planLineId == line.id &&
              RealizedExpenseKind.usesPlanLine(e.kind),
        )
        .toList(growable: false)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final paidMinor = await expensePaymentChartPaidMinor(
      ledger: ledger,
      packageId: packageId,
      planId: planId,
      planLineId: line.id,
      year: year,
      month: month,
    );
    final title = line.title.trim().isEmpty ? fallbackTitle : line.title.trim();

    bars.add(
      ExpensePaymentStatusBar(
        letter: String.fromCharCode(65 + i),
        lineId: line.id,
        title: title,
        totalMinor: totalMinor,
        paidMinor: paidMinor,
        color: palette[i % palette.length],
        heightPixels: expensePaymentBandHeightPixels(
          amountMinor: totalMinor,
          maxFlattenedAmount: maxFlattened,
        ),
        payments: [
          for (final expense in linePayments)
            ExpensePaymentRecord(
              amountMinor: expense.amountMinor,
              paymentDate: expense.paymentDate,
              payerDisplayName: displayNameForParticipant(
                expense.payerParticipantId,
                roster,
              ),
            ),
        ],
      ),
    );
  }

  final currency = lines.first.currency;
  return ExpensePaymentStatusData(bars: bars, currency: currency);
}
