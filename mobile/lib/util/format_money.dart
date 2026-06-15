import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';
import '../prefs/regional_unit_choices.dart';

/// ISO code for persistence and relay payloads; not shown in UI (v1 uses [kDefaultCurrencyCode] only).
String resolveStorageCurrencyCode(String currencyCode) {
  final code = currencyCode.trim();
  if (code.isEmpty) return kDefaultCurrencyCode;
  return code;
}

/// User-visible currency symbol. Never returns an ISO 4217 code.
String currencyDisplaySymbol(BuildContext context, String currencyCode) {
  final code = resolveStorageCurrencyCode(currencyCode);
  if (code == kDefaultCurrencyCode) return r'$';
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.simpleCurrency(locale: localeName, name: code)
      .currencySymbol;
}

/// Prefer [AppPreferences.currency] when set; otherwise first plan line's currency.
String displayCurrencyCodeForPlan(AppPreferences prefs, List<PlanLine> lines) {
  final p = prefs.currency.trim();
  if (p.isNotEmpty) return p;
  if (lines.isEmpty) return kDefaultCurrencyCode;
  final fromLine = lines.first.currency.trim();
  return fromLine.isEmpty ? kDefaultCurrencyCode : fromLine;
}

String _formatMinorWithSymbol(String localeName, int minor, String symbol) {
  return NumberFormat.currency(
    locale: localeName,
    symbol: symbol,
    decimalDigits: 2,
  ).format(minor / 100.0);
}

/// Formats [minor] (e.g. cents) as money using ISO 4217 [currencyCode] internally.
/// v1 display uses [currencyDisplaySymbol] for the default currency (never "CAD").
String formatMinorAsMoney(BuildContext context, int minor, String currencyCode) {
  final localeName = Localizations.localeOf(context).toString();
  final code = resolveStorageCurrencyCode(currencyCode);
  if (code == kDefaultCurrencyCode) {
    return _formatMinorWithSymbol(localeName, minor, r'$');
  }
  return NumberFormat.simpleCurrency(locale: localeName, name: code)
      .format(minor / 100.0);
}

/// Same as [formatMinorAsMoney] but [major] is in currency major units (e.g. dollars).
String formatMajorDoubleAsMoney(
  BuildContext context,
  double major,
  String currencyCode,
) {
  return formatMinorAsMoney(context, (major * 100).round(), currencyCode);
}

/// Locale-aware money label without a [BuildContext] (e.g. journal list subjects).
String formatMinorAsMoneyForLocale(
  String localeName,
  int minor,
  String currencyCode,
) {
  final code = resolveStorageCurrencyCode(currencyCode);
  if (code == kDefaultCurrencyCode) {
    return _formatMinorWithSymbol(localeName, minor, r'$');
  }
  return NumberFormat.simpleCurrency(locale: localeName, name: code)
      .format(minor / 100.0);
}
