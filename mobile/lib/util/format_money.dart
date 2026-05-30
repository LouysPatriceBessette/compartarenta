import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';

/// Prefer [AppPreferences.currency] when set; otherwise first plan line's currency.
String displayCurrencyCodeForPlan(AppPreferences prefs, List<PlanLine> lines) {
  final p = prefs.currency.trim();
  if (p.isNotEmpty) return p;
  if (lines.isEmpty) return '';
  return lines.first.currency.trim();
}

/// Formats [minor] (e.g. cents) as money using ISO 4217 [currencyCode].
/// If [currencyCode] is empty, formats as a plain decimal number.
String formatMinorAsMoney(BuildContext context, int minor, String currencyCode) {
  final localeName = Localizations.localeOf(context).toString();
  final code = currencyCode.trim();
  if (code.isEmpty) {
    return NumberFormat('#,##0.00', localeName).format(minor / 100.0);
  }
  return NumberFormat.simpleCurrency(locale: localeName, name: code).format(minor / 100.0);
}

/// Same as [formatMinorAsMoney] but [major] is in currency major units (e.g. dollars).
String formatMajorDoubleAsMoney(BuildContext context, double major, String currencyCode) {
  return formatMinorAsMoney(context, (major * 100).round(), currencyCode);
}

/// Locale-aware money label without a [BuildContext] (e.g. journal list subjects).
String formatMinorAsMoneyForLocale(
  String localeName,
  int minor,
  String currencyCode,
) {
  final code = currencyCode.trim();
  if (code.isEmpty) {
    return NumberFormat('#,##0.00', localeName).format(minor / 100.0);
  }
  return NumberFormat.simpleCurrency(locale: localeName, name: code)
      .format(minor / 100.0);
}
