import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingWelcomeTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(l10n.onboardingWelcomeCopy),
          const Spacer(),
          FilledButton(
            onPressed: onContinue,
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }
}

