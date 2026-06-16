import 'package:flutter/material.dart';

/// Shared chart colors for housing balance and payment-status graphs.
const List<Color> housingBalancesChartPalette = [
  Color(0xFFD32F2F),
  Color(0xFF1976D2),
  Color(0xFF388E3C),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF00838F),
  Color(0xFF6D4C41),
  Color(0xFF455A64),
];

Color housingChartColorForIndex(int index) =>
    housingBalancesChartPalette[index % housingBalancesChartPalette.length];
