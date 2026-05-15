import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util/display_numbers.dart';
import '../util/percent_rational_expansion.dart';

/// Share of [totalMinor] attributed to [shareMinor], as a percent label.
/// - **Terminating** rational percent → exactly **one** fraction digit (half-up).
/// - **Non-terminating** → first [kNonTerminatingPercentDisplayFractionDigits]
///   **exact** fractional digits of `(share×100)/total`, then [kPercentExpansionEllipsis].
///
/// Calculation code must keep using integer minors; this widget is display-only.
class RationalPercentText extends StatelessWidget {
  const RationalPercentText({
    super.key,
    required this.shareMinor,
    required this.totalMinor,
    this.style,
  });

  final int shareMinor;
  final int totalMinor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.titleMedium;
    final sep = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).symbols.DECIMAL_SEP;

    final exp = expandPercentRationalFromShareTotal(
      shareMinor: shareMinor,
      totalMinor: totalMinor,
    );

    return switch (exp) {
      PercentExpansionOneDecimal(:final tenthsRounded) => Text(
          '${formatPercentFromTenthsRounded(context, tenthsRounded)}%',
          style: baseStyle,
        ),
      PercentExpansionTruncatedEllipsis(
        :final intPart,
        :final fracDigitsFour,
      ) =>
        Text(
          '$intPart$sep$fracDigitsFour$kPercentExpansionEllipsis%',
          style: baseStyle,
        ),
    };
  }
}
