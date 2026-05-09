import 'package:flutter/material.dart';

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
