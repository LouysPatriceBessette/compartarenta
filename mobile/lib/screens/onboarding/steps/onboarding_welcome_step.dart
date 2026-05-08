import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({
    super.key,
    required this.onContinue,
    required this.onReadLater,
  });

  final VoidCallback onContinue;
  final VoidCallback onReadLater;

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
          Text(l10n.onboardingWelcomeCopyShort),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  child: Text(l10n.commonContinue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReadLater,
                  child: Text(l10n.onboardingReadLater),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

