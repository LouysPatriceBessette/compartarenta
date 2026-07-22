import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shared welcome + confidentiality copy for onboarding.
class WelcomeIntroContent extends StatelessWidget {
  const WelcomeIntroContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboardingWelcomeIntro),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingWelcomeConfidentialTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.onboardingWelcomeConfidentialBody),
      ],
    );
  }
}
