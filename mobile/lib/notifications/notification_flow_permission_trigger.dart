import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_dialog.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import 'notification_permission_gate.dart';
import 'push_notification_service.dart';

enum NotificationFlowSwitch {
  contactAddRequests,
  contactInvitationExpiration,
  housingDecisionChange,
  housingOfferExpiration,
}

enum NotificationFlowPermissionResult { continueFlow, abortFlow }

enum _NotificationFlowPromptChoice { enable, openSettings, continueWithout }

class NotificationFlowPermissionTrigger {
  const NotificationFlowPermissionTrigger({
    this.permissionGate = NotificationPermissionGate.instance,
  });

  final NotificationPermissionGate permissionGate;

  Future<NotificationFlowPermissionResult> ensure({
    required BuildContext context,
    required AppPreferences prefs,
    required Set<NotificationFlowSwitch> switches,
  }) async {
    final status = await permissionGate.status();
    final hasSystemPermission = _systemAllowsNotifications(status);
    final hasAppPermission = prefs.notificationsEnabled;
    final hasFlowPermissions = switches.every((s) => _switchEnabled(prefs, s));

    if (hasSystemPermission && hasAppPermission && hasFlowPermissions) {
      return NotificationFlowPermissionResult.continueFlow;
    }
    if (!context.mounted) return NotificationFlowPermissionResult.abortFlow;

    final l10n = AppLocalizations.of(context);
    final choice = await showAppDialog<_NotificationFlowPromptChoice>(
      context: context,
      guardKey: 'notificationFlowPermissionPrompt',
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationFlowPermissionPromptTitle),
        content: Text(l10n.notificationFlowPermissionPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              _NotificationFlowPromptChoice.continueWithout,
            ),
            child: Text(l10n.notificationFlowPermissionNoAction),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _NotificationFlowPromptChoice.openSettings),
            child: Text(l10n.notificationFlowPermissionReviewAction),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _NotificationFlowPromptChoice.enable),
            child: Text(l10n.notificationFlowPermissionEnableAction),
          ),
        ],
      ),
    );

    if (!context.mounted) return NotificationFlowPermissionResult.abortFlow;
    return switch (choice) {
      _NotificationFlowPromptChoice.enable => _enableAndContinue(
        prefs,
        switches,
      ),
      _NotificationFlowPromptChoice.openSettings => _openSettings(context),
      _NotificationFlowPromptChoice.continueWithout ||
      null => NotificationFlowPermissionResult.continueFlow,
    };
  }

  Future<NotificationFlowPermissionResult> _enableAndContinue(
    AppPreferences prefs,
    Set<NotificationFlowSwitch> switches,
  ) async {
    final status = await permissionGate.requestSystemPermission();
    if (_systemAllowsNotifications(status)) {
      await prefs.setNotificationsEnabled(true);
      for (final item in switches) {
        await _setSwitch(prefs, item, true);
      }
      await PushNotificationService.initialize();
    }
    return NotificationFlowPermissionResult.continueFlow;
  }

  NotificationFlowPermissionResult _openSettings(BuildContext context) {
    context.go('/settings/notifications');
    return NotificationFlowPermissionResult.abortFlow;
  }

  bool _systemAllowsNotifications(NotificationSystemPermissionStatus status) {
    return status == NotificationSystemPermissionStatus.granted ||
        status == NotificationSystemPermissionStatus.provisional ||
        status == NotificationSystemPermissionStatus.unsupported;
  }

  bool _switchEnabled(AppPreferences prefs, NotificationFlowSwitch item) {
    return switch (item) {
      NotificationFlowSwitch.contactAddRequests =>
        prefs.notificationContactAddRequests,
      NotificationFlowSwitch.contactInvitationExpiration =>
        prefs.notificationContactInvitationExpiration,
      NotificationFlowSwitch.housingDecisionChange =>
        prefs.notificationHousingDecisionChange,
      NotificationFlowSwitch.housingOfferExpiration =>
        prefs.notificationHousingOfferExpiration,
    };
  }

  Future<void> _setSwitch(
    AppPreferences prefs,
    NotificationFlowSwitch item,
    bool value,
  ) {
    return switch (item) {
      NotificationFlowSwitch.contactAddRequests =>
        prefs.setNotificationContactAddRequests(value),
      NotificationFlowSwitch.contactInvitationExpiration =>
        prefs.setNotificationContactInvitationExpiration(value),
      NotificationFlowSwitch.housingDecisionChange =>
        prefs.setNotificationHousingDecisionChange(value),
      NotificationFlowSwitch.housingOfferExpiration =>
        prefs.setNotificationHousingOfferExpiration(value),
    };
  }
}
