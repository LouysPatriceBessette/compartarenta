import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_notification_background.dart';

void registerPushBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
