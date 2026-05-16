// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import '../prefs/app_preferences.dart';
import 'developer_test_notification_result.dart';

Future<DeveloperTestNotificationResult> sendDeveloperTestNotification(
  AppPreferences prefs,
) async {
  if (!html.Notification.supported) {
    return DeveloperTestNotificationResult.unsupported;
  }
  if (!prefs.notificationsEnabled) {
    return DeveloperTestNotificationResult.appNotificationsDisabled;
  }
  if (html.Notification.permission != 'granted') {
    return DeveloperTestNotificationResult.permissionDenied;
  }

  try {
    html.Notification('TEST', body: 'TEST');
    return DeveloperTestNotificationResult.shown;
  } catch (_) {
    return DeveloperTestNotificationResult.failed;
  }
}
