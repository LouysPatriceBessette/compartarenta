import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import 'push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!PushNotificationService.isHousingProposalRemoteMessage(message)) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  try {
    await PushNotificationService.showRemoteMessageAsLocalNotification(
      message,
      isBackgroundIsolate: true,
    );
  } catch (e, st) {
    log('firebaseMessagingBackgroundHandler', error: e, stackTrace: st);
  }
}
