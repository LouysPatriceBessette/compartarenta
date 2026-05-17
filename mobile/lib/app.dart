import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app_root_navigator.dart';
import 'config/app_config.dart';
import 'db/app_database.dart';
import 'db/repositories/contacts_repository.dart';
import 'prefs/app_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/settings/about_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/profile_identity_settings_screen.dart';
import 'screens/settings/units_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';
import 'screens/housing/housing_module_entry_screen.dart';
import 'screens/car_sharing/car_sharing_plan_screen.dart';
import 'screens/contacts/contact_detail_screen.dart';
import 'screens/contacts/contact_edit_route_screen.dart';
import 'screens/contacts/contacts_list_screen.dart';
import 'screens/contacts/generate_invitation_screen.dart';
import 'screens/contacts/incoming_handshakes_screen.dart';
import 'screens/contacts/outstanding_invitations_screen.dart';
import 'screens/contacts/redeem_invitation_screen.dart';
import 'relay/handshake_orchestrator.dart';
import 'widgets/app_error_boundary.dart';
import 'widgets/contact_invite_deep_link_listener.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/profile_label_conflict_host.dart';
import 'theme/app_theme.dart';

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
      final dn = prefs.displayName;
      final av = prefs.avatarId;
      final sig = '$dn|$av';
      if (sig == _lastProfileSignature) return;
      final prevParts = _lastProfileSignature.split('|');
      final prevDn = prevParts.isNotEmpty ? prevParts.first : '';
      _lastProfileSignature = sig;

      if (dn.trim().isNotEmpty && dn != prevDn) {
        unawaited(_clearTheirLabelsIfCanonicalMatches(dn));
      }

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

  Future<void> _clearTheirLabelsIfCanonicalMatches(String canonical) async {
    try {
      final repo = ContactsRepository(AppDatabase.processScope);
      await repo.clearTheirLabelForMeWhenMatchesCanonical(canonical);
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch != null) {
        orch.steadyStateInboxTick.value = orch.steadyStateInboxTick.value + 1;
      }
    } catch (_) {
      // Best-effort; profile UI still loads from DB on next open.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefs,
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (snapshot.hasError) {
          return MaterialApp(
            theme: buildAppTheme(),
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
          return MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(
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
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              theme: buildAppTheme(),
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
                child: ProfileLabelConflictHost(
                  child: ConnectivityBanner(
                    child: ContactInviteDeepLinkListener(
                      router: router,
                      prefs: prefs,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
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
    navigatorKey: appRootNavigatorKey,
    refreshListenable: prefs,
    redirect: onboardingRedirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            SettingsScreen(config: config, prefs: prefs),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) =>
            ProfileIdentitySettingsScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => NotificationSettingsScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/settings/units',
        builder: (context, state) => UnitsSettingsScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => AboutSettingsScreen(config: config),
      ),
      GoRoute(
        path: '/housing',
        builder: (context, state) => HousingModuleEntryScreen(prefs: prefs),
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
            redirect: (context, state) => '/contacts/invite/new',
          ),
          GoRoute(
            path: 'invite/new',
            builder: (context, state) {
              final extra = state.extra;
              return GenerateInvitationScreen(
                reconnectContactId: extra is String ? extra : null,
              );
            },
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
                builder: (context, state) => ContactEditRouteScreen(
                  contactId: state.pathParameters['contactId']!,
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
