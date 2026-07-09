import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import 'notification_localizations.dart';
import 'notification_permission_gate.dart';
import 'notification_qa_prefix.dart';
import 'contact_notification_service_stub.dart'
    if (dart.library.html) 'contact_notification_service_web.dart'
    if (dart.library.io) 'contact_notification_service_native.dart'
    as impl;

abstract class ContactNotificationSink {
  Future<void> contactAddRequestReceived({required String displayName});

  /// Inviter-side: someone redeemed a valid invitation code and is now
  /// connected (no manual accept step).
  Future<void> contactAddedViaInvitation({required String displayName});

  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  });

  Future<void> contactAddRequestFailed({required String errorCode});

  /// Invitee-side: inviter rejected a duplicate reconnect because module
  /// work is anchored on the pre-existing contact (bug 1.22 extension).
  Future<void> contactDuplicateModuleAnchorRejected();

  Future<void> contactDisconnected({required String displayName});

  /// Target-side notification for plan-mediated establishment.
  Future<void> planPeerEstablishmentRequestReceived({
    required String requesterDisplayName,
    required String proposerDisplayName,
    required String planId,
  });
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

    final l10n = l10nForNotificationLocale(prefs: prefs);
    await impl.showContactNotification(
      title: notificationQaPrefix(13, l10n.pushNotificationContactAddRequestTitle),
      body: notificationQaPrefix(
        13,
        l10n.pushNotificationContactAddRequestBody(displayName),
      ),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> contactAddedViaInvitation({required String displayName}) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = l10nForNotificationLocale(prefs: prefs);
    await impl.showContactNotification(
      title: notificationQaPrefix(14, l10n.pushNotificationContactAddRequestTitle),
      body: notificationQaPrefix(
        14,
        l10n.pushNotificationContactAddedViaInvitationBody(displayName),
      ),
      playSound: prefs.notificationSoundEnabled,
      payload: 'contacts',
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

    final l10n = l10nForNotificationLocale(prefs: prefs);
    final resolvedBody = accepted
        ? l10n.pushNotificationContactAddRequestAcceptedBody(displayName)
        : l10n.pushNotificationContactAddRequestRejectedBody(displayName);
    await impl.showContactNotification(
      title: notificationQaPrefix(15, l10n.pushNotificationContactAddRequestTitle),
      body: notificationQaPrefix(15, resolvedBody),
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

    final l10n = l10nForNotificationLocale(prefs: prefs);
    await impl.showContactNotification(
      title: notificationQaPrefix(16, l10n.pushNotificationContactAddRequestTitle),
      body: notificationQaPrefix(
        16,
        _connectionRequestFailureBody(l10n, errorCode),
      ),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> contactDuplicateModuleAnchorRejected() async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = l10nForNotificationLocale(prefs: prefs);
    await impl.showContactNotification(
      title: notificationQaPrefix(
        19,
        l10n.pushNotificationContactAddRequestTitle,
      ),
      body: notificationQaPrefix(
        19,
        l10n.pushNotificationContactDuplicateModuleAnchorRejectedBody,
      ),
      playSound: prefs.notificationSoundEnabled,
      payload: 'contacts',
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

    final l10n = l10nForNotificationLocale(prefs: prefs);
    await impl.showContactNotification(
      title: notificationQaPrefix(
        17,
        l10n.pushNotificationContactDisconnectionTitle,
      ),
      body: notificationQaPrefix(
        17,
        l10n.pushNotificationContactDisconnectionBody(displayName),
      ),
      playSound: prefs.notificationSoundEnabled,
    );
  }

  @override
  Future<void> planPeerEstablishmentRequestReceived({
    required String requesterDisplayName,
    required String proposerDisplayName,
    required String planId,
  }) async {
    final prefs = await AppPreferences.load();
    if (!prefs.notificationsEnabled || !prefs.notificationContactAddRequests) {
      return;
    }
    if (!await _systemAllowsNotifications()) return;

    final l10n = l10nForNotificationLocale(prefs: prefs);
    final trimmedPlanId = planId.trim();
    await impl.showContactNotification(
      title: notificationQaPrefix(18, l10n.pushNotificationContactAddRequestTitle),
      body: notificationQaPrefix(
        18,
        l10n.pushNotificationPlanPeerEstablishmentRequestBody(
          requesterDisplayName,
          proposerDisplayName,
        ),
      ),
      playSound: prefs.notificationSoundEnabled,
      payload: trimmedPlanId.isEmpty
          ? null
          : 'plan_peer_establishment:$trimmedPlanId',
    );
  }

  Future<bool> _systemAllowsNotifications() async {
    final status = await NotificationPermissionGate.instance.status();
    return status == NotificationSystemPermissionStatus.granted ||
        status == NotificationSystemPermissionStatus.provisional;
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
