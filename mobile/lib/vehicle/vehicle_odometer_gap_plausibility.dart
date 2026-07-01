import 'dart:math';

import 'vehicle_consumption_metrics.dart';

/// Default guard when no city/route/traffic consumption is known: 7.5 L/100 km.
const double kDefaultOdometerGapGuardLitersPer100Km = 7.5;

/// Highest known city/route/traffic consumption, or [kDefaultOdometerGapGuardLitersPer100Km].
double guardConsumptionLitersPer100Km(VehicleConsumptionSnapshot snapshot) {
  final candidates = <double>[
    if (snapshot.litersPer100KmRoute != null && snapshot.litersPer100KmRoute! > 0)
      snapshot.litersPer100KmRoute!,
    if (snapshot.litersPer100KmCity != null && snapshot.litersPer100KmCity! > 0)
      snapshot.litersPer100KmCity!,
    if (snapshot.litersPer100KmTraffic != null &&
        snapshot.litersPer100KmTraffic! > 0)
      snapshot.litersPer100KmTraffic!,
  ];
  if (candidates.isEmpty) {
    return kDefaultOdometerGapGuardLitersPer100Km;
  }
  return candidates.reduce(max);
}

/// Max plausible one-tank distance in stored km tenths, or null when unknown.
int? maxPlausiblePositiveGapTenths({
  required double? tankCapacityLiters,
  required double guardLitersPer100Km,
}) {
  return maxPlausibleSessionDistanceTenths(
    tankCapacityLiters: tankCapacityLiters,
    fuelPurchasedLitersDuringSession: 0,
    guardLitersPer100Km: guardLitersPer100Km,
  );
}

/// Max plausible session distance from fuel available in the tank.
///
/// [fuelPurchasedLitersDuringSession] is ignored for the upper bound: fuel on
/// board cannot exceed [tankCapacityLiters] (a full-tank purchase fills to
/// capacity, it does not add purchase volume on top).
int? maxPlausibleSessionDistanceTenths({
  required double? tankCapacityLiters,
  required double fuelPurchasedLitersDuringSession,
  required double guardLitersPer100Km,
}) {
  if (tankCapacityLiters == null ||
      tankCapacityLiters <= 0 ||
      guardLitersPer100Km <= 0) {
    return null;
  }
  final effectiveFuelLiters = tankCapacityLiters;
  if (effectiveFuelLiters <= 0) {
    return null;
  }
  final maxKm = effectiveFuelLiters * 100 / guardLitersPer100Km;
  return (maxKm * 10).round();
}

bool isSuspiciousPositiveGap({
  required int gapTenths,
  required int? maxGapTenths,
}) {
  if (maxGapTenths == null || gapTenths <= 0) {
    return false;
  }
  return gapTenths > maxGapTenths;
}
