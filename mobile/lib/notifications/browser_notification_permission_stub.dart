import 'notification_permission_gate.dart';

Future<NotificationSystemPermissionStatus> browserNotificationStatus() async {
  return NotificationSystemPermissionStatus.unsupported;
}

Future<NotificationSystemPermissionStatus> requestBrowserNotification() async {
  return NotificationSystemPermissionStatus.unsupported;
}
