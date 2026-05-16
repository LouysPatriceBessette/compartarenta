import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/async_state.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  late Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutTitle)),
      body: ListView(
        children: [
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
                    onRetry: () {
                      setState(() {
                        _packageInfo = PackageInfo.fromPlatform();
                      });
                    },
                  ),
                );
              }

              final subtitle = info == null
                  ? l10n.commonNotSet
                  : '${info.version} (${info.buildNumber})';

              return ListTile(
                title: Text(l10n.settingsAppVersionTitle),
                subtitle: Text(subtitle),
              );
            },
          ),
        ],
      ),
    );
  }
}
