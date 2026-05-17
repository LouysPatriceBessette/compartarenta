import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../app_root_navigator.dart';

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
    DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
    title,
    body,
    details,
    payload: _contactsPayload,
  );
}

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  _initialized = true;

  await _plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != _contactsPayload) return;
      final ctx = appRootNavigatorKey.currentContext;
      if (ctx == null) return;
      ctx.go('/contacts');
    },
  );

  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_androidChannel);
  await android?.createNotificationChannel(_androidSilentChannel);
}
