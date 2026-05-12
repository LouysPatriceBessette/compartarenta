import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navHome),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: l10n.navSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _HomeActionCard(
                    icon: MdiIcons.homeCity,
                    label: l10n.homeHousingPlan,
                    onTap: () => context.push('/housing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HomeActionCard(
                    icon: MdiIcons.carSide,
                    label: l10n.homeCarSharingPlan,
                    onTap: () => context.push('/car'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: MdiIcons.accountMultipleOutline,
              label: l10n.homeContacts,
              onTap: () => context.push('/contacts'),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeEnvironment(config.environment.name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeApiBaseUrl(config.apiBaseUrl.toString()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(l10n.homePlaceholderBody),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

