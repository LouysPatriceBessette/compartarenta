import 'package:flutter/material.dart';

/// Approximates CSS `text-wrap: balance` for short menu labels.
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedStyle = style ?? DefaultTextStyle.of(context).style;
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Text(
            text,
            style: resolvedStyle,
            textAlign: textAlign,
            maxLines: maxLines,
          );
        }
        final direction = Directionality.of(context);
        final balanced = balanceTextWrap(
          text,
          maxWidth: maxWidth,
          style: resolvedStyle,
          textDirection: direction,
        );
        return Text(
          balanced,
          style: resolvedStyle,
          textAlign: textAlign,
          maxLines: maxLines,
        );
      },
    );
  }
}

/// Picks manual line breaks so wrapped lines have similar visual width.
String balanceTextWrap(
  String text, {
  required double maxWidth,
  required TextStyle style,
  required TextDirection textDirection,
}) {
  final words = text.split(RegExp(r'\s+'));
  if (words.length <= 1) {
    return text;
  }

  final singleLineWidth = _measureText(
    text,
    style: style,
    textDirection: textDirection,
  );
  if (singleLineWidth <= maxWidth) {
    return text;
  }

  var bestScore = double.infinity;
  String? bestTwoLine;

  for (var split = 1; split < words.length; split++) {
    final line1 = words.sublist(0, split).join(' ');
    final line2 = words.sublist(split).join(' ');
    final width1 = _measureText(
      line1,
      style: style,
      textDirection: textDirection,
    );
    final width2 = _measureText(
      line2,
      style: style,
      textDirection: textDirection,
    );
    if (width1 > maxWidth || width2 > maxWidth) {
      continue;
    }
    final score = (width1 - width2).abs();
    if (score < bestScore) {
      bestScore = score;
      bestTwoLine = '$line1\n$line2';
    }
  }

  if (bestTwoLine != null) {
    return bestTwoLine;
  }

  return text;
}

double _measureText(
  String value, {
  required TextStyle style,
  required TextDirection textDirection,
}) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: textDirection,
    maxLines: 1,
  )..layout();
  return painter.width;
}
