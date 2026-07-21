import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Shared chart colors for housing balance and payment-status graphs.
const List<Color> housingBalancesChartPalette = [
  AppBrandColors.vehicleBlue,
  AppBrandColors.moneyGreen,
  AppBrandColors.housingOrange,
  AppBrandColors.calendarViolet,
  AppBrandColors.rust,
  AppBrandColors.tornadoAmber,
  AppBrandColors.stone,
  AppBrandColors.tornadoOrange,
];

Color housingChartColorForIndex(int index) =>
    housingBalancesChartPalette[index % housingBalancesChartPalette.length];
