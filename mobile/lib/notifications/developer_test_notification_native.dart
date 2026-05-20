import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../prefs/app_preferences.dart';
import 'developer_test_notification_result.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidTestChannel =
    AndroidNotificationChannel(
      'developer_test_notifications_v1',
      'Developer test notifications',
      description: 'Development-only notifications used to test permissions.',
      importance: Importance.high,
    );

bool _initialized = false;

Future<DeveloperTestNotificationResult> sendDeveloperTestNotification(
  AppPreferences prefs,
) async {
  if (!prefs.notificationsEnabled) {
    return DeveloperTestNotificationResult.appNotificationsDisabled;
  }

  try {
    final permission = await Permission.notification.status;
    if (!permission.isGranted && !permission.isLimited) {
      return DeveloperTestNotificationResult.permissionDenied;
    }

    await _ensureInitialized();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: 'TEST',
      body: 'TEST',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'developer_test_notifications_v1',
          'Developer test notifications',
          channelDescription:
              'Development-only notifications used to test permissions.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return DeveloperTestNotificationResult.shown;
  } catch (_) {
    return DeveloperTestNotificationResult.failed;
  }
}

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  _initialized = true;

  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_androidTestChannel);
}
