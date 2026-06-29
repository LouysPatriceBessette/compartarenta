/// Approximate tank fill level when a purchase is not a full tank.
class VehicleTankFillLevel {
  const VehicleTankFillLevel({
    required this.fractionNumerator,
    required this.fractionDenominator,
    required this.percent,
  });

  final int fractionNumerator;
  final int fractionDenominator;
  final int percent;

  String label() => '$fractionNumerator/$fractionDenominator - $percent%';

  static const List<VehicleTankFillLevel> choices = [
    VehicleTankFillLevel(fractionNumerator: 7, fractionDenominator: 8, percent: 87),
    VehicleTankFillLevel(fractionNumerator: 3, fractionDenominator: 4, percent: 75),
    VehicleTankFillLevel(fractionNumerator: 5, fractionDenominator: 8, percent: 62),
    VehicleTankFillLevel(fractionNumerator: 1, fractionDenominator: 2, percent: 50),
    VehicleTankFillLevel(fractionNumerator: 3, fractionDenominator: 8, percent: 37),
    VehicleTankFillLevel(fractionNumerator: 1, fractionDenominator: 4, percent: 25),
  ];

  static final VehicleTankFillLevel defaultChoice = choices.first;

  static VehicleTankFillLevel? fromPercent(int? percent) {
    if (percent == null) return null;
    for (final c in choices) {
      if (c.percent == percent) return c;
    }
    return null;
  }
}
