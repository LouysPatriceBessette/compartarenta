import 'package:compartarenta/vehicle/vehicle_meter_photo_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known unchanged sentinel is not a displayable photo', () {
    expect(
      isKnownUnchangedMeterPhotoPath(kVehicleMeterPhotoKnownUnchangedSentinel),
      isTrue,
    );
    expect(
      meterReadingHasDisplayablePhoto(kVehicleMeterPhotoKnownUnchangedSentinel),
      isFalse,
    );
    expect(meterReadingHasDisplayablePhoto('photos/odometer.jpg'), isTrue);
    expect(meterReadingHasDisplayablePhoto(''), isFalse);
  });
}
