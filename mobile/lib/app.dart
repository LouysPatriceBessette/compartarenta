import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'prefs/app_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'widgets/app_error_boundary.dart';
import 'widgets/connectivity_banner.dart';

class CompartarentaApp extends StatefulWidget {
  const CompartarentaApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<CompartarentaApp> createState() => _CompartarentaAppState();
}

class _CompartarentaAppState extends State<CompartarentaApp> {
  late final Future<AppPreferences> _prefs = AppPreferences.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefs,
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || prefs == null) {
          return const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
        }

        final router = _createRouter(widget.config, prefs);

        // Rebuild MaterialApp when preferences (e.g., language override) change.
        return ListenableBuilder(
          listenable: prefs,
          builder: (context, _) {
            final override = prefs.languageCode;
            final locale = override == null ? null : Locale(override);

            return MaterialApp.router(
              onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              ),
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              routerConfig: router,
              builder: (context, child) => AppErrorBoundary(
                child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
        );
      },
    );
  }
}

GoRouter _createRouter(AppConfig config, AppPreferences prefs) {
  String? onboardingRedirect(BuildContext context, GoRouterState state) {
    final isOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (prefs.onboardingComplete) {
      return isOnboarding ? '/' : null;
    }

    final next = nextOnboardingLocation(prefs);
    if (isOnboarding) {
      return state.matchedLocation == next ? null : next;
    }
    return next;
  }

  return GoRouter(
    refreshListenable: prefs,
    redirect: onboardingRedirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(config: config),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(config: config, prefs: prefs),
      ),
      GoRoute(
        path: '/onboarding/:step',
        builder: (context, state) {
          final step = state.pathParameters['step'] ?? 'welcome';
          return OnboardingShell(config: config, prefs: prefs, step: step);
        },
      ),
    ],
  );
}

