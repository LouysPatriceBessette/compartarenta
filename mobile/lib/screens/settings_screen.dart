import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../data/supported_currencies.dart';
import '../db/db_reset.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import '../widgets/async_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.config, required this.prefs});

  final AppConfig config;
  final AppPreferences prefs;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static final Uri _privacyPolicyUrl =
      Uri.parse('https://example.invalid/privacy');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showDevTools = widget.config.environment != AppEnvironment.prod;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(l10n.settingsLanguageSubtitle),
            trailing: DropdownButton<String?>(
              value: widget.prefs.languageCode,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.languageSystem)),
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'fr', child: Text(l10n.languageFrench)),
                DropdownMenuItem(value: 'es', child: Text(l10n.languageSpanish)),
              ],
              onChanged: (value) async {
                await widget.prefs.setLanguageCode(value);
              },
            ),
          ),
          ListTile(
            title: Text(l10n.settingsProfileTitle),
            subtitle: Text(
              widget.prefs.displayName.isEmpty
                  ? l10n.commonNotSet
                  : widget.prefs.displayName,
            ),
          ),
          ListTile(
            title: Text(l10n.settingsCurrencyTitle),
            subtitle: Text(
              widget.prefs.currency.isEmpty
                  ? l10n.commonNotSet
                  : (supportedCurrencyByCode(widget.prefs.currency)?.displayLine ??
                      widget.prefs.currency),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDateFormatTitle),
            subtitle: Text(
              widget.prefs.dateFormat.isEmpty
                  ? l10n.commonNotSet
                  : widget.prefs.dateFormat,
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDistanceUnitTitle),
            subtitle: Text(widget.prefs.distanceUnit?.name ?? l10n.commonNotSet),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsEnvironmentTitle),
            subtitle: Text(widget.config.environment.name),
          ),
          ListTile(
            title: Text(l10n.settingsApiBaseUrlTitle),
            subtitle: Text(widget.config.apiBaseUrl.toString()),
          ),
          FutureBuilder(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingView(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorView(
                    title: l10n.errorSomethingWentWrongTitle,
                    body: l10n.errorSomethingWentWrongBody,
                    onRetry: () => setState(() {}),
                  ),
                );
              }

              final subtitle = info == null
                  ? 'Unknown'
                  : '${info.version} (${info.buildNumber})';

              return ListTile(
                title: Text(l10n.settingsAppVersionTitle),
                subtitle: Text(subtitle),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsPrivacyPolicyTitle),
            subtitle: Text(_privacyPolicyUrl.toString()),
            onTap: () async {
              await launchUrl(_privacyPolicyUrl, mode: LaunchMode.externalApplication);
            },
          ),
          if (showDevTools) ...[
            const Divider(),
            ListTile(
              title: const Text('Developer tools'),
              subtitle: const Text('Development-only actions'),
            ),
            ListTile(
              title: const Text('Reset onboarding & preferences'),
              subtitle: const Text('Clears onboarding progress and saved preferences.'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset onboarding & preferences?'),
                    content: const Text(
                      'This will clear onboarding progress and preferences stored on this device. '
                      'Use only during development.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;
                await widget.prefs.resetOnboardingAndPreferences();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding and preferences reset.')),
                );
              },
            ),
            ListTile(
              title: const Text('Reset local database'),
              subtitle: const Text('Deletes the on-device SQLite database files.'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset local database?'),
                    content: const Text(
                      'This will delete local database files on this device. '
                      'Use only during development.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;
                await DbReset.deleteLocalDbFiles();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local database deleted.')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

