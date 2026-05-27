import 'package:flutter/material.dart';

import '../../../housing/realized_expense/realized_expense_balance.dart';
import 'housing_balances_graph_painter.dart';

class HousingBalancesGraph extends StatelessWidget {
  const HousingBalancesGraph({
    super.key,
    required this.participants,
    required this.modeData,
  });

  final List<HousingBalanceParticipant> participants;
  final HousingBalanceModeData modeData;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = participants.length == 2 ? (500 / 220) : 1.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: HousingBalancesGraphPainter(
          participants: participants,
          modeData: modeData,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
