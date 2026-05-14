import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'prefs/app_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'screens/housing/housing_plan_screen.dart';
import 'screens/car_sharing/car_sharing_plan_screen.dart';
import 'screens/contacts/contact_detail_screen.dart';
import 'screens/contacts/contact_editor_screen.dart';
import 'screens/contacts/contacts_list_screen.dart';
import 'screens/contacts/generate_invitation_screen.dart';
import 'screens/contacts/incoming_handshakes_screen.dart';
import 'screens/contacts/outstanding_invitations_screen.dart';
import 'screens/contacts/redeem_invitation_screen.dart';
import 'relay/handshake_orchestrator.dart';
import 'widgets/app_error_boundary.dart';
import 'widgets/contact_invite_deep_link_listener.dart';
import 'widgets/connectivity_banner.dart';

class CompartarentaApp extends StatefulWidget {
  const CompartarentaApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<CompartarentaApp> createState() => _CompartarentaAppState();
}

class _CompartarentaAppState extends State<CompartarentaApp> {
  late final Future<AppPreferences> _prefs = _loadPrefs();

  /// Reused across [ListenableBuilder] rebuilds so navigation state is kept.
  GoRouter? _router;

  Future<AppPreferences> _loadPrefs() async {
    final prefs = await AppPreferences.load();
    _wireProfileBroadcaster(prefs);
    return prefs;
  }

  String _lastProfileSignature = '';
  void _wireProfileBroadcaster(AppPreferences prefs) {
    _lastProfileSignature = '${prefs.displayName}|${prefs.avatarId}';
    prefs.addListener(() {
      final sig = '${prefs.displayName}|${prefs.avatarId}';
      if (sig == _lastProfileSignature) return;
      _lastProfileSignature = sig;
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch == null) return;
      if (prefs.displayName.isEmpty || prefs.avatarId.isEmpty) return;
      // Fire and forget — broadcaster catches its own errors.
      // ignore: unawaited_futures
      orch.broadcastProfileUpdate(
        displayName: prefs.displayName,
        avatarId: prefs.avatarId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefs,
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    'Startup failed:\n${snapshot.error}\n\n${snapshot.stackTrace}',
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done || prefs == null) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        _router ??= _createRouter(widget.config, prefs);
        final router = _router!;

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
                child: ConnectivityBanner(
                  child: ContactInviteDeepLinkListener(
                    router: router,
                    prefs: prefs,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
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
        path: '/housing',
        builder: (context, state) => HousingPlanScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/car',
        builder: (context, state) => CarSharingPlanScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ContactEditorScreen(),
          ),
          GoRoute(
            path: 'invite/new',
            builder: (context, state) => const GenerateInvitationScreen(),
          ),
          GoRoute(
            path: 'invitations',
            builder: (context, state) => const OutstandingInvitationsScreen(),
          ),
          GoRoute(
            path: 'redeem',
            builder: (context, state) {
              final extra = state.extra;
              final initial = extra is String ? extra : null;
              return RedeemInvitationScreen(initialInvitationUri: initial);
            },
          ),
          GoRoute(
            path: 'incoming',
            builder: (context, state) => const IncomingHandshakesScreen(),
          ),
          GoRoute(
            path: ':contactId',
            builder: (context, state) => ContactDetailScreen(
              contactId: state.pathParameters['contactId']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => ContactEditorScreen(
                  contactId: state.pathParameters['contactId'],
                ),
              ),
            ],
          ),
        ],
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

