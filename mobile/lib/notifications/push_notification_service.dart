import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../app_root_navigator.dart';
import '../db/app_database.dart';
import '../housing/amendment/housing_amendment_summary.dart';
import '../housing/proposals/housing_proposal_transport_service.dart';
import '../housing/housing_navigation_intent.dart';
import '../screens/housing/housing_amendment_detail_screen.dart';
import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import 'closed_app_push_registration_service.dart';
import 'housing_browser_notification_stub.dart'
    if (dart.library.html) 'housing_browser_notification_web.dart'
    as housing_browser;
import 'wake_inbox_background_poll.dart';

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
        description:
            'Alerts when a co-participant sends a housing plan proposal.',
        importance: Importance.high,
      );
  static const AndroidNotificationChannel
  _androidSilentChannel = AndroidNotificationChannel(
    'housing_proposals_silent_v1',
    'Housing proposals (silent)',
    description:
        'Silent alerts when a co-participant sends a housing plan proposal.',
    importance: Importance.high,
    playSound: false,
  );

  static const String _housingTapPayload = 'housing_proposal';
  static const String _housingAmendmentPrefix = 'housing_amendment:';
  static const String _housingRealizedExpenseReviewPrefix =
      'housing_realized_expense:';

  static const List<String> _housingKinds = <String>[
    'housing_proposal',
    'expensePlanAgreementProposal',
  ];

  static bool _started = false;
  static bool _localStarted = false;

  static AppLocalizations _l10nForUiLocale() {
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
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
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e, st) {
      debugPrint(
        'PushNotificationService: Firebase.initializeApp failed: '
        '$e\n$st',
      );
      _started = false;
      return;
    }

    await _ensureLocalNotificationsInitialized(_plugin);

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
      debugPrint(
        'PushNotificationService: FCM token refreshed (length '
        '${token.length})',
      );
      unawaited(ClosedAppPushRegistrationService.maybeInstance?.sync());
    });

    unawaited(ClosedAppPushRegistrationService.maybeInstance?.sync());
  }

  static Future<void> _ensureAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);
    await android?.createNotificationChannel(_androidSilentChannel);
  }

  static Future<void> _ensureLocalNotificationsInitialized(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (identical(plugin, _plugin) && _localStarted) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: dispatchLocalNotificationTap,
    );
    await _ensureAndroidChannel();
    if (identical(plugin, _plugin)) {
      _localStarted = true;
      final launch = await plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true &&
          response?.payload == _housingTapPayload) {
        dispatchLocalNotificationTap(response!);
      }
    }
  }

  /// Shared tap handler for all local notification payloads (housing + contacts).
  static void dispatchLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (payload == _housingTapPayload) {
      _navigateToHousing();
      return;
    }
    if (payload.startsWith(_housingAmendmentPrefix)) {
      final planId = payload.substring(_housingAmendmentPrefix.length);
      if (planId.isNotEmpty) {
        _navigateToHousingAmendmentDetail(planId);
      } else {
        _navigateToHousing();
      }
      return;
    }
    if (payload.startsWith(_housingRealizedExpenseReviewPrefix)) {
      final expenseId = payload.substring(
        _housingRealizedExpenseReviewPrefix.length,
      );
      if (expenseId.isNotEmpty) {
        _navigateToRealizedExpenseReview(expenseId);
      }
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    if (isWakeForInboxRemoteMessage(message)) {
      unawaited(runWakeInboxPollOnce());
      return;
    }
    if (!isHousingProposalRemoteMessage(message)) return;
    unawaited(
      showRemoteMessageAsLocalNotification(message, isBackgroundIsolate: false),
    );
  }

  /// Data-only wake from the relay (`v` is ignored for forward compatibility).
  static bool isWakeForInboxRemoteMessage(RemoteMessage message) {
    return message.data['kind'] == 'wake_for_inbox';
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

  static bool shouldDisplayHousingProposalNotification(AppPreferences prefs) {
    return prefs.notificationsEnabled &&
        prefs.notificationHousingPlanSubmission;
  }

  static bool shouldDisplayHousingDecisionNotification(AppPreferences prefs) {
    return prefs.notificationsEnabled &&
        prefs.notificationHousingDecisionChange;
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

    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        l10n.pushNotificationHousingProposalTitle;
    final body =
        message.notification?.body ??
        message.data['body'] as String? ??
        l10n.pushNotificationHousingProposalBody;

    final plugin = isBackgroundIsolate
        ? FlutterLocalNotificationsPlugin()
        : _plugin;

    if (isBackgroundIsolate) {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_androidChannel);
      await android?.createNotificationChannel(_androidSilentChannel);
    }

    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingProposalNotification(prefs)) {
      return;
    }
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;

    final androidDetails = AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: playSound,
    );
    final iosDetails = DarwinNotificationDetails(presentSound: playSound);
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id =
        message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);

    await plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: _housingTapPayload,
    );
  }

  static Future<void> showLocalHousingProposalNotification({
    String? senderDisplayName,
    String? planId,
  }) async {
    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingProposalNotification(prefs)) return;

    var payload = _housingTapPayload;
    if (planId != null && planId.isNotEmpty) {
      final db = AppDatabase.processScope;
      if (await pendingRevisionIsAmendment(db, planId)) {
        payload = '$_housingAmendmentPrefix$planId';
      }
    }

    final l10n = _l10nForUiLocale();
    final title = l10n.pushNotificationHousingProposalTitle;
    final body = l10n.pushNotificationHousingProposalBody;
    await _ensureLocalNotificationsInitialized(_plugin);
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: playSound,
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      payload: payload,
    );
  }

  static Future<void> showLocalHousingRealizedExpenseNotification({
    required String senderDisplayName,
    String? expenseId,
  }) async {
    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingDecisionNotification(prefs)) return;

    final l10n = _l10nForUiLocale();
    final title = l10n.pushNotificationHousingRealizedExpenseTitle;
    final body = senderDisplayName.trim().isEmpty
        ? l10n.pushNotificationHousingRealizedExpenseBody
        : l10n.pushNotificationHousingRealizedExpenseBodyFrom(
            senderDisplayName.trim(),
          );

    final tapPayload = expenseId == null || expenseId.isEmpty
        ? _housingTapPayload
        : '$_housingRealizedExpenseReviewPrefix$expenseId';

    if (kIsWeb) {
      await housing_browser.showHousingBrowserNotification(
        title: title,
        body: body,
        expenseId: expenseId,
      );
      return;
    }

    await _ensureLocalNotificationsInitialized(_plugin);
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: playSound,
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      payload: tapPayload,
    );
  }

  static Future<void> showLocalHousingRealizedExpenseRejectedNotification({
    required String senderDisplayName,
  }) async {
    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingDecisionNotification(prefs)) return;

    final l10n = _l10nForUiLocale();
    final title = l10n.pushNotificationHousingRealizedExpenseRejectedTitle;
    final body = senderDisplayName.trim().isEmpty
        ? l10n.pushNotificationHousingRealizedExpenseRejectedBody
        : l10n.pushNotificationHousingRealizedExpenseRejectedBodyFrom(
            senderDisplayName.trim(),
          );

    if (kIsWeb) {
      await housing_browser.showHousingBrowserNotification(
        title: title,
        body: body,
      );
      return;
    }

    await _ensureLocalNotificationsInitialized(_plugin);
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: playSound,
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      payload: _housingTapPayload,
    );
  }

  static void _navigateToRealizedExpenseReview(String expenseId) {
    HousingNavigationIntent.requestReview(expenseId);
    _navigateToHousing();
  }

  static Future<void> showLocalHousingDecisionNotification({
    required String senderDisplayName,
  }) async {
    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingDecisionNotification(prefs)) return;

    final l10n = _l10nForUiLocale();
    final title = l10n.pushNotificationHousingDecisionTitle;
    final body = senderDisplayName.trim().isEmpty
        ? l10n.pushNotificationHousingDecisionBody
        : l10n.pushNotificationHousingDecisionBodyFrom(
            senderDisplayName.trim(),
          );

    if (kIsWeb) {
      await housing_browser.showHousingBrowserNotification(
        title: title,
        body: body,
      );
      return;
    }

    await _ensureLocalNotificationsInitialized(_plugin);
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: playSound,
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      payload: _housingTapPayload,
    );
  }

  static Future<void> showLocalHousingResponseFailureNotification({
    required String errorCode,
  }) async {
    final prefs = await AppPreferences.load();
    if (!shouldDisplayHousingDecisionNotification(prefs)) return;

    final l10n = _l10nForUiLocale();
    final title = l10n.pushNotificationHousingDecisionTitle;
    final body = switch (errorCode) {
      'relay_unavailable' =>
        l10n.pushNotificationHousingResponseFailureRelayUnavailableBody,
      'unknown' => l10n.pushNotificationHousingResponseFailureUnknownBody,
      'send_failed' => l10n.pushNotificationHousingResponseFailureSendBody,
      'local_error' =>
        l10n.pushNotificationHousingResponseFailureLocalErrorBody,
      _ => l10n.pushNotificationHousingResponseFailureLocalErrorBody,
    };
    await _ensureLocalNotificationsInitialized(_plugin);
    final playSound = prefs.notificationSoundEnabled;
    final androidChannel = playSound ? _androidChannel : _androidSilentChannel;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: playSound,
        ),
        iOS: DarwinNotificationDetails(presentSound: playSound),
      ),
      payload: _housingTapPayload,
    );
  }

  static void _navigateToHousing() {
    void attempt([int tries = 0]) {
      final ctx = appRootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        unawaited(
          HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes(),
        );
        final router = GoRouter.of(ctx);
        router.go('/housing');
        return;
      }
      if (tries >= 30) {
        debugPrint(
          'PushNotificationService: navigate to /housing skipped (no context)',
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt(tries + 1));
    }

    attempt();
  }

  /// Notification tap: open housing hub, then amendment detail above it.
  static void _navigateToHousingAmendmentDetail(String planId) {
    void attempt([int tries = 0]) {
      final ctx = appRootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        unawaited(
          HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes(),
        );
        final router = GoRouter.of(ctx);
        router.go('/housing');
        void pushDetail([int pushTries = 0]) {
          final navCtx = appRootNavigatorKey.currentContext;
          if (navCtx == null || !navCtx.mounted) {
            if (pushTries >= 40) return;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => pushDetail(pushTries + 1),
            );
            return;
          }
          unawaited(
            AppPreferences.load().then((prefs) async {
              if (!navCtx.mounted) return;
              final pendingId = await HousingProposalTransportService(
                AppDatabase.processScope,
              ).pendingRevisionIdForPlan(planId);
              if (!navCtx.mounted) return;
              await Navigator.of(navCtx).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HousingAmendmentDetailScreen(
                    db: AppDatabase.processScope,
                    planId: planId,
                    prefs: prefs,
                    revisionId: pendingId,
                  ),
                ),
              );
            }),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => pushDetail());
        return;
      }
      if (tries >= 30) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt(tries + 1));
    }

    attempt();
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
