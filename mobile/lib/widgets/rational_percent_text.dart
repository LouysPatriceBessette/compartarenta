import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// Expands [numerator]/[denominator] as a percentage (already ×100 if needed).
///
/// [percentNumerator] / [percentDenominator] is the exact percent value
/// (e.g. share 30000, total 90000 → pass numerator 100*30000, denominator 90000).
class _PercentExpansion {
  _PercentExpansion.terminating(this.intPart, this.fracTwoDecimals)
    : isTerminating = true,
      nonRepeatDigits = '',
      repeatDigits = '';

  _PercentExpansion.repeating({
    required this.intPart,
    required this.nonRepeatDigits,
    required this.repeatDigits,
  })  : isTerminating = false,
        fracTwoDecimals = '';

  final bool isTerminating;
  final int intPart;
  final String fracTwoDecimals;
  final String nonRepeatDigits;
  final String repeatDigits;
}

_PercentExpansion? _expandPercentRational(int num, int den) {
  if (den <= 0) return null;
  num = num.abs();
  final g = _gcd(num, den);
  num ~/= g;
  den ~/= g;

  final intPart = num ~/ den;
  final rem = num % den;
  if (rem == 0) {
    final scaled = (num * 100) ~/ den;
    final w = scaled ~/ 100;
    final f = (scaled % 100).toString().padLeft(2, '0');
    return _PercentExpansion.terminating(w, f);
  }

  if (_isTerminatingDenominator(den)) {
    final scaled = (num * 100 + den ~/ 2) ~/ den;
    final w = scaled ~/ 100;
    final f = (scaled % 100).toString().padLeft(2, '0');
    return _PercentExpansion.terminating(w, f);
  }

  final fracDigits = <int>[];
  final remAtIndex = <int, int>{};
  var r = rem;
  var idx = 0;
  var repeatStart = 0;
  while (true) {
    if (r == 0) {
      final scaled = (num * 100 + den ~/ 2) ~/ den;
      final w = scaled ~/ 100;
      final f = (scaled % 100).toString().padLeft(2, '0');
      return _PercentExpansion.terminating(w, f);
    }
    if (remAtIndex.containsKey(r)) {
      repeatStart = remAtIndex[r]!;
      break;
    }
    remAtIndex[r] = idx;
    r *= 10;
    fracDigits.add(r ~/ den);
    r %= den;
    idx++;
    if (idx > 48) {
      repeatStart = 0;
      break;
    }
  }

  final nonRep = fracDigits.sublist(0, repeatStart).join();
  final rep = fracDigits.sublist(repeatStart).join();
  if (rep.isEmpty) {
    final scaled = (num * 100 + den ~/ 2) ~/ den;
    final w = scaled ~/ 100;
    final f = (scaled % 100).toString().padLeft(2, '0');
    return _PercentExpansion.terminating(w, f);
  }
  return _PercentExpansion.repeating(
    intPart: intPart,
    nonRepeatDigits: nonRep,
    repeatDigits: rep,
  );
}

/// Renders a percent for [shareMinor] of [totalMinor] using two decimals when
/// exact, otherwise **vinculum** (overline) on the minimal repeating tail.
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

    if (totalMinor <= 0) {
      return Text('0${sep}00%', style: baseStyle);
    }

    final pctNumerator = shareMinor * 100;
    final exp = _expandPercentRational(pctNumerator, totalMinor);
    if (exp == null) {
      return Text('0${sep}00%', style: baseStyle);
    }

    if (exp.isTerminating) {
      return Text('${exp.intPart}$sep${exp.fracTwoDecimals}%', style: baseStyle);
    }

    final children = <InlineSpan>[
      TextSpan(
        text: '${exp.intPart}$sep${exp.nonRepeatDigits}',
        style: baseStyle,
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _OverlinedDigitRun(
          digits: exp.repeatDigits,
          style: baseStyle,
        ),
      ),
      TextSpan(text: '%', style: baseStyle),
    ];

    return Text.rich(TextSpan(children: children));
  }
}

class _OverlinedDigitRun extends StatelessWidget {
  const _OverlinedDigitRun({required this.digits, this.style});

  final String digits;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final st = style ?? DefaultTextStyle.of(context).style;
    final tp = TextPainter(
      text: TextSpan(text: digits, style: st),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final w = tp.width;
    final h = tp.height;
    return SizedBox(
      width: w,
      height: h + 5,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 1,
            child: Container(
              height: 1.2,
              color: st.color ?? DefaultTextStyle.of(context).style.color,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(digits, style: st),
          ),
        ],
      ),
    );
  }
}
