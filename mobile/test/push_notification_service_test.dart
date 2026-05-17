import 'package:compartarenta/notifications/push_notification_service.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PushNotificationService', () {
    test(
      'should gate housing proposal notifications with app preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications.enabled': true,
          'notifications.housing.planSubmission': true,
        });
        var prefs = await AppPreferences.load();

        expect(
          PushNotificationService.shouldDisplayHousingProposalNotification(
            prefs,
          ),
          isTrue,
        );

        await prefs.setNotificationHousingPlanSubmission(false);
        expect(
          PushNotificationService.shouldDisplayHousingProposalNotification(
            prefs,
          ),
          isFalse,
        );

        await prefs.setNotificationHousingPlanSubmission(true);
        await prefs.setNotificationsEnabled(false);
        expect(
          PushNotificationService.shouldDisplayHousingProposalNotification(
            prefs,
          ),
          isFalse,
        );
      },
    );
  });
}
