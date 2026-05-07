import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../widgets/async_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static final Uri _privacyPolicyUrl =
      Uri.parse('https://example.invalid/privacy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(widget.config.environment.name),
          ),
          ListTile(
            title: const Text('API base URL'),
            subtitle: Text(widget.config.apiBaseUrl.toString()),
          ),
          FutureBuilder(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingView(message: 'Loading app version…'),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorView(
                    title: 'Unable to load app version',
                    body: 'Please try again later.',
                    onRetry: () => setState(() {}),
                  ),
                );
              }

              final subtitle = info == null
                  ? 'Unknown'
                  : '${info.version} (${info.buildNumber})';

              return ListTile(
                title: const Text('App version'),
                subtitle: Text(subtitle),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy policy'),
            subtitle: Text(_privacyPolicyUrl.toString()),
            onTap: () async {
              await launchUrl(_privacyPolicyUrl, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}

