import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../debug/qa_date_range_picker_dialog.dart';
import '../prefs/app_preferences.dart';
import '../prefs/week_start.dart';

/// Locale passed to Material date pickers so column order matches [weekStart]
/// while keeping month/day names aligned with the app language when possible.
Locale calendarMaterialLocaleForWeekStart(Locale appLocale, WeekStart weekStart) {
  final lang = appLocale.languageCode;
  if (weekStart == WeekStart.monday) {
    return switch (lang) {
      'fr' => const Locale('fr'),
      'es' => const Locale('es'),
      'en' => const Locale('en', 'GB'),
      _ => const Locale('en', 'GB'),
    };
  }
  return switch (lang) {
    'fr' => const Locale('fr', 'CA'),
    'es' => const Locale('es', 'MX'),
    'en' => const Locale('en', 'US'),
    _ => const Locale('en', 'US'),
  };
}

/// Wraps [child] with Material localizations whose week starts on [weekStart].
Widget weekStartCalendarLocalizations({
  required BuildContext context,
  required AppPreferences prefs,
  required Widget child,
}) {
  final appLocale = Localizations.localeOf(context);
  final weekStart = prefs.resolveWeekStart(appLocale);
  final calLocale = calendarMaterialLocaleForWeekStart(appLocale, weekStart);
  return Localizations(
    locale: calLocale,
    delegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    child: child,
  );
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required AppPreferences prefs,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final appLocale = Localizations.localeOf(context);
  final weekStart = prefs.resolveWeekStart(appLocale);
  final calLocale = calendarMaterialLocaleForWeekStart(appLocale, weekStart);
  return showDatePicker(
    context: context,
    locale: calLocale,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (ctx, pickerChild) {
      if (pickerChild == null) return const SizedBox.shrink();
      return weekStartCalendarLocalizations(
        context: ctx,
        prefs: prefs,
        child: pickerChild,
      );
    },
  );
}

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required AppPreferences prefs,
  required DateTime firstDate,
  required DateTime lastDate,
  String? saveText,
}) {
  final first = DateUtils.dateOnly(firstDate);
  final last = DateUtils.dateOnly(lastDate);
  if (kDebugMode) {
    return showQaDateRangePickerDialog(
      context: context,
      prefs: prefs,
      firstDate: first,
      lastDate: last,
      saveText: saveText,
    );
  }
  final appLocale = Localizations.localeOf(context);
  final weekStart = prefs.resolveWeekStart(appLocale);
  final calLocale = calendarMaterialLocaleForWeekStart(appLocale, weekStart);
  return showDateRangePicker(
    context: context,
    locale: calLocale,
    firstDate: first,
    lastDate: last,
    saveText: saveText,
    builder: (ctx, pickerChild) {
      if (pickerChild == null) return const SizedBox.shrink();
      return weekStartCalendarLocalizations(
        context: ctx,
        prefs: prefs,
        child: pickerChild,
      );
    },
  );
}
