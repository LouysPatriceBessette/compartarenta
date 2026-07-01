import 'package:compartarenta/vehicle/vehicle_driving_condition_consumption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('drivingMixPercentsValid', () {
    test('accepts integers summing to 100', () {
      expect(drivingMixPercentsValid(50, 30, 20), isTrue);
      expect(drivingMixPercentsValid(100, 0, 0), isTrue);
    });

    test('rejects non-100 sums and negatives', () {
      expect(drivingMixPercentsValid(50, 30, 21), isFalse);
      expect(drivingMixPercentsValid(-1, 50, 51), isFalse);
    });
  });

  group('solveDrivingConditionConsumption', () {
    test('recovers known per-mode rates from three tank intervals', () {
      const routeRate = 0.08;
      const cityRate = 0.10;
      const trafficRate = 0.12;

      final intervals = [
        DrivingConditionConsumptionInput(
          routeKm: 100,
          cityKm: 50,
          trafficKm: 50,
          fuelLiters: routeRate * 100 + cityRate * 50 + trafficRate * 50,
        ),
        DrivingConditionConsumptionInput(
          routeKm: 50,
          cityKm: 100,
          trafficKm: 50,
          fuelLiters: routeRate * 50 + cityRate * 100 + trafficRate * 50,
        ),
        DrivingConditionConsumptionInput(
          routeKm: 50,
          cityKm: 50,
          trafficKm: 100,
          fuelLiters: routeRate * 50 + cityRate * 50 + trafficRate * 100,
        ),
      ];

      final result = solveDrivingConditionConsumption(intervals);
      expect(result, isNotNull);
      expect(result!.litersPerKmRoute, closeTo(routeRate, 1e-6));
      expect(result.litersPerKmCity, closeTo(cityRate, 1e-6));
      expect(result.litersPerKmTraffic, closeTo(trafficRate, 1e-6));
    });

    test('returns null with fewer than two intervals', () {
      expect(
        solveDrivingConditionConsumption(const [
          DrivingConditionConsumptionInput(
            routeKm: 100,
            cityKm: 0,
            trafficKm: 0,
            fuelLiters: 8,
          ),
        ]),
        isNull,
      );
    });

    test('two intervals attribute fuel to traffic when traffic km > 0', () {
      final intervals = [
        const DrivingConditionConsumptionInput(
          routeKm: 500,
          cityKm: 109,
          trafficKm: 21,
          fuelLiters: 43,
        ),
        const DrivingConditionConsumptionInput(
          routeKm: 115,
          cityKm: 103.5,
          trafficKm: 36.5,
          fuelLiters: 18,
        ),
      ];

      final result = solveDrivingConditionConsumption(intervals);
      expect(result, isNotNull);
      expect(result!.litersPer100KmTraffic, greaterThan(0));
      expect(
        result.blendedLitersPer100Km(
          totalRouteKm: 615,
          totalCityKm: 212.5,
          totalTrafficKm: 57.5,
        ),
        closeTo(6.9, 0.1),
      );
      expect(result.litersPer100KmRoute, closeTo(6.5, 0.2));
      expect(result.litersPer100KmCity, closeTo(9.0, 0.2));
      expect(result.litersPer100KmTraffic, closeTo(3.3, 0.2));
    });

    test('three intervals recover stable rates from user seed window', () {
      final intervals = [
        const DrivingConditionConsumptionInput(
          routeKm: 500,
          cityKm: 109,
          trafficKm: 21,
          fuelLiters: 43,
        ),
        const DrivingConditionConsumptionInput(
          routeKm: 115,
          cityKm: 103.5,
          trafficKm: 36.5,
          fuelLiters: 18,
        ),
        const DrivingConditionConsumptionInput(
          routeKm: 384.4,
          cityKm: 85.35,
          trafficKm: 42.25,
          fuelLiters: 35.4,
        ),
      ];

      final result = solveDrivingConditionConsumption(intervals);
      expect(result, isNotNull);
      expect(result!.litersPer100KmRoute, closeTo(6.7, 0.1));
      expect(result.litersPer100KmCity, closeTo(6.9, 0.1));
      expect(result.litersPer100KmTraffic, closeTo(8.6, 0.1));
      expect(
        result.blendedLitersPer100Km(
          totalRouteKm: 999.4,
          totalCityKm: 297.85,
          totalTrafficKm: 99.75,
        ),
        closeTo(6.9, 0.1),
      );
    });
  });

  group('modeKmFromSession', () {
    test('allocates tenths-of-km by integer percent', () {
      expect(
        modeKmFromSession(usageAmountTenths: 100, percent: 40),
        4.0,
      );
    });
  });
}
