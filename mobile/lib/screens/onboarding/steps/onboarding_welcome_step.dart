import 'package:flutter/material.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const String draftCopy = 'Thanks for trying Compartarenta.\n\n'
      'In the next steps, you’ll configure your sharing plan(s) (shared housing, car sharing, or both) and start a 6‑week real‑mode trial.\n\n'
      'Your data stays on your device—this app does not collect it.\n\n'
      'If these conditions don’t work for you, you can uninstall at any time.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(draftCopy),
          const Spacer(),
          FilledButton(
            onPressed: onContinue,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

