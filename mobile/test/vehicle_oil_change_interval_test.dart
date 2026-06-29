import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:compartarenta/vehicle/vehicle_oil_change_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOilChangeIntervalToStoredTenths land', () {
    test('1.5 x1000 km → 15000 tenths', () {
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '1.5',
          usesHorometer: false,
          distanceUnit: DistanceUnit.km,
        ),
        15000,
      );
    });

    test('5 x1000 km → 50000 tenths (default scale)', () {
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '5',
          usesHorometer: false,
          distanceUnit: DistanceUnit.km,
        ),
        50000,
      );
    });

    test('rejects below 1 and above 20', () {
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '0.9',
          usesHorometer: false,
          distanceUnit: DistanceUnit.km,
        ),
        isNull,
      );
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '21',
          usesHorometer: false,
          distanceUnit: DistanceUnit.km,
        ),
        isNull,
      );
    });
  });

  group('parseOilChangeIntervalToStoredTenths boat', () {
    test('100 h → 1000 tenths', () {
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '100',
          usesHorometer: true,
          distanceUnit: DistanceUnit.km,
        ),
        1000,
      );
    });

    test('rejects below 50 and above 500', () {
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '49',
          usesHorometer: true,
          distanceUnit: DistanceUnit.km,
        ),
        isNull,
      );
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: '501',
          usesHorometer: true,
          distanceUnit: DistanceUnit.km,
        ),
        isNull,
      );
    });
  });

  group('formatOilChangeIntervalForDisplay', () {
    test('round-trips land km multiplier', () {
      const stored = 15000;
      final text = formatOilChangeIntervalForDisplay(
        storedTenths: stored,
        usesHorometer: false,
        distanceUnit: DistanceUnit.km,
      );
      expect(text, '1.5');
      expect(
        parseOilChangeIntervalToStoredTenths(
          text: text,
          usesHorometer: false,
          distanceUnit: DistanceUnit.km,
        ),
        stored,
      );
    });
  });
}
