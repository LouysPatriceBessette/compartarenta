import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Placeholder for hub routes not yet implemented (passes 2–5).
class HousingActiveHubPlaceholderScreen extends StatelessWidget {
  const HousingActiveHubPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.housingActiveHubPassPlaceholderTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.housingActiveHubPassPlaceholderBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
