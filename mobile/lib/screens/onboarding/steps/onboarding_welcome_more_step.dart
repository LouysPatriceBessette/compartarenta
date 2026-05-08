import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class OnboardingWelcomeMoreStep extends StatelessWidget {
  const OnboardingWelcomeMoreStep({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingWelcomeMoreTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(l10n.onboardingWelcomeCopyLong),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onOk,
            child: Text(l10n.onboardingOk),
          ),
        ],
      ),
    );
  }
}

