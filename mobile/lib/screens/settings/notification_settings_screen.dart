import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../notifications/notification_permission_gate.dart';
import '../../prefs/app_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.prefs,
    this.permissionGate = NotificationPermissionGate.instance,
  });

  final AppPreferences prefs;
  final NotificationPermissionGate permissionGate;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late Future<NotificationSystemPermissionStatus> _status;

  @override
  void initState() {
    super.initState();
    _status = widget.permissionGate.status();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _status = widget.permissionGate.status();
    });
  }

  Future<void> _requestPermission() async {
    await widget.permissionGate.ensureForUserAction(prefs: widget.prefs);
    if (!mounted) return;
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationsEnabled = widget.prefs.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotificationsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsNotificationsGeneralSection),
          FutureBuilder<NotificationSystemPermissionStatus>(
            future: _status,
            builder: (context, snapshot) {
              final status = snapshot.data;
              final subtitle = status == null
                  ? l10n.settingsNotificationsSystemPermissionChecking
                  : _statusLabel(l10n, status);
              final canRequest =
                  status == NotificationSystemPermissionStatus.unknown ||
                  status == NotificationSystemPermissionStatus.denied;

              return ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.settingsNotificationsSystemPermissionTitle),
                subtitle: Text(subtitle),
                trailing: canRequest
                    ? TextButton(
                        onPressed: _requestPermission,
                        child: Text(l10n.settingsNotificationsRequestAction),
                      )
                    : IconButton(
                        tooltip: l10n.commonRetry,
                        onPressed: _refreshStatus,
                        icon: const Icon(Icons.refresh),
                      ),
              );
            },
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsGeneralSwitchTitle),
            subtitle: Text(l10n.settingsNotificationsGeneralSwitchBody),
            value: notificationsEnabled,
            onChanged: (value) async {
              await widget.prefs.setNotificationsEnabled(value);
              if (mounted) setState(() {});
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsContactsSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactAddRequest),
            value: widget.prefs.notificationContactAddRequests,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationContactAddRequests(value);
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactDisconnection),
            value: widget.prefs.notificationContactDisconnection,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationContactDisconnection(
                      value,
                    );
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsContactInvitationExpiration),
            value: widget.prefs.notificationContactInvitationExpiration,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs
                        .setNotificationContactInvitationExpiration(value);
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsHousingSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingPlanSubmission),
            value: widget.prefs.notificationHousingPlanSubmission,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationHousingPlanSubmission(
                      value,
                    );
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingDecisionChange),
            value: widget.prefs.notificationHousingDecisionChange,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationHousingDecisionChange(
                      value,
                    );
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsHousingOfferExpiration),
            value: widget.prefs.notificationHousingOfferExpiration,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationHousingOfferExpiration(
                      value,
                    );
                    if (mounted) setState(() {});
                  }
                : null,
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsNotificationsSoundSection),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsSoundSwitchTitle),
            subtitle: Text(l10n.settingsNotificationsSoundSwitchBody),
            value: widget.prefs.notificationSoundEnabled,
            onChanged: notificationsEnabled
                ? (value) async {
                    await widget.prefs.setNotificationSoundEnabled(value);
                    if (mounted) setState(() {});
                  }
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

  String _statusLabel(
    AppLocalizations l10n,
    NotificationSystemPermissionStatus status,
  ) {
    return switch (status) {
      NotificationSystemPermissionStatus.unsupported =>
        l10n.settingsNotificationsSystemPermissionUnsupported,
      NotificationSystemPermissionStatus.unknown =>
        l10n.settingsNotificationsSystemPermissionUnknown,
      NotificationSystemPermissionStatus.granted =>
        l10n.settingsNotificationsSystemPermissionGranted,
      NotificationSystemPermissionStatus.denied =>
        l10n.settingsNotificationsSystemPermissionDenied,
      NotificationSystemPermissionStatus.provisional =>
        l10n.settingsNotificationsSystemPermissionProvisional,
    };
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
