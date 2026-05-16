import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _generalNotifications = true;
  bool _contactAddRequests = true;
  bool _contactDisconnectionNotices = true;
  bool _contactInvitationExpiration = true;
  bool _housingPlanSubmissionReceived = true;
  bool _housingParticipantDecisionChanged = true;
  bool _housingOfferExpiration = true;
  bool _notificationSound = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotificationsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsNotificationsGeneralSection),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsNotificationsSystemPermissionTitle),
            subtitle: Text(l10n.settingsNotificationsSystemPermissionBody),
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsGeneralSwitchTitle),
            subtitle: Text(l10n.settingsNotificationsGeneralSwitchBody),
            value: _generalNotifications,
            onChanged: (value) {
              setState(() => _generalNotifications = value);
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsContactsSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactAddRequest),
            value: _contactAddRequests,
            onChanged: _generalNotifications
                ? (value) => setState(() => _contactAddRequests = value)
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactDisconnection),
            value: _contactDisconnectionNotices,
            onChanged: _generalNotifications
                ? (value) {
                    setState(() => _contactDisconnectionNotices = value);
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactInvitationExpiration),
            value: _contactInvitationExpiration,
            onChanged: _generalNotifications
                ? (value) {
                    setState(() => _contactInvitationExpiration = value);
                  }
                : null,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsHousingSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingPlanSubmission),
            value: _housingPlanSubmissionReceived,
            onChanged: _generalNotifications
                ? (value) {
                    setState(() => _housingPlanSubmissionReceived = value);
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingDecisionChange),
            value: _housingParticipantDecisionChanged,
            onChanged: _generalNotifications
                ? (value) {
                    setState(() => _housingParticipantDecisionChanged = value);
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingOfferExpiration),
            value: _housingOfferExpiration,
            onChanged: _generalNotifications
                ? (value) => setState(() => _housingOfferExpiration = value)
                : null,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsSoundSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsSoundSwitchTitle),
            subtitle: Text(l10n.settingsNotificationsSoundSwitchBody),
            value: _notificationSound,
            onChanged: _generalNotifications
                ? (value) => setState(() => _notificationSound = value)
                : null,
          ),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l10n.settingsNotificationsSoundPickerTitle),
            subtitle: Text(l10n.settingsNotificationsSoundPickerBody),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
    );
  }
}
