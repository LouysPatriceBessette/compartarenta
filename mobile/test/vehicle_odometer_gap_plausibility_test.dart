import 'package:flutter_test/flutter_test.dart';

import 'package:compartarenta/vehicle/vehicle_consumption_metrics.dart';
import 'package:compartarenta/vehicle/vehicle_odometer_gap_plausibility.dart';

void main() {
  group('guardConsumptionLitersPer100Km', () {
    test('uses default when no mode breakdown', () {
      expect(
        guardConsumptionLitersPer100Km(
          const VehicleConsumptionSnapshot(hasSufficientData: false),
        ),
        kDefaultOdometerGapGuardLitersPer100Km,
      );
    });

    test('uses highest of city route traffic', () {
      expect(
        guardConsumptionLitersPer100Km(
          const VehicleConsumptionSnapshot(
            hasSufficientData: true,
            litersPer100KmRoute: 6.5,
            litersPer100KmCity: 9.2,
            litersPer100KmTraffic: 8.0,
          ),
        ),
        9.2,
      );
    });
  });

  group('maxPlausibleSessionDistanceTenths', () {
    test('60 L tank at 7.5 L/100 km → 800 km', () {
      expect(
        maxPlausibleSessionDistanceTenths(
          tankCapacityLiters: 60,
          fuelPurchasedLitersDuringSession: 0,
          guardLitersPer100Km: 7.5,
        ),
        8000,
      );
    });

    test('fuel purchased during session still capped at tank capacity', () {
      expect(
        maxPlausibleSessionDistanceTenths(
          tankCapacityLiters: 60,
          fuelPurchasedLitersDuringSession: 45,
          guardLitersPer100Km: 7.5,
        ),
        8000,
      );
    });

    test('returns null without tank capacity', () {
      expect(
        maxPlausibleSessionDistanceTenths(
          tankCapacityLiters: null,
          fuelPurchasedLitersDuringSession: 45,
          guardLitersPer100Km: 7.5,
        ),
        isNull,
      );
    });
  });

  group('maxPlausiblePositiveGapTenths', () {
    test('delegates to session distance with zero refuel', () {
      expect(
        maxPlausiblePositiveGapTenths(
          tankCapacityLiters: 60,
          guardLitersPer100Km: 7.5,
        ),
        8000,
      );
    });
  });

  group('isSuspiciousPositiveGap', () {
    test('900 km session distance exceeds 800 km guard', () {
      expect(
        isSuspiciousPositiveGap(gapTenths: 9000, maxGapTenths: 8000),
        isTrue,
      );
    });

    test('100 km gap within 800 km guard', () {
      expect(
        isSuspiciousPositiveGap(gapTenths: 1000, maxGapTenths: 8000),
        isFalse,
      );
    });
  });
}
