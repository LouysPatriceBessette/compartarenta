// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> showHousingBrowserNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  html.Notification(title, body: body);
}
