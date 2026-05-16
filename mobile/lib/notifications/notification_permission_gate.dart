import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../prefs/app_preferences.dart';

enum NotificationSystemPermissionStatus {
  unsupported,
  unknown,
  granted,
  denied,
  provisional,
}

abstract class NotificationPermissionClient {
  Future<NotificationSystemPermissionStatus> getStatus();

  Future<NotificationSystemPermissionStatus> request();
}

class DefaultNotificationPermissionClient
    implements NotificationPermissionClient {
  const DefaultNotificationPermissionClient();

  @override
  Future<NotificationSystemPermissionStatus> getStatus() async {
    if (kIsWeb) {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return _fromPermissionStatus(status);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    return NotificationSystemPermissionStatus.unsupported;
  }

  @override
  Future<NotificationSystemPermissionStatus> request() async {
    if (kIsWeb) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return _fromPermissionStatus(status);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    return NotificationSystemPermissionStatus.unsupported;
  }

  NotificationSystemPermissionStatus _fromPermissionStatus(
    PermissionStatus status,
  ) {
    if (status.isGranted || status.isLimited) {
      return NotificationSystemPermissionStatus.granted;
    }
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      return NotificationSystemPermissionStatus.denied;
    }
    return NotificationSystemPermissionStatus.unknown;
  }

  NotificationSystemPermissionStatus _fromFirebaseAuthorization(
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized =>
        NotificationSystemPermissionStatus.granted,
      AuthorizationStatus.provisional =>
        NotificationSystemPermissionStatus.provisional,
      AuthorizationStatus.denied => NotificationSystemPermissionStatus.denied,
      AuthorizationStatus.notDetermined =>
        NotificationSystemPermissionStatus.unknown,
    };
  }
}

class NotificationPermissionGate {
  const NotificationPermissionGate({
    this.client = const DefaultNotificationPermissionClient(),
  });

  static const instance = NotificationPermissionGate();

  final NotificationPermissionClient client;

  Future<NotificationSystemPermissionStatus> status() => client.getStatus();

  Future<NotificationSystemPermissionStatus> ensureForUserAction({
    AppPreferences? prefs,
  }) async {
    if (prefs != null && !prefs.notificationsEnabled) {
      return client.getStatus();
    }

    final current = await client.getStatus();
    if (current == NotificationSystemPermissionStatus.granted ||
        current == NotificationSystemPermissionStatus.provisional ||
        current == NotificationSystemPermissionStatus.unsupported) {
      return current;
    }
    return client.request();
  }
}
