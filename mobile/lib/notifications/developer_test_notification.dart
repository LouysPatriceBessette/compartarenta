import '../prefs/app_preferences.dart';
import 'developer_test_notification_result.dart';
import 'developer_test_notification_stub.dart'
    if (dart.library.html) 'developer_test_notification_web.dart'
    if (dart.library.io) 'developer_test_notification_native.dart'
    as impl;

Future<DeveloperTestNotificationResult> sendDeveloperTestNotification(
  AppPreferences prefs,
) {
  return impl.sendDeveloperTestNotification(prefs);
}
