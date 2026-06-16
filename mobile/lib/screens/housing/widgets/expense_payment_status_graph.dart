import 'package:flutter/material.dart';

import '../../../housing/realized_expense/expense_payment_status.dart';
import 'expense_payment_status_graph_painter.dart';

class ExpensePaymentStatusGraph extends StatelessWidget {
  const ExpensePaymentStatusGraph({super.key, required this.bars});

  final List<ExpensePaymentStatusBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const SizedBox.shrink();
    }

    final contentWidth = ExpensePaymentStatusGraphPainter.contentWidth(
      bars.length,
    );
    final chartHeight = ExpensePaymentStatusGraphPainter.chartHeightForBars(
      bars,
    );
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final chartWidth = contentWidth < viewportWidth
            ? viewportWidth
            : contentWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: CustomPaint(
                    painter: ExpensePaymentStatusGraphPainter(bars: bars),
                    size: Size(chartWidth, chartHeight),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      for (final bar in bars)
                        SizedBox(
                          width: ExpensePaymentStatusGraphPainter.columnWidth,
                          child: Text(
                            bar.letter,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: bar.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
