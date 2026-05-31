import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('web dev host prefs snapshot', () {
    test('exportDevHostSnapshot round-trips onboarding and profile keys', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'onboarding.complete': true,
        'profile.displayName': 'Monica',
        'profile.avatarId': 'mdi:2',
        'prefs.currency': 'CAD',
        'prefs.dateFormat': 'yyyy-MM-dd',
        'prefs.distanceUnit': 'km',
        'plans.enabled': <String>['housing'],
      });

      final source = await AppPreferences.load();
      final exported = source.exportDevHostSnapshot();

      SharedPreferences.setMockInitialValues({});
      final target = await AppPreferences.load();
      expect(target.hasProfile, isFalse);

      await target.importDevHostSnapshot(exported);
      expect(target.onboardingComplete, isTrue);
      expect(target.displayName, 'Monica');
      expect(target.avatarId, 'mdi:2');
      expect(target.currency, 'CAD');
      expect(target.planTypes.map((p) => p.name), contains('housing'));
    });
  });
}
