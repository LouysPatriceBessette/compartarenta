import '../../db/app_database.dart';
import '../expense_form/expense_recurrence_spec.dart';
import '../projection/plan_projection.dart';
import '../realized_expense/realized_expense_ledger_service.dart';

/// One sliding recurrence window for payment coverage.
final class SlidingPaymentPeriod {
  const SlidingPaymentPeriod({
    required this.periodKey,
    required this.startUtc,
    required this.endUtcExclusive,
    required this.dueAtUtc,
    required this.windowDays,
  });

  /// Stable opaque key for relay scheduling (UTF-8 period start millis).
  final String periodKey;
  final DateTime startUtc;
  final DateTime endUtcExclusive;
  final DateTime dueAtUtc;
  final int windowDays;
}

/// Encodes `planId` + `lineId` for relay `scope_key` bytes.
List<int> housingReminderScopeKeyBytes(String planId, String lineId) {
  final planBytes = planId.codeUnits;
  final lineBytes = lineId.codeUnits;
  return [...planBytes, 0x1f, ...lineBytes];
}

String housingReminderPeriodKey(SlidingPaymentPeriod period) =>
    period.periodKey;

/// Returns the sliding period containing [atUtc] for [line].
SlidingPaymentPeriod? slidingPeriodContaining({
  required PlanLine line,
  required DateTime atUtc,
}) {
  if (!line.isRecurring || line.amountIsBudgetCap) return null;
  final windowDays = PlanProjection.recurrencePeriodDays(line);
  if (windowDays == null || windowDays <= 0) return null;

  final spec =
      ExpenseRecurrenceSpec.parseStored(line.recurrenceSpecJson) ??
      ExpenseRecurrenceSpec.fromLegacyDayOfMonth(line.recurrenceDayOfMonth);

  return switch (spec) {
    EveryNDaysRecurrence(:final n, :final anchorIso) =>
      _everyNDaysPeriod(n: n, anchorIso: anchorIso, atUtc: atUtc),
    MonthlyDayRecurrence(:final day) =>
      _monthlyDayPeriod(day: day, atUtc: atUtc, windowDays: windowDays),
    NthWeekdayRecurrence() =>
      _monthlyDayPeriod(day: 1, atUtc: atUtc, windowDays: windowDays),
    null =>
      _monthlyDayPeriod(day: 1, atUtc: atUtc, windowDays: windowDays),
  };
}

SlidingPaymentPeriod _everyNDaysPeriod({
  required int n,
  required String anchorIso,
  required DateTime atUtc,
}) {
  final anchor = DateTime.tryParse(anchorIso)?.toUtc() ??
      DateTime.utc(atUtc.year, atUtc.month, atUtc.day);
  final deltaDays = atUtc.difference(anchor).inDays;
  final k = deltaDays < 0 ? (deltaDays - n + 1) ~/ n : deltaDays ~/ n;
  final start = anchor.add(Duration(days: k * n));
  final end = start.add(Duration(days: n));
  return SlidingPaymentPeriod(
    periodKey: '${start.millisecondsSinceEpoch}',
    startUtc: start,
    endUtcExclusive: end,
    dueAtUtc: end,
    windowDays: n,
  );
}

SlidingPaymentPeriod _monthlyDayPeriod({
  required int day,
  required DateTime atUtc,
  required int windowDays,
}) {
  final local = atUtc.toLocal();
  var y = local.year;
  var m = local.month;
  final clampedDay = day.clamp(1, 28);
  var periodStart = DateTime(y, m, clampedDay);
  if (local.isBefore(periodStart)) {
    if (m == 1) {
      y -= 1;
      m = 12;
    } else {
      m -= 1;
    }
    periodStart = DateTime(y, m, clampedDay);
  }
  final nextStart = m == 12
      ? DateTime(y + 1, 1, clampedDay)
      : DateTime(y, m + 1, clampedDay);
  final startUtc = periodStart.toUtc();
  final endUtc = nextStart.toUtc();
  return SlidingPaymentPeriod(
    periodKey: '${startUtc.millisecondsSinceEpoch}',
    startUtc: startUtc,
    endUtcExclusive: endUtc,
    dueAtUtc: endUtc,
    windowDays: windowDays,
  );
}

/// Next period after [period], or null when [agreementEnd] is before due.
SlidingPaymentPeriod? nextSlidingPeriod({
  required PlanLine line,
  required SlidingPaymentPeriod period,
  DateTime? agreementEnd,
}) {
  final next = slidingPeriodContaining(
    line: line,
    atUtc: period.endUtcExclusive.add(const Duration(seconds: 1)),
  );
  if (next == null) return null;
  if (agreementEnd != null && next.dueAtUtc.isAfter(agreementEnd)) {
    return null;
  }
  return next;
}

final class PaymentPeriodCoverage {
  const PaymentPeriodCoverage({
    required this.requiredMinor,
    required this.attributedPaidMinor,
    required this.carryInMinor,
    required this.carryOutMinor,
  });

  final int requiredMinor;
  final int attributedPaidMinor;
  final int carryInMinor;
  final int carryOutMinor;

  bool get isFullyCovered => attributedPaidMinor >= requiredMinor;
}

int _expenseAttributedMinor(RealizedExpense expense) {
  final carry = expense.paymentChartCarryForwardMinor;
  if (carry <= 0) return expense.amountMinor;
  return (expense.amountMinor - carry).clamp(0, expense.amountMinor);
}

/// Coverage for [line] in [period] using published expenses on [ledger].
Future<PaymentPeriodCoverage> paymentPeriodCoverage({
  required RealizedExpenseLedgerService ledger,
  required String packageId,
  required String planId,
  required PlanLine line,
  required SlidingPaymentPeriod period,
  SlidingPaymentPeriod? previousPeriod,
}) async {
  final requiredMinor = PlanProjection.unitMinor(line);
  var carryIn = 0;
  if (previousPeriod != null) {
    carryIn = await _carryOutFromPreviousPeriod(
      ledger: ledger,
      packageId: packageId,
      planId: planId,
      planLineId: line.id,
      previousPeriod: previousPeriod,
      requiredMinor: requiredMinor,
    );
  }

  final published = await ledger.listPublishedForPlanLine(
    packageId: packageId,
    planId: planId,
    planLineId: line.id,
  );
  var attributed = carryIn;
  for (final e in published) {
    final payUtc = e.paymentDate.toUtc();
    if (!payUtc.isBefore(period.endUtcExclusive) ||
        payUtc.isBefore(period.startUtc)) {
      continue;
    }
    attributed += _expenseAttributedMinor(e);
  }
  final carryOut = attributed > requiredMinor ? attributed - requiredMinor : 0;
  return PaymentPeriodCoverage(
    requiredMinor: requiredMinor,
    attributedPaidMinor: attributed,
    carryInMinor: carryIn,
    carryOutMinor: carryOut,
  );
}

Future<int> _carryOutFromPreviousPeriod({
  required RealizedExpenseLedgerService ledger,
  required String packageId,
  required String planId,
  required String planLineId,
  required SlidingPaymentPeriod previousPeriod,
  required int requiredMinor,
}) async {
  final published = await ledger.listPublishedForPlanLine(
    packageId: packageId,
    planId: planId,
    planLineId: planLineId,
  );
  var attributed = 0;
  for (final e in published) {
    final payUtc = e.paymentDate.toUtc();
    if (!payUtc.isBefore(previousPeriod.endUtcExclusive) ||
        payUtc.isBefore(previousPeriod.startUtc)) {
      continue;
    }
    attributed += _expenseAttributedMinor(e);
  }
  if (attributed <= requiredMinor) return 0;
  var deferred = 0;
  for (final e in published) {
    final payUtc = e.paymentDate.toUtc();
    if (!payUtc.isBefore(previousPeriod.endUtcExclusive) ||
        payUtc.isBefore(previousPeriod.startUtc)) {
      continue;
    }
    deferred += e.paymentChartCarryForwardMinor;
  }
  return deferred > 0 ? deferred : (attributed - requiredMinor);
}
