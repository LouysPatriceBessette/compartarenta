import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../housing/realized_expense/expense_payment_status.dart';
import '../../../theme/app_theme.dart';

class ExpensePaymentStatusGraphPainter extends CustomPainter {
  const ExpensePaymentStatusGraphPainter({required this.bars});

  final List<ExpensePaymentStatusBar> bars;

  static const double columnWidth = 52;
  static const double scaleStrokeWidth = 1.5;
  static const double fillBarWidth = 10;
  static const double fillBarGap = 4;
  static const int tickCount = 6;
  static const double tickLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) {
      return;
    }

    final scalePaint = Paint()
      ..color = AppBrandColors.stone
      ..strokeWidth = scaleStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = AppBrandColors.stone
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final bottomY = size.height;

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final centerX = columnWidth * i + columnWidth / 2;
      final bandHeight = bar.heightPixels;
      final topY = bottomY - bandHeight;
      final scaleX = centerX + fillBarWidth / 2 + fillBarGap;

      canvas.drawLine(Offset(scaleX, topY), Offset(scaleX, bottomY), scalePaint);

      for (var t = 0; t <= tickCount; t++) {
        final y = bottomY - (bandHeight * t / tickCount);
        canvas.drawLine(
          Offset(scaleX, y),
          Offset(scaleX + tickLength, y),
          tickPaint,
        );
      }

      if (bar.paidFraction <= 0) {
        continue;
      }

      final fillHeight = bandHeight * bar.paidFraction;
      final fillTopY = bottomY - fillHeight;
      final fillLeft = scaleX - fillBarGap - fillBarWidth;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(fillLeft, fillTopY, fillBarWidth, fillHeight),
        const Radius.circular(2),
      );
      final fillPaint = Paint()
        ..color = bar.color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ExpensePaymentStatusGraphPainter oldDelegate) {
    return oldDelegate.bars != bars;
  }

  static double fillHeightPixels(ExpensePaymentStatusBar bar) {
    if (bar.paidFraction <= 0) {
      return 0;
    }
    return bar.heightPixels * bar.paidFraction;
  }

  static double chartHeightForBars(List<ExpensePaymentStatusBar> bars) {
    if (bars.isEmpty) {
      return 0;
    }
    var maxHeight = expensePaymentBandReferenceHeightPx;
    for (final bar in bars) {
      maxHeight = math.max(maxHeight, bar.heightPixels);
      maxHeight = math.max(maxHeight, fillHeightPixels(bar));
    }
    return maxHeight;
  }

  static double contentWidth(int barCount) =>
      math.max(columnWidth * barCount, columnWidth);
}
