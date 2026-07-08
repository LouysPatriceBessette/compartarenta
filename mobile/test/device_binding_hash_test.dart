import 'package:compartarenta/device/device_binding_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDeviceBindingId', () {
    test('is deterministic for the same signal map', () async {
      const signals = {
        'build_model': 'Pixel 6',
        'sdk_int': '34',
        'physical_width': '1080.0',
      };
      final a = await computeDeviceBindingId(signals);
      final b = await computeDeviceBindingId(signals);
      expect(a, equals(b));
      expect(a, isNotEmpty);
    });

    test('is independent of map insertion order', () async {
      const first = {
        'alpha': '1',
        'beta': '2',
        'gamma': '3',
      };
      const second = {
        'gamma': '3',
        'alpha': '1',
        'beta': '2',
      };
      expect(
        canonicalDeviceBindingPayload(first),
        canonicalDeviceBindingPayload(second),
      );
      expect(
        await computeDeviceBindingId(first),
        await computeDeviceBindingId(second),
      );
    });

    test('changes when any signal value changes', () async {
      const base = {
        'build_model': 'Pixel 6',
        'sdk_int': '34',
      };
      const tweaked = {
        'build_model': 'Pixel 7',
        'sdk_int': '34',
      };
      expect(
        await computeDeviceBindingId(base),
        isNot(equals(await computeDeviceBindingId(tweaked))),
      );
    });

    test('rejects empty signal map', () async {
      expect(
        () => computeDeviceBindingId({}),
        throwsArgumentError,
      );
    });
  });
}
