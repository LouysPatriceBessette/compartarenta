import 'dart:convert';

/// Normalized recurrence for a recurring expense line.
sealed class ExpenseRecurrenceSpec {
  const ExpenseRecurrenceSpec();

  Map<String, Object?> toJson();

  static ExpenseRecurrenceSpec? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final kind = json['kind'];
    if (kind == 'monthlyDay') {
      final day = json['day'];
      if (day is! num) return null;
      return MonthlyDayRecurrence(
        day: day.toInt(),
        anchorIso: json['anchor'] as String?,
      );
    }
    if (kind == 'everyNDays') {
      final n = json['n'];
      if (n is! num) return null;
      return EveryNDaysRecurrence(
        n: n.toInt(),
        anchorIso: json['anchor'] as String? ?? '',
      );
    }
    if (kind == 'nthWeekday') {
      final ordinal = json['ordinal'];
      final weekday = json['weekday'];
      if (ordinal is! num || weekday is! num) return null;
      return NthWeekdayRecurrence(
        ordinal: ordinal.toInt(),
        weekday: weekday.toInt(),
        anchorIso: json['anchor'] as String? ?? '',
      );
    }
    return null;
  }

  static ExpenseRecurrenceSpec? parseStored(String jsonText) {
    if (jsonText.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;
      return fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static String encode(ExpenseRecurrenceSpec spec) => jsonEncode(spec.toJson());

  /// Best-effort from legacy [recurrenceDayOfMonth] only.
  static ExpenseRecurrenceSpec? fromLegacyDayOfMonth(int? day) {
    if (day == null || day < 1 || day > 31) return null;
    return MonthlyDayRecurrence(day: day);
  }
}

final class MonthlyDayRecurrence extends ExpenseRecurrenceSpec {
  const MonthlyDayRecurrence({required this.day, this.anchorIso});

  final int day;
  final String? anchorIso;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'monthlyDay',
    'day': day,
    if (anchorIso != null && anchorIso!.isNotEmpty) 'anchor': anchorIso,
  };
}

final class EveryNDaysRecurrence extends ExpenseRecurrenceSpec {
  const EveryNDaysRecurrence({required this.n, required this.anchorIso});

  final int n;
  final String anchorIso;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'everyNDays',
    'n': n,
    'anchor': anchorIso,
  };
}

final class NthWeekdayRecurrence extends ExpenseRecurrenceSpec {
  const NthWeekdayRecurrence({
    required this.ordinal,
    required this.weekday,
    required this.anchorIso,
  });

  /// 1 = first, …, 5 = last (product convention).
  final int ordinal;
  /// 1 = Monday … 7 = Sunday (DateTime.weekday).
  final int weekday;
  final String anchorIso;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'nthWeekday',
    'ordinal': ordinal,
    'weekday': weekday,
    'anchor': anchorIso,
  };
}
