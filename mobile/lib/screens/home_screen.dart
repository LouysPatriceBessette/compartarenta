import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../l10n/app_localizations.dart';
import '../vehicle/vehicle_module_access.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final access = const VehicleModuleAccess();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: () => navigateToChild(context, '/settings'),
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

          final rawContentW = constraints.maxWidth -
              2 * contentInset -
              viewPadding.left -
              viewPadding.right;
          final contentW = rawContentW.clamp(0.0, double.infinity);
          final moduleTileW = landscape
              ? ((contentW - gap) / 2).clamp(0.0, double.infinity)
              : contentW;

          final tiles = <Widget>[
            SizedBox(
              width: contentW,
              child: _HomeActionCard(
                icon: MdiIcons.accountMultipleOutline,
                label: l10n.homeModuleContacts,
                onTap: () => navigateTo(context, '/contacts'),
                semanticsIdentifier:
                    kDebugMode ? 'qa-home-contacts' : null,
              ),
            ),
            SizedBox(
              width: moduleTileW,
              child: _HomeActionCard(
                icon: MdiIcons.homeCity,
                label: l10n.homeModuleHousing,
                onTap: () => navigateTo(context, '/housing'),
                semanticsIdentifier:
                    kDebugMode ? 'qa-home-housing' : null,
              ),
            ),
          ];

          if (access.showVehicleHomeTile) {
            tiles.add(
              SizedBox(
                width: moduleTileW,
                child: _HomeActionCard(
                  icon: MdiIcons.carSide,
                  label: l10n.homeModuleVehicle,
                  onTap: () => navigateTo(context, '/vehicle'),
                  semanticsIdentifier:
                      kDebugMode ? 'qa-home-vehicle' : null,
                ),
              ),
            );
          }

          if (access.showVehicleSharingHomeTile) {
            tiles.add(
              SizedBox(
                width: moduleTileW,
                child: _HomeActionCard(
                  icon: Icons.car_rental,
                  label: l10n.homeModuleVehicleSharing,
                  onTap: () => navigateTo(context, '/vehicle-sharing'),
                  semanticsIdentifier:
                      kDebugMode ? 'qa-home-vehicle-sharing' : null,
                ),
              ),
            );
          }

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
              children: tiles,
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
    this.semanticsIdentifier,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSurface;

    final card = InkWell(
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

    if (semanticsIdentifier == null) return card;
    return Semantics(
      identifier: semanticsIdentifier,
      button: true,
      label: label,
      excludeSemantics: true,
      child: card,
    );
  }
}
