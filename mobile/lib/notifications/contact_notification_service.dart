import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import 'notification_permission_gate.dart';
import 'contact_notification_service_stub.dart'
    if (dart.library.html) 'contact_notification_service_web.dart'
    if (dart.library.io) 'contact_notification_service_native.dart'
    as impl;

abstract class ContactNotificationSink {
  Future<void> contactAddRequestReceived({required String displayName});

  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  });

  Future<void> contactAddRequestFailed({required String errorCode});

  Future<void> contactDisconnected({required String displayName});
}

class DefaultContactNotificationSink implements ContactNotificationSink {
  const DefaultContactNotificationSink();

  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = _l10nForUiLocale();
    await impl.showContactNotification(
      title: l10n.pushNotificationContactAddRequestTitle,
      body: l10n.pushNotificationContactAddRequestBody(displayName),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  }) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = _l10nForUiLocale();
    await impl.showContactNotification(
      title: l10n.pushNotificationContactAddRequestTitle,
      body: accepted
          ? l10n.pushNotificationContactAddRequestAcceptedBody(displayName)
          : l10n.pushNotificationContactAddRequestRejectedBody(displayName),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> contactAddRequestFailed({required String errorCode}) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = _l10nForUiLocale();
    await impl.showContactNotification(
      title: l10n.pushNotificationContactAddRequestTitle,
      body: _connectionRequestFailureBody(l10n, errorCode),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> contactDisconnected({required String displayName}) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled ||
        !prefs.notificationContactDisconnection) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = _l10nForUiLocale();
    await impl.showContactNotification(
      title: l10n.pushNotificationContactDisconnectionTitle,
      body: l10n.pushNotificationContactDisconnectionBody(displayName),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  Future<bool> _systemAllowsNotifications() async {
    final status = await NotificationPermissionGate.instance.status();
    return status == NotificationSystemPermissionStatus.granted ||
        status == NotificationSystemPermissionStatus.provisional;
  }

  AppLocalizations _l10nForUiLocale() {
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (lang == 'fr') {
      return lookupAppLocalizations(const Locale('fr'));
    }
    if (lang == 'es') {
      return lookupAppLocalizations(const Locale('es'));
    }
    return lookupAppLocalizations(const Locale('en'));
  }

  String _connectionRequestFailureBody(AppLocalizations l10n, String code) {
    return switch (code) {
      'expired_code' ||
      'expired' => l10n.pushNotificationContactAddRequestExpiredCodeBody,
      'already_completed' || 'nonce_already_consumed' =>
        l10n.pushNotificationContactAddRequestInvalidCodeBody,
      'relay_error' => l10n.pushNotificationContactAddRequestRelayErrorBody,
      'relay_unavailable' =>
        l10n.pushNotificationContactAddRequestRelayUnavailableBody,
      _ => l10n.pushNotificationContactAddRequestUnknownFailureBody,
    };
  }
}
