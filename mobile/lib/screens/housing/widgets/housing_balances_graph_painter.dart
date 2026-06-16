import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../housing/realized_expense/realized_expense_balance.dart';
import 'housing_chart_palette.dart';

final class HousingBalancesGraphPainter extends CustomPainter {
  const HousingBalancesGraphPainter({
    required this.participants,
    required this.modeData,
  });

  final List<HousingBalanceParticipant> participants;
  final HousingBalanceModeData modeData;

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
      ..color = const Color(0xFFB8C1CC).withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final debtEdgePaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < centers.length; i++) {
      for (var j = i + 1; j < centers.length; j++) {
        final vector = centers[j] - centers[i];
        final distance = vector.distance;
        if (distance <= 0) {
          continue;
        }
        final unit = Offset(vector.dx / distance, vector.dy / distance);
        final radiusI = _nodeRadius(
          size,
          nodeByParticipant[participants[i].participantId]?.diameterPercent ?? 0,
        );
        final radiusJ = _nodeRadius(
          size,
          nodeByParticipant[participants[j].participantId]?.diameterPercent ?? 0,
        );
        canvas.drawLine(
          _linePointNearNode(centers[i], unit, radiusI, size),
          _linePointNearNode(centers[j], -unit, radiusJ, size),
          skeletonPaint,
        );
      }
    }

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
      final start = _linePointNearNode(fromCenter, unit, fromRadius, size);
      final end = _linePointNearNode(toCenter, -unit, toRadius, size);

      final fromColor = housingChartColorForIndex(fromIndex);
      debtEdgePaint.shader = ui.Gradient.linear(
        start,
        end,
        [
          fromColor,
          const Color(0xFFB8C1CC).withValues(alpha: 0.15),
        ],
        const [0.0, 0.9],
      );
      canvas.drawLine(start, end, debtEdgePaint);
    }

    for (var i = 0; i < participants.length; i++) {
      final participant = participants[i];
      final node = nodeByParticipant[participant.participantId];
      final appearance = _nodeAppearance(
        participantCount: participants.length,
        diameterPercent: node?.diameterPercent ?? 0,
        color: housingChartColorForIndex(i),
      );
      final radius = _nodeRadius(size, node?.diameterPercent ?? 0);
      final fillPaint = Paint()
        ..color = appearance.color.withValues(alpha: appearance.fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centers[i], radius, fillPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: participant.letter,
          style: TextStyle(
            color: appearance.color.withValues(alpha: appearance.labelOpacity),
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

  static const double _svgViewBoxMinSide = 500;
  static const double _svgMinNodeRadius = 8;
  static const double _svgMaxNodeRadius = 20;
  /// Clearance between a line end and the node circle (SVG units).
  static const double _svgLineNodeGap = 3;

  static ({Color color, double fillOpacity, double labelOpacity}) _nodeAppearance({
    required int participantCount,
    required double diameterPercent,
    required Color color,
  }) {
    final recessed = participantCount >= 3 && diameterPercent <= 0;
    if (recessed) {
      return (color: color, fillOpacity: 0.4, labelOpacity: 0.4);
    }
    return (color: color, fillOpacity: 1, labelOpacity: 1);
  }

  static double _nodeRadius(Size size, double diameterPercent) {
    final minSide = math.min(size.width, size.height);
    final svgRadius = _svgMinNodeRadius +
        ((diameterPercent / 100) * (_svgMaxNodeRadius - _svgMinNodeRadius));
    return svgRadius * (minSide / _svgViewBoxMinSide);
  }

  static double _lineNodeGap(Size size) =>
      _svgLineNodeGap * (math.min(size.width, size.height) / _svgViewBoxMinSide);

  /// [outwardUnit] points from the node center toward the other endpoint.
  static Offset _linePointNearNode(
    Offset center,
    Offset outwardUnit,
    double nodeRadius,
    Size size,
  ) {
    return center + (outwardUnit * (nodeRadius + _lineNodeGap(size)));
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
