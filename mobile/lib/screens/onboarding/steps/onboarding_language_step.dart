import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../prefs/app_preferences.dart';

class OnboardingLanguageStep extends StatelessWidget {
  const OnboardingLanguageStep({
    super.key,
    required this.prefs,
    required this.onContinue,
  });

  final AppPreferences prefs;
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
            l10n.onboardingLanguageTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(l10n.onboardingLanguageBody),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: prefs.languageCode,
                  decoration: InputDecoration(labelText: l10n.settingsLanguageTitle),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.languageSystem)),
                    DropdownMenuItem(value: 'fr', child: Text(l10n.languageFrench)),
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(value: 'es', child: Text(l10n.languageSpanish)),
                  ],
                  onChanged: (value) async {
                    await prefs.setLanguageCode(value);
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              await prefs.setOnboardingLanguageDone(true);
              onContinue();
            },
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }
}

