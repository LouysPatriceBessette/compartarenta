import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../housing/realized_expense/realized_expense_balance.dart';

final class HousingBalancesGraphPainter extends CustomPainter {
  const HousingBalancesGraphPainter({
    required this.participants,
    required this.modeData,
  });

  final List<HousingBalanceParticipant> participants;
  final HousingBalanceModeData modeData;

  static const List<Color> _palette = [
    Color(0xFFD32F2F),
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (participants.isEmpty) {
      return;
    }
    final centers = _nodeCenters(size, participants.length);
    final labels = _labelCenters(size, participants.length);
    final participantIndex = <String, int>{
      for (var i = 0; i < participants.length; i++) participants[i].participantId: i,
    };
    final nodeByParticipant = <String, HousingBalanceNodeEntry>{
      for (final node in modeData.nodes) node.participantId: node,
    };

    final skeletonPaint = Paint()
      ..color = const Color(0xFFB8C1CC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < centers.length; i++) {
      for (var j = i + 1; j < centers.length; j++) {
        canvas.drawLine(centers[i], centers[j], skeletonPaint);
      }
    }

    final maxEdgeAmount = modeData.edges.fold<int>(
      0,
      (maxAmount, edge) =>
          maxAmount > edge.amountMinor ? maxAmount : edge.amountMinor,
    );
    for (final edge in modeData.edges) {
      final fromIndex = participantIndex[edge.fromParticipantId];
      final toIndex = participantIndex[edge.toParticipantId];
      if (fromIndex == null || toIndex == null) {
        continue;
      }
      final fromCenter = centers[fromIndex];
      final toCenter = centers[toIndex];
      final vector = toCenter - fromCenter;
      final distance = vector.distance;
      if (distance <= 0) {
        continue;
      }
      final unit = Offset(vector.dx / distance, vector.dy / distance);
      final fromRadius = _nodeRadius(
        size,
        nodeByParticipant[edge.fromParticipantId]?.diameterPercent ?? 0,
      );
      final toRadius = _nodeRadius(
        size,
        nodeByParticipant[edge.toParticipantId]?.diameterPercent ?? 0,
      );
      const arrowLength = 10.0;
      final start = fromCenter + (unit * fromRadius);
      final tip = toCenter - (unit * toRadius);
      final end = tip - (unit * arrowLength);
      final strokeWidth = maxEdgeAmount <= 0
          ? 3.0
          : 2.5 + (1.5 * edge.amountMinor / maxEdgeAmount);
      final edgePaint = Paint()
        ..color = _palette[fromIndex % _palette.length].withValues(alpha: 0.82)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, edgePaint);

      final perpendicular = Offset(-unit.dy, unit.dx);
      final arrowHalfWidth = 5.0;
      final arrowPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          end.dx + (perpendicular.dx * arrowHalfWidth),
          end.dy + (perpendicular.dy * arrowHalfWidth),
        )
        ..lineTo(
          end.dx - (perpendicular.dx * arrowHalfWidth),
          end.dy - (perpendicular.dy * arrowHalfWidth),
        )
        ..close();
      final arrowPaint = Paint()
        ..color = _palette[fromIndex % _palette.length].withValues(alpha: 0.82)
        ..style = PaintingStyle.fill;
      canvas.drawPath(arrowPath, arrowPaint);
    }

    for (var i = 0; i < participants.length; i++) {
      final participant = participants[i];
      final node = nodeByParticipant[participant.participantId];
      final radius = _nodeRadius(size, node?.diameterPercent ?? 0);
      final fillPaint = Paint()
        ..color = _palette[i % _palette.length]
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(centers[i], radius, fillPaint);
      canvas.drawCircle(centers[i], radius, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: participant.letter,
          style: TextStyle(
            color: _palette[i % _palette.length],
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = Offset(
        labels[i].dx - (textPainter.width / 2),
        labels[i].dy - (textPainter.height / 2),
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant HousingBalancesGraphPainter oldDelegate) {
    return oldDelegate.participants != participants ||
        oldDelegate.modeData != modeData;
  }

  static double _nodeRadius(Size size, double diameterPercent) {
    final minSide = math.min(size.width, size.height);
    final minDiameter = minSide * 0.012;
    final maxDiameter = minSide * 0.072;
    final diameter =
        minDiameter + ((diameterPercent / 100) * (maxDiameter - minDiameter));
    return diameter / 2;
  }

  static List<Offset> _nodeCenters(Size size, int count) {
    if (count <= 1) {
      return [Offset(size.width / 2, size.height / 2)];
    }
    if (count == 2) {
      return [
        Offset(size.width * 0.22, size.height * 0.5),
        Offset(size.width * 0.78, size.height * 0.5),
      ];
    }
    final minSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = minSide * 0.34;
    return [
      for (var i = 0; i < count; i++)
        Offset(
          center.dx + (radius * math.cos(_angleForIndex(i, count))),
          center.dy + (radius * math.sin(_angleForIndex(i, count))),
        ),
    ];
  }

  static List<Offset> _labelCenters(Size size, int count) {
    if (count <= 1) {
      return [Offset(size.width / 2, size.height * 0.18)];
    }
    if (count == 2) {
      return [
        Offset(size.width * 0.22, size.height * 0.355),
        Offset(size.width * 0.78, size.height * 0.355),
      ];
    }
    final minSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = minSide * 0.416;
    return [
      for (var i = 0; i < count; i++)
        Offset(
          center.dx + (radius * math.cos(_angleForIndex(i, count))),
          center.dy + (radius * math.sin(_angleForIndex(i, count))),
        ),
    ];
  }

  static double _angleForIndex(int index, int count) {
    return (-math.pi / 2) + (index * (2 * math.pi / count));
  }
}
