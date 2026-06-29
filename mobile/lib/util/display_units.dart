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
