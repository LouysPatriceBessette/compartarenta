import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/vehicle/vehicle_meter_reading_effective.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleMeterReading _reading({
  required String id,
  required int value,
  String? supersedesReadingId,
  bool isCorrection = false,
  String correctionNote = '',
}) {
  return VehicleMeterReading(
    id: id,
    vehicleId: 'v1',
    value: value,
    unit: 'odometer_km',
    photoPath: 'p',
    recordedAt: DateTime.utc(2027, 1, 1, 12),
    recordedByContactId: 'owner',
    vehicleUseId: null,
    readingRole: isCorrection ? 'correction' : 'sessionEnd',
    isCorrection: isCorrection,
    correctionNote: correctionNote,
    negativeGapAcknowledged: false,
    isFullTank: null,
    tankFillFraction: null,
    resolvedAt: null,
    supersedesReadingId: supersedesReadingId,
  );
}

void main() {
  group('effectiveMeterReadingsChronological', () {
    test('excludes superseded original and uses replacement value', () {
      final original = _reading(id: 'old', value: 500200);
      final replacement = _reading(
        id: 'new',
        value: 500300,
        supersedesReadingId: 'old',
        isCorrection: true,
        correctionNote: 'replace|correctTrigger',
      );
      final effective = effectiveMeterReadingsChronological([
        original,
        replacement,
      ]);
      expect(effective, hasLength(1));
      expect(effective.single.id, 'new');
      expect(effective.single.value, 500300);
    });

    test('latestEffectiveMeterReading returns replacement', () {
      final original = _reading(id: 'old', value: 500200);
      final replacement = _reading(
        id: 'new',
        value: 500300,
        supersedesReadingId: 'old',
        isCorrection: true,
      );
      final latest = latestEffectiveMeterReading([original, replacement]);
      expect(latest?.id, 'new');
    });
  });
}
