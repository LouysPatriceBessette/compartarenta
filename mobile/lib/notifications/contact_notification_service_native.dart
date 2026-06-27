import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_service.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'contact_events_v1',
  'Contact events',
  description: 'Alerts for incoming contact requests and disconnect notices.',
  importance: Importance.high,
);

const AndroidNotificationChannel _androidSilentChannel =
    AndroidNotificationChannel(
      'contact_events_silent_v1',
      'Contact events (silent)',
      description:
          'Silent alerts for incoming contact requests and disconnect notices.',
      importance: Importance.high,
      playSound: false,
    );

const String _contactsPayload = 'contacts';

bool _initialized = false;

Future<void> showContactNotification({
  required String title,
  required String body,
  required bool playSound,
  String? payload,
}) async {
  await _ensureInitialized();
  final channel = playSound ? _androidChannel : _androidSilentChannel;
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: playSound,
    ),
    iOS: DarwinNotificationDetails(presentSound: playSound),
  );

  await _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload ?? _contactsPayload,
  );
}

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  _initialized = true;

  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      PushNotificationService.dispatchLocalNotificationTap(response);
    },
  );

  final launch = await _plugin.getNotificationAppLaunchDetails();
  final response = launch?.notificationResponse;
  final payload = response?.payload;
  if (launch?.didNotificationLaunchApp == true &&
      payload != null &&
      payload.isNotEmpty) {
    PushNotificationService.dispatchLocalNotificationTap(response!);
  }

  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_androidChannel);
  await android?.createNotificationChannel(_androidSilentChannel);
}
