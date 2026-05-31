import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/web_dev_profile_recovery.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('reconcileDevProfileFromDriftIfNeeded', () {
    test('copies self participant into prefs when profile is empty', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'onboarding.complete': true,
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const planId = 'housing:default';
      final now = DateTime.utc(2026, 5, 30);

      await db.into(db.participants).insert(
            ParticipantsCompanion.insert(
              id: '$planId:self',
              displayName: 'Monica',
              avatarId: 'mdi:2',
              createdAt: now,
            ),
          );

      final prefs = await AppPreferences.load();
      expect(prefs.hasProfile, isFalse);

      final recovered = await reconcileDevProfileFromDriftIfNeeded(db, prefs);
      expect(recovered, isTrue);
      expect(prefs.displayName, 'Monica');
      expect(prefs.avatarId, 'mdi:2');
    });

    test('does nothing when profile is already set', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'onboarding.complete': true,
        'profile.displayName': 'Louys',
        'profile.avatarId': 'mdi:1',
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final prefs = await AppPreferences.load();
      final recovered = await reconcileDevProfileFromDriftIfNeeded(db, prefs);
      expect(recovered, isFalse);
      expect(prefs.displayName, 'Louys');
    });
  });
}
