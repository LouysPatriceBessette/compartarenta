import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_root_navigator.dart';
import '../firebase_options.dart';
import '../l10n/app_localizations.dart';

/// FCM + local notifications for housing proposals (and future message types).
///
/// Requires a real Firebase project: replace [DefaultFirebaseOptions] via
/// `flutterfire configure` and ship a matching `android/app/google-services.json`.
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'housing_proposals_v1',
    'Housing proposals',
    description: 'Alerts when a co-participant sends a housing plan proposal.',
    importance: Importance.high,
  );

  static const String _housingTapPayload = 'housing_proposal';

  static const List<String> _housingKinds = <String>[
    'housing_proposal',
    'expensePlanAgreementProposal',
  ];

  static bool _started = false;

  static AppLocalizations _l10nForUiLocale() {
    final lang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (lang == 'fr') {
      return lookupAppLocalizations(const Locale('fr'));
    }
    if (lang == 'es') {
      return lookupAppLocalizations(const Locale('es'));
    }
    return lookupAppLocalizations(const Locale('en'));
  }

  static Future<void> initialize() async {
    if (_started) return;
    _started = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('PushNotificationService: Firebase.initializeApp failed: '
          '$e\n$st');
      _started = false;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _ensureAndroidChannel();

    await _requestPermissions();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _handleOpenData(Map<String, dynamic>.from(m.data));
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleOpenData(Map<String, dynamic>.from(initial.data));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('PushNotificationService: FCM token refreshed (length '
          '${token.length})');
    });
  }

  static Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      debugPrint('PushNotificationService: Android notification permission '
          '$status');
    }
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      'PushNotificationService: FCM permission '
      '${settings.authorizationStatus}',
    );
  }

  static void _onForegroundMessage(RemoteMessage message) {
    if (!isHousingProposalRemoteMessage(message)) return;
    unawaited(
      showRemoteMessageAsLocalNotification(
        message,
        isBackgroundIsolate: false,
      ),
    );
  }

  static bool isHousingProposalRemoteMessage(RemoteMessage message) {
    final kind = message.data['kind'] as String?;
    if (kind != null && _housingKinds.contains(kind)) return true;
    if (message.notification != null) {
      final t = message.notification!.title?.toLowerCase() ?? '';
      if (t.contains('proposal') || t.contains('proposition')) return true;
    }
    return false;
  }

  /// Shows a heads-up notification. Used from the foreground isolate and from
  /// the FCM background isolate (separate [FlutterLocalNotificationsPlugin] there).
  static Future<void> showRemoteMessageAsLocalNotification(
    RemoteMessage message, {
    required bool isBackgroundIsolate,
  }) async {
    if (isBackgroundIsolate && message.notification != null) {
      // Background + notification payload: Android usually shows the system
      // notification already; avoid a duplicate tray entry.
      return;
    }

    final l10n = isBackgroundIsolate
        ? lookupAppLocalizations(const Locale('en'))
        : _l10nForUiLocale();

    final title = message.notification?.title ??
        message.data['title'] as String? ??
        l10n.pushNotificationHousingProposalTitle;
    final body = message.notification?.body ??
        message.data['body'] as String? ??
        l10n.pushNotificationHousingProposalBody;

    final plugin = isBackgroundIsolate
        ? FlutterLocalNotificationsPlugin()
        : _plugin;

    if (isBackgroundIsolate) {
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_androidChannel);
    }

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);

    await plugin.show(
      id,
      title,
      body,
      details,
      payload: _housingTapPayload,
    );
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != _housingTapPayload) return;
    _navigateToHousing();
  }

  static void _navigateToHousing() {
    final ctx = appRootNavigatorKey.currentContext;
    if (ctx == null) return;
    ctx.go('/housing');
  }

  static void _handleOpenData(Map<String, dynamic> data) {
    final kind = data['kind'] as String?;
    if (kind != null && _housingKinds.contains(kind)) {
      _navigateToHousing();
      return;
    }
    if (data['openHousing'] == 'true' || data['route'] == '/housing') {
      _navigateToHousing();
    }
  }
}
