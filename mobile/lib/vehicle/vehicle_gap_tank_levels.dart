import 'vehicle_tank_fill_levels.dart';

/// Tank fill choices between two declared levels (inclusive), per product rules.
List<VehicleTankFillLevel> tankFillLevelsBetween({
  required int? previousPercent,
  required int? triggerPercent,
}) {
  final low = _effectivePercent(previousPercent);
  final high = _effectivePercent(triggerPercent);
  final minP = low < high ? low : high;
  final maxP = low < high ? high : low;
  return VehicleTankFillLevel.choices
      .where((level) => level.percent >= minP && level.percent <= maxP)
      .toList();
}

int _effectivePercent(int? percent) {
  if (percent == null) return VehicleTankFillLevel.highestPercent;
  return percent;
}
