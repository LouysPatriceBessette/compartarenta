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
