import 'package:flutter/material.dart';

/// User preference for which weekday column comes first in week grids and pickers.
enum WeekStart {
  sunday,
  monday,
}

/// Material [MaterialLocalizations.firstDayOfWeekIndex]: 0 = Sunday … 6 = Saturday.
int firstDayOfWeekIndexFor(WeekStart weekStart) {
  return switch (weekStart) {
    WeekStart.sunday => 0,
    WeekStart.monday => 1,
  };
}

/// Default when the user has not chosen yet (locale heuristics, not CLDR-perfect).
WeekStart defaultWeekStartForLocale(Locale locale) {
  final country = locale.countryCode?.toUpperCase();
  if (country == 'US' || country == 'CA' || country == 'MX' || country == 'BR') {
    return WeekStart.sunday;
  }
  if (country == 'GB' || country == 'AU') {
    return WeekStart.monday;
  }
  return switch (locale.languageCode) {
    'fr' || 'de' || 'es' || 'it' => WeekStart.monday,
    _ => WeekStart.sunday,
  };
}

WeekStart? weekStartFromStored(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final w in WeekStart.values) {
    if (w.name == raw) return w;
  }
  return null;
}
