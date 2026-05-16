import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';
import '../prefs/app_preferences.dart';
import 'browser_notification_permission_stub.dart'
    if (dart.library.html) 'browser_notification_permission_web.dart';

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
      return browserNotificationStatus();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return _fromPermissionStatus(status);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _ensureFirebaseInitialized();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    return NotificationSystemPermissionStatus.unsupported;
  }

  @override
  Future<NotificationSystemPermissionStatus> request() async {
    if (kIsWeb) {
      return requestBrowserNotification();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return _fromPermissionStatus(status);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _ensureFirebaseInitialized();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    return NotificationSystemPermissionStatus.unsupported;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

  Future<NotificationSystemPermissionStatus> requestSystemPermission() async {
    final current = await client.getStatus();
    if (current == NotificationSystemPermissionStatus.granted ||
        current == NotificationSystemPermissionStatus.provisional ||
        current == NotificationSystemPermissionStatus.unsupported) {
      return current;
    }
    return client.request();
  }

  Future<NotificationSystemPermissionStatus> ensureForUserAction({
    AppPreferences? prefs,
  }) async {
    if (prefs != null && !prefs.notificationsEnabled) {
      return client.getStatus();
    }

    return requestSystemPermission();
  }
}
