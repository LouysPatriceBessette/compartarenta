import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Formats a stored instant as a **calendar date** in the user's locale,
/// following the same pattern strings as onboarding (`YYYY-MM-DD`, etc.).
String formatPreferenceDate(DateTime? utc, String format) {
  if (utc == null) return '—';
  final d = DateUtils.dateOnly(utc.toLocal());
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  switch (format) {
    case 'DD/MM/YYYY':
      return '$day/$m/$y';
    case 'MM/DD/YYYY':
      return '$m/$day/$y';
    case 'YYYY-MM-DD':
    default:
      return '$y-$m-$day';
  }
}

bool isStrictlyBeforeCalendarDate(DateTime a, DateTime b) {
  final da = DateUtils.dateOnly(a.toLocal());
  final db = DateUtils.dateOnly(b.toLocal());
  return da.isBefore(db);
}

/// Inclusive calendar span from [startUtc] to [endUtc] (local dates), e.g. "7 months, 2 days".
String formatContractCalendarDuration(
  DateTime? startUtc,
  DateTime? endUtc,
  AppLocalizations l10n,
) {
  if (startUtc == null || endUtc == null) return '';
  final s = DateUtils.dateOnly(startUtc.toLocal());
  final e = DateUtils.dateOnly(endUtc.toLocal());
  if (!e.isAfter(s)) return '';
  var months = 0;
  var cur = DateTime(s.year, s.month, s.day);
  while (true) {
    final nxt = DateTime(cur.year, cur.month + 1, cur.day);
    if (nxt.isAfter(e)) break;
    months++;
    cur = nxt;
  }
  var days = e.difference(cur).inDays;
  if (days < 0) days = 0;
  final parts = <String>[];
  if (months > 0) {
    parts.add(l10n.housingPlanDurationMonthsCount(months));
  }
  if (days > 0) {
    parts.add(l10n.housingPlanDurationDaysCount(days));
  }
  if (parts.isEmpty) {
    parts.add(l10n.housingPlanDurationDaysCount(0));
  }
  return parts.join(', ');
}
