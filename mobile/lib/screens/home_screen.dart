import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    void showComingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonComingSoon)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: l10n.navSettings,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final landscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final viewPadding = MediaQuery.viewPaddingOf(context);
          const contentInset = 16.0;
          const gap = 12.0;

          // Usable width for Wrap children: [LayoutBuilder] can report maxWidth==0
          // briefly (e.g. cold start / activity teardown), which must not become a
          // negative SizedBox width (BoxConstraints w=-32 when only insets apply).
          final rawContentW = constraints.maxWidth -
              2 * contentInset -
              viewPadding.left -
              viewPadding.right;
          final contentW = rawContentW.clamp(0.0, double.infinity);
          final moduleTileW = landscape
              ? ((contentW - gap) / 2).clamp(0.0, double.infinity)
              : contentW;

          /// Material Icons does not expose `Icons.finance` in this SDK; `savings`
          /// is the closest bundled match to the Material Symbol “Finance”.
          const IconData budgetIcon = Icons.savings;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              contentInset + viewPadding.left,
              contentInset + viewPadding.top,
              contentInset + viewPadding.right,
              contentInset + viewPadding.bottom,
            ),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: contentW,
                  child: _HomeActionCard(
                    icon: MdiIcons.accountMultipleOutline,
                    label: l10n.homeModuleContacts,
                    onTap: () => context.push('/contacts'),
                  ),
                ),
                SizedBox(
                  width: moduleTileW,
                  child: _HomeActionCard(
                    icon: MdiIcons.homeCity,
                    label: l10n.homeModuleHousing,
                    onTap: () => context.push('/housing'),
                  ),
                ),
                SizedBox(
                  width: moduleTileW,
                  child: _HomeActionCard(
                    icon: budgetIcon,
                    label: l10n.homeModulePersonalBudget,
                    onTap: showComingSoon,
                    enabled: false,
                  ),
                ),
                SizedBox(
                  width: moduleTileW,
                  child: _HomeActionCard(
                    icon: MdiIcons.carSide,
                    label: l10n.homeModuleVehicle,
                    onTap: showComingSoon,
                    enabled: false,
                  ),
                ),
                SizedBox(
                  width: moduleTileW,
                  child: _HomeActionCard(
                    icon: Icons.car_rental,
                    label: l10n.homeModuleVehicleSharing,
                    onTap: showComingSoon,
                    enabled: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// When false, card uses muted colors (Material disabled-style) but [onTap] still runs.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);

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
              Icon(icon, size: 28, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
