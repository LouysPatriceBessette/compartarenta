import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'percent_rational_expansion.dart';

/// **Display-only** number formatting (never round pipeline math — format at UI).
///
/// - **Money**: [formatMinorAsMoney] / [formatMajorDoubleAsMoney] in
///   `format_money.dart` (two fraction digits).
/// - **Percentages**: one fraction digit when the rational **terminates**;
///   for non-terminating `(share×100)/total`, use [formatShareOfTotalPercentNoSuffixSmart]
///   or [RationalPercentText] (four exact fractional digits + ellipsis).
String formatPercentFromTenthsRounded(
  BuildContext context,
  int tenthsRounded,
) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat('#0.0', locale).format(tenthsRounded / 10.0);
}

/// [formatShareOfTotalPercentNoSuffix] plus, when `(share×100)/total` is
/// non-terminating, four **exact** truncated fractional digits and
/// [kPercentExpansionEllipsis].
String formatShareOfTotalPercentNoSuffixSmart(
  BuildContext context, {
  required int shareNumeratorMinor,
  required int totalDenominatorMinor,
}) {
  final sep = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).symbols.DECIMAL_SEP;
  final exp = expandPercentRationalFromShareTotal(
    shareMinor: shareNumeratorMinor,
    totalMinor: totalDenominatorMinor,
  );
  return switch (exp) {
    PercentExpansionOneDecimal(:final tenthsRounded) =>
      formatPercentFromTenthsRounded(context, tenthsRounded),
    PercentExpansionTruncatedEllipsis(
      :final intPart,
      :final fracDigitsFour,
    ) =>
      '$intPart$sep$fracDigitsFour$kPercentExpansionEllipsis',
  };
}

String formatShareOfTotalPercentWithSuffixSmart(
  BuildContext context, {
  required int shareNumeratorMinor,
  required int totalDenominatorMinor,
}) =>
    '${formatShareOfTotalPercentNoSuffixSmart(context, shareNumeratorMinor: shareNumeratorMinor, totalDenominatorMinor: totalDenominatorMinor)}%';

/// One decimal, half-up (terminating decimal only).
String formatShareOfTotalPercentNoSuffix(
  BuildContext context, {
  required int shareNumeratorMinor,
  required int totalDenominatorMinor,
}) {
  final locale = Localizations.localeOf(context).toString();
  final fmt = NumberFormat('#0.0', locale);
  if (totalDenominatorMinor <= 0) {
    return fmt.format(0);
  }
  final tenths =
      (shareNumeratorMinor * 1000 + totalDenominatorMinor ~/ 2) ~/
          totalDenominatorMinor;
  return fmt.format(tenths / 10.0);
}

/// Same as [formatShareOfTotalPercentNoSuffix] but appends a `%` sign for
/// standalone labels (no space; follow with l10n if the string already adds `%`).
String formatShareOfTotalPercentWithSuffix(
  BuildContext context, {
  required int shareNumeratorMinor,
  required int totalDenominatorMinor,
}) =>
    '${formatShareOfTotalPercentNoSuffix(context, shareNumeratorMinor: shareNumeratorMinor, totalDenominatorMinor: totalDenominatorMinor)}%';

/// Display-only percent in \[0, 100\] from a **ratio** `numerator/denominator`
/// (e.g. already-scaled integers). One decimal, half-up.
String formatRatioAsPercentNoSuffix(
  BuildContext context, {
  required int numerator,
  required int denominator,
}) {
  final locale = Localizations.localeOf(context).toString();
  final fmt = NumberFormat('#0.0', locale);
  if (denominator <= 0) return fmt.format(0);
  final tenths = (numerator * 10 + denominator ~/ 2) ~/ denominator;
  return fmt.format(tenths / 10.0);
}
