import 'package:compartarenta/debug/qa_e2e_meter_photo.dart';
import 'package:compartarenta/vehicle/vehicle_meter_photo_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => QaE2eFlags.setMeterPhotoOptional(false));

  test('qaE2eEffectiveMeterPhotoPath returns sentinel when QA flag is on', () {
    QaE2eFlags.setMeterPhotoOptional(true);
    expect(
      qaE2eEffectiveMeterPhotoPath(null),
      kVehicleMeterPhotoKnownUnchangedSentinel,
    );
    expect(
      qaE2eEffectiveMeterPhotoPath(''),
      kVehicleMeterPhotoKnownUnchangedSentinel,
    );
  });

  test('qaE2eEffectiveMeterPhotoPath keeps picked path', () {
    QaE2eFlags.setMeterPhotoOptional(true);
    expect(qaE2eEffectiveMeterPhotoPath('/tmp/photo.jpg'), '/tmp/photo.jpg');
  });

  test('qaE2eEffectiveMeterPhotoPath is null without QA flag', () {
    QaE2eFlags.setMeterPhotoOptional(false);
    expect(qaE2eEffectiveMeterPhotoPath(null), isNull);
  });

  test('qaE2eMeterPhotoRequired respects QA flag', () {
    QaE2eFlags.setMeterPhotoOptional(true);
    expect(qaE2eMeterPhotoRequired(otherwiseRequired: true), isFalse);
    QaE2eFlags.setMeterPhotoOptional(false);
    expect(qaE2eMeterPhotoRequired(otherwiseRequired: true), isTrue);
    expect(qaE2eMeterPhotoRequired(otherwiseRequired: false), isFalse);
  });

  test('meterPhotoOptional requires debug mode', () {
    QaE2eFlags.setMeterPhotoOptional(true);
    expect(QaE2eFlags.meterPhotoOptional, kDebugMode);
  });

  test('syncQaE2eFlagsFromPrefs restores meter photo optional from prefs', () async {
    SharedPreferences.setMockInitialValues({
      kQaE2eMeterPhotoOptionalPrefKey: true,
    });
    QaE2eFlags.setMeterPhotoOptional(false);

    await syncQaE2eFlagsFromPrefs();

    expect(QaE2eFlags.meterPhotoOptional, kDebugMode);
  });
}
