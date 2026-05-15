/// Exact percent = (share × 100) / total for **display** classification only.
sealed class PercentRationalExpansion {
  const PercentRationalExpansion();
}

/// Non-terminating percents show this many **exact** fractional digits (truncate),
/// then [kPercentExpansionEllipsis].
const int kNonTerminatingPercentDisplayFractionDigits = 4;

/// Unicode HORIZONTAL ELLIPSIS (U+2026), one glyph like typographic "…".
const String kPercentExpansionEllipsis = '\u2026';

int _percentTenthsHalfUp(int num, int den) => (num * 10 + den ~/ 2) ~/ den;

/// Terminating decimal: show a single rounded fractional digit (locale-aware
/// formatting happens in the widget / formatter layer).
class PercentExpansionOneDecimal extends PercentRationalExpansion {
  const PercentExpansionOneDecimal(this.tenthsRounded);
  /// Value × 10, rounded half-up (e.g. 505 → 50.5%).
  final int tenthsRounded;
}

/// Non-terminating: first [kNonTerminatingPercentDisplayFractionDigits] digits
/// after the decimal point of the **exact** rational (no rounding), then ellipsis.
class PercentExpansionTruncatedEllipsis extends PercentRationalExpansion {
  const PercentExpansionTruncatedEllipsis({
    required this.intPart,
    required this.fracDigitsFour,
  }) : assert(fracDigitsFour.length == kNonTerminatingPercentDisplayFractionDigits);

  final int intPart;
  /// Exactly [kNonTerminatingPercentDisplayFractionDigits] characters in `0`–`9`.
  final String fracDigitsFour;
}

int _gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a;
}

bool _isTerminatingDenominator(int d) {
  var x = d.abs();
  while (x % 2 == 0) {
    x ~/= 2;
  }
  while (x % 5 == 0) {
    x ~/= 5;
  }
  return x == 1;
}

/// Classifies (share×100)/total for **display** (never mutate calculation ints).
PercentRationalExpansion expandPercentRationalFromShareTotal({
  required int shareMinor,
  required int totalMinor,
}) {
  if (totalMinor <= 0) return const PercentExpansionOneDecimal(0);
  var num = shareMinor * 100;
  var den = totalMinor;
  final g = _gcd(num, den);
  num ~/= g;
  den ~/= g;

  final intPart = num ~/ den;
  final rem = num % den;
  if (rem == 0) {
    return PercentExpansionOneDecimal(_percentTenthsHalfUp(num, den));
  }

  if (_isTerminatingDenominator(den)) {
    return PercentExpansionOneDecimal(_percentTenthsHalfUp(num, den));
  }

  final buf = StringBuffer();
  var r = rem;
  for (var i = 0; i < kNonTerminatingPercentDisplayFractionDigits; i++) {
    if (r == 0) {
      buf.write('0');
      continue;
    }
    r *= 10;
    buf.writeCharCode(0x30 + (r ~/ den));
    r %= den;
  }
  return PercentExpansionTruncatedEllipsis(
    intPart: intPart,
    fracDigitsFour: buf.toString(),
  );
}
