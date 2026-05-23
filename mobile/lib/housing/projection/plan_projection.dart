import '../../db/app_database.dart';
import '../expense_form/expense_recurrence_spec.dart';

/// Projection math for a plan + agreement period.
///
/// Assumptions (v1):
/// - Recurring lines are monthly and multiply by the number of covered months
///   (inclusive of both start and end months).
/// - [PlanLine.amountMinor] is the unit amount (fixed or budget cap high estimate).
/// - Legacy [amountUsesRange] with min/max: still uses midpoint until rows are migrated.
/// - Null numeric values are treated as 0.
class PlanProjection {
  /// Arbitrary month length for sunburst / monthly summary normalization.
  static const int nominalMonthDays = 30;

  /// Recurrence periods in this inclusive band are treated as ~one month.
  static const int monthPerceptionMinDays = 27;
  static const int monthPerceptionMaxDays = 33;

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

  /// Recurrence period in days for [line], or null when not recurring.
  static int? recurrencePeriodDays(PlanLine line) {
    if (!line.isRecurring) return null;
    final spec =
        ExpenseRecurrenceSpec.parseStored(line.recurrenceSpecJson) ??
        ExpenseRecurrenceSpec.fromLegacyDayOfMonth(line.recurrenceDayOfMonth);
    return switch (spec) {
      null => nominalMonthDays,
      MonthlyDayRecurrence() => nominalMonthDays,
      EveryNDaysRecurrence(:final n) => n.clamp(1, 999999),
      NthWeekdayRecurrence() => nominalMonthDays,
    };
  }

  /// True when [periodDays] is far enough from a calendar month to normalize.
  static bool shouldNormalizeToNominalMonth(int periodDays) =>
      periodDays < monthPerceptionMinDays ||
      periodDays > monthPerceptionMaxDays;

  /// Whether the monthly chart should scale this line to a 30-day month.
  static bool isMonthlyChartNormalized(PlanLine line) {
    final period = recurrencePeriodDays(line);
    if (period == null) return false;
    return shouldNormalizeToNominalMonth(period);
  }

  /// Unit amount for the monthly sunburst and participant monthly totals only.
  ///
  /// Recurring lines with period &lt; 27 or &gt; 33 days:
  /// `unitMinor × 30 / periodDays`. Other recurring lines and one-offs keep
  /// [unitMinor].
  static int monthlyChartUnitMinor(PlanLine line) {
    final unit = unitMinor(line);
    final period = recurrencePeriodDays(line);
    if (period == null || !shouldNormalizeToNominalMonth(period)) {
      return unit;
    }
    return ((unit * nominalMonthDays) / period).round();
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
