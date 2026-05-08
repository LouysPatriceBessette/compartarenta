import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../prefs/app_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'steps/onboarding_preferences_step.dart';
import 'steps/onboarding_profile_step.dart';
import 'steps/onboarding_language_step.dart';
import 'steps/onboarding_splash_step.dart';
import 'steps/onboarding_welcome_step.dart';
import 'steps/onboarding_welcome_more_step.dart';

String nextOnboardingLocation(AppPreferences prefs) {
  if (prefs.onboardingStep == null || prefs.onboardingStep == 'splash') {
    return '/onboarding/splash';
  }
  if (!prefs.onboardingLanguageDone) {
    return '/onboarding/language';
  }
  if (!prefs.onboardingWelcomeDone) {
    return prefs.onboardingStep == 'welcome_more'
        ? '/onboarding/welcome_more'
        : '/onboarding/welcome';
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
      case 'splash':
        child = OnboardingSplashStep(
          onDone: () async {
            await prefs.setOnboardingStep('language');
            if (context.mounted) context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'language':
        child = OnboardingLanguageStep(
          prefs: prefs,
          onContinue: () async {
            await prefs.setOnboardingStep('welcome');
            if (context.mounted) context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'welcome':
        child = OnboardingWelcomeStep(
          onContinue: () {
            prefs.setOnboardingStep('welcome_more');
            context.go('/onboarding/welcome_more');
          },
          onReadLater: () {
            prefs.setOnboardingWelcomeDone(true);
            prefs.setOnboardingStep('profile');
            context.go(nextOnboardingLocation(prefs));
          },
        );
        break;
      case 'welcome_more':
        child = OnboardingWelcomeMoreStep(
          onOk: () async {
            await prefs.setOnboardingWelcomeDone(true);
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
      appBar: step == 'splash'
          ? null
          : AppBar(
              title: Text(l10n.onboardingTitle),
              automaticallyImplyLeading: false,
            ),
      body: SafeArea(child: child),
    );
  }
}

