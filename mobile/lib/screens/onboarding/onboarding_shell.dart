import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../prefs/app_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'steps/onboarding_plans_step.dart';
import 'steps/onboarding_preferences_step.dart';
import 'steps/onboarding_profile_step.dart';
import 'steps/onboarding_welcome_step.dart';

String nextOnboardingLocation(AppPreferences prefs) {
  if (prefs.onboardingStep == 'welcome') {
    return '/onboarding/welcome';
  }
  if (!prefs.hasPlanSelection) {
    return '/onboarding/plans';
  }
  if (!prefs.hasProfile) {
    return '/onboarding/profile';
  }
  if (!prefs.hasRegionalPrefs) {
    return '/onboarding/preferences';
  }
  return '/onboarding/preferences';
}

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.config,
    required this.prefs,
    required this.step,
  });

  final AppConfig config;
  final AppPreferences prefs;
  final String step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget child;
    switch (step) {
      case 'welcome':
        child = OnboardingWelcomeStep(
          onContinue: () async {
            await prefs.setOnboardingStep('plans');
            if (context.mounted) context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'plans':
        child = OnboardingPlansStep(
          prefs: prefs,
          onContinue: () async {
            await prefs.setOnboardingStep('profile');
            if (context.mounted) context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'profile':
        child = OnboardingProfileStep(
          prefs: prefs,
          onContinue: () async {
            await prefs.setOnboardingStep('preferences');
            if (context.mounted) context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'preferences':
        child = OnboardingPreferencesStep(
          prefs: prefs,
          onFinish: () async {
            await prefs.completeOnboarding();
            if (context.mounted) context.go('/');
          },
        );
        break;
      default:
        child = Center(child: Text(l10n.errorUnknownOnboardingStep));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: child),
    );
  }
}

