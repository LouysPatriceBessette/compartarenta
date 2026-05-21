import '../../db/app_database.dart';

/// Projection math for a plan + agreement period.
///
/// Assumptions (v1):
/// - Recurring lines are monthly and multiply by the number of covered months
///   (inclusive of both start and end months).
/// - [PlanLine.amountMinor] is the unit amount (fixed or budget cap high estimate).
/// - Legacy [amountUsesRange] with min/max: still uses midpoint until rows are migrated.
/// - Null numeric values are treated as 0.
class PlanProjection {
  /// Single period amount in minor units (one month for recurring, total for one-off).
  static int unitMinor(PlanLine line) {
    if (line.amountIsBudgetCap) {
      return line.amountMinor ?? 0;
    }
    if (line.amountUsesRange) {
      final minV = line.minAmountMinor ?? 0;
      final maxV = line.maxAmountMinor ?? 0;
      return ((minV + maxV) / 2).round();
    }
    return line.amountMinor ?? 0;
  }

  static int projectTotalMinor({
    required List<PlanLine> lines,
    required Agreement agreement,
    int maxMonths = 120,
  }) {
    final months = monthsCoveredInclusive(agreement.periodStart, agreement.periodEnd)
        .clamp(0, maxMonths);

    var total = 0;
    for (final line in lines) {
      final u = unitMinor(line);
      if (line.isRecurring) {
        total += u * months;
      } else {
        total += u;
      }
    }
    return total;
  }

  /// Number of months covered, inclusive of both endpoints’ months.
  ///
  /// Example: 2026-05-01 → 2026-05-31 => 1
  /// Example: 2026-05-15 → 2026-06-01 => 2
  static int monthsCoveredInclusive(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month);
    final b = DateTime(end.year, end.month);
    return (b.year - a.year) * 12 + (b.month - a.month) + 1;
  }
}
