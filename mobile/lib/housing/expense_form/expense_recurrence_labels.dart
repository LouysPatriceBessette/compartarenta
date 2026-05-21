import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import 'expense_recurrence_spec.dart';

/// `YYYY-MM-DD` from a local calendar date (no time suffix).
String calendarDateIso(DateTime date) {
  final d = DateUtils.dateOnly(date);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String formatRecurrenceAnchorIso(String anchorIso, String dateFormat) {
  final fmt = dateFormat.trim().isEmpty ? 'YYYY-MM-DD' : dateFormat.trim();
  final raw = anchorIso.split('T').first;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return formatPreferenceDate(parsed.toUtc(), fmt);
}

/// User-facing one-line summary for the expense form recurrence tile.
String formatRecurrenceSpecSummary(
  AppLocalizations l10n,
  String dateFormat,
  ExpenseRecurrenceSpec spec,
) {
  final anchor = switch (spec) {
    MonthlyDayRecurrence(:final anchorIso) => anchorIso,
    EveryNDaysRecurrence(:final anchorIso) => anchorIso,
    NthWeekdayRecurrence(:final anchorIso) => anchorIso,
  };
  final anchorDisplay = anchor == null || anchor.isEmpty
      ? ''
      : formatRecurrenceAnchorIso(anchor, dateFormat);
  return switch (spec) {
    MonthlyDayRecurrence(:final day) =>
      l10n.housingExpenseRecurrenceMonthlyDay(day, anchorDisplay),
    EveryNDaysRecurrence(:final n, :final anchorIso) =>
      l10n.housingExpenseRecurrenceEveryNDays(
        n,
        formatRecurrenceAnchorIso(anchorIso, dateFormat),
      ),
    NthWeekdayRecurrence(:final ordinal, :final weekday, :final anchorIso) =>
      l10n.housingExpenseRecurrenceNthWeekdayOfMonth(
        recurrenceOrdinalLabel(l10n, ordinal),
        recurrenceWeekdayLabel(l10n, weekday),
        formatRecurrenceAnchorIso(anchorIso, dateFormat),
      ),
  };
}

/// Inclusive calendar day count (start and end dates both count).
int inclusiveCalendarDayCount(DateTime start, DateTime end) {
  final s = DateUtils.dateOnly(start);
  final e = DateUtils.dateOnly(end);
  return e.difference(s).inDays + 1;
}

/// 1 = first occurrence of [weekday] in the month, 2 = second, etc.
int ordinalOfWeekdayInMonth(DateTime date) {
  return ((date.day - 1) ~/ 7) + 1;
}

String recurrenceOrdinalLabel(AppLocalizations l10n, int ordinal) {
  switch (ordinal) {
    case 1:
      return l10n.housingRecurrenceOrdinalFirst;
    case 2:
      return l10n.housingRecurrenceOrdinalSecond;
    case 3:
      return l10n.housingRecurrenceOrdinalThird;
    case 4:
      return l10n.housingRecurrenceOrdinalFourth;
    case 5:
      return l10n.housingRecurrenceOrdinalFifth;
    default:
      return l10n.housingRecurrenceOrdinalFifth;
  }
}

/// [weekday] is [DateTime.weekday] (1 = Monday … 7 = Sunday).
String recurrenceWeekdayLabel(AppLocalizations l10n, int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.housingRecurrenceWeekdayMonday;
    case DateTime.tuesday:
      return l10n.housingRecurrenceWeekdayTuesday;
    case DateTime.wednesday:
      return l10n.housingRecurrenceWeekdayWednesday;
    case DateTime.thursday:
      return l10n.housingRecurrenceWeekdayThursday;
    case DateTime.friday:
      return l10n.housingRecurrenceWeekdayFriday;
    case DateTime.saturday:
      return l10n.housingRecurrenceWeekdaySaturday;
    case DateTime.sunday:
      return l10n.housingRecurrenceWeekdaySunday;
    default:
      return l10n.housingRecurrenceWeekdayMonday;
  }
}

String recurrenceNthWeekdayOfMonthLabel(
  AppLocalizations l10n, {
  required DateTime anchorDate,
  required String anchorIso,
  required String dateFormat,
}) {
  final ordinal = ordinalOfWeekdayInMonth(anchorDate);
  return l10n.housingExpenseRecurrenceNthWeekdayOfMonth(
    recurrenceOrdinalLabel(l10n, ordinal),
    recurrenceWeekdayLabel(l10n, anchorDate.weekday),
    formatRecurrenceAnchorIso(anchorIso, dateFormat),
  );
}
