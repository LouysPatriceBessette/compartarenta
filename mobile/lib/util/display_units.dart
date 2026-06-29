import 'package:intl/intl.dart';

import '../prefs/app_preferences.dart';

/// User-facing liquid volume abbreviations (fixed labels per product spec).
String liquidVolumeUnitAbbrev(LiquidVolumeUnit unit) => switch (unit) {
      LiquidVolumeUnit.liter => 'L',
      LiquidVolumeUnit.usGallon => 'Gal US',
      LiquidVolumeUnit.imperialGallon => 'Gal Imp',
    };

/// User-facing distance abbreviations (fixed labels per product spec).
String distanceUnitAbbrev(DistanceUnit unit) => switch (unit) {
      DistanceUnit.km => 'Km',
      DistanceUnit.miles => 'Miles',
    };

LiquidVolumeUnit resolveLiquidVolumeUnit(AppPreferences prefs) =>
    prefs.liquidVolumeUnit ?? LiquidVolumeUnit.liter;

DistanceUnit resolveDistanceUnit(AppPreferences prefs) =>
    prefs.distanceUnit ?? DistanceUnit.km;

const double _litersPerUsGallon = 3.785411784;
const double _litersPerImperialGallon = 4.54609;

/// Converts liters (canonical storage) to the user's liquid volume unit.
double litersToDisplayVolume(double liters, LiquidVolumeUnit unit) =>
    switch (unit) {
      LiquidVolumeUnit.liter => liters,
      LiquidVolumeUnit.usGallon => liters / _litersPerUsGallon,
      LiquidVolumeUnit.imperialGallon => liters / _litersPerImperialGallon,
    };

/// Converts a user-entered volume to liters for persistence.
double displayVolumeToLiters(double display, LiquidVolumeUnit unit) =>
    switch (unit) {
      LiquidVolumeUnit.liter => display,
      LiquidVolumeUnit.usGallon => display * _litersPerUsGallon,
      LiquidVolumeUnit.imperialGallon => display * _litersPerImperialGallon,
    };

String formatLiquidVolumeForDisplay(
  double liters, {
  required LiquidVolumeUnit unit,
  required String locale,
}) {
  final display = litersToDisplayVolume(liters, unit);
  final formatted = NumberFormat('#,##0.0', locale).format(display);
  return '$formatted ${liquidVolumeUnitAbbrev(unit)}';
}
