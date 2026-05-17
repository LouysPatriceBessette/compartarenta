// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> showContactNotification({
  required String title,
  required String body,
  required bool playSound,
}) async {
  if (!html.Notification.supported ||
      html.Notification.permission != 'granted') {
    return;
  }
  html.Notification(title, body: body);
}
