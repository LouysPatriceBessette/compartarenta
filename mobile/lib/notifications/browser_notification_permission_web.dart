// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'notification_permission_gate.dart';

Future<NotificationSystemPermissionStatus> browserNotificationStatus() async {
  if (!html.Notification.supported) {
    return NotificationSystemPermissionStatus.unsupported;
  }
  if (kDebugMode) {
    debugPrint(
      'Browser notification permission for ${html.window.location.origin}: '
      '${html.Notification.permission ?? 'default'}',
    );
  }
  return _fromBrowserPermission(html.Notification.permission ?? 'default');
}

Future<NotificationSystemPermissionStatus> requestBrowserNotification() async {
  if (!html.Notification.supported) {
    return NotificationSystemPermissionStatus.unsupported;
  }
  final result = await html.Notification.requestPermission();
  return _fromBrowserPermission(result);
}

NotificationSystemPermissionStatus _fromBrowserPermission(String permission) {
  return switch (permission) {
    'granted' => NotificationSystemPermissionStatus.granted,
    'denied' => NotificationSystemPermissionStatus.denied,
    'default' => NotificationSystemPermissionStatus.unknown,
    _ => NotificationSystemPermissionStatus.unknown,
  };
}
