import '../../db/app_database.dart';

/// Projection math for a plan + contract period.
///
/// Assumptions (v1):
/// - Recurring lines are monthly and multiply by the number of covered months
///   (inclusive of both start and end months).
/// - One-off lines use the midpoint of [minAmountMinor, maxAmountMinor].
/// - Null numeric values are treated as 0.
class PlanProjection {
  static int projectTotalMinor({
    required List<PlanLine> lines,
    required AgreementContract contract,
    int maxMonths = 120,
  }) {
    final months = monthsCoveredInclusive(contract.periodStart, contract.periodEnd)
        .clamp(0, maxMonths);

    var total = 0;
    for (final line in lines) {
      if (line.isRecurring) {
        total += (line.amountMinor ?? 0) * months;
      } else {
        final minV = line.minAmountMinor ?? 0;
        final maxV = line.maxAmountMinor ?? 0;
        total += ((minV + maxV) / 2).round();
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

