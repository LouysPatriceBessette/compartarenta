import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_ledger_service.dart';
import 'housing_settlement_window.dart';

/// Inclusive first/last calendar months for monthly housing summaries.
class HousingAgreementMonthWindow {
  const HousingAgreementMonthWindow({
    required this.firstMonth,
    required this.lastMonth,
  });

  final DateTime firstMonth;
  final DateTime lastMonth;

  DateTime clamp(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (normalized.isBefore(firstMonth)) return firstMonth;
    if (normalized.isAfter(lastMonth)) return lastMonth;
    return normalized;
  }

  /// Month bounds from agreement dates and optional settlement-open extension.
  static HousingAgreementMonthWindow fromAgreement(
    Agreement agreement, {
    bool settlementOpen = false,
  }) {
    final startMonth = DateTime(
      agreement.periodStart.year,
      agreement.periodStart.month,
    );
    final endMonth = DateTime(
      agreement.periodEnd.year,
      agreement.periodEnd.month,
    );
    final monthEnd = DateTime(
      agreement.periodEnd.year,
      agreement.periodEnd.month + 1,
      0,
    );
    final endDay = DateUtils.dateOnly(agreement.periodEnd.toLocal());
    final extendToNextMonth =
        monthEnd.difference(endDay).inDays.abs() <= 5;
    var lastMonth = extendToNextMonth
        ? DateTime(agreement.periodEnd.year, agreement.periodEnd.month + 1)
        : endMonth;
    if (settlementOpen) {
      final settlementEnd = settlementWindowLastDayInclusive(
        agreement.periodEnd,
      );
      final settlementMonth = DateTime(
        settlementEnd.year,
        settlementEnd.month,
      );
      if (settlementMonth.isAfter(lastMonth)) {
        lastMonth = settlementMonth;
      }
    }
    return HousingAgreementMonthWindow(
      firstMonth: startMonth,
      lastMonth: lastMonth,
    );
  }

  /// Loads month window for [planId], including settlement-month visibility.
  static Future<HousingAgreementMonthWindow?> forPlan(
    AppDatabase db,
    String planId,
  ) async {
    final agreement = await db.getAgreementForPlan(planId);
    if (agreement == null) return null;
    final ledger = RealizedExpenseLedgerService(db);
    final hasNonZero = await ledger.hasNonZeroOptimizedBalances(planId);
    final settlementOpen = isSettlementOpen(
      agreement: agreement,
      hasNonZeroOptimizedBalances: hasNonZero,
    );
    return fromAgreement(agreement, settlementOpen: settlementOpen);
  }
}
