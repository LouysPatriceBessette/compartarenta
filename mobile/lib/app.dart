import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'screens/settings/activity_log_settings_screen.dart';
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
import 'housing/housing_plan_peer_contacts.dart';
import 'screens/contacts/redeem_invitation_screen.dart';
import 'relay/handshake_orchestrator.dart';
import 'notifications/closed_app_push_registration_service.dart';
import 'widgets/app_error_boundary.dart';
import 'widgets/contact_invite_deep_link_listener.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/profile_label_conflict_host.dart';
import 'theme/app_theme.dart';
import 'util/native_plugin_link_error.dart';

class CompartarentaApp extends StatefulWidget {
  const CompartarentaApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<CompartarentaApp> createState() => _CompartarentaAppState();
}

class _CompartarentaAppState extends State<CompartarentaApp>
    with WidgetsBindingObserver {
  late Future<AppPreferences> _prefs = _loadPrefs();
  int _prefsLoadGeneration = 0;

  /// Reused across [ListenableBuilder] rebuilds so navigation state is kept.
  GoRouter? _router;

  String _lastRoutingPushPrefsSig = '';

  void _retryPrefsLoad() {
    setState(() {
      _prefsLoadGeneration++;
      _prefs = _loadPrefs();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) {
      if (state == AppLifecycleState.resumed) {
        unawaited(
          HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes().catchError(
            (Object error, StackTrace stack) {
              debugPrint('Relay poll on web resume failed: $error\n$stack');
            },
          ),
        );
      }
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.hidden:
        case AppLifecycleState.detached:
          break;
        default:
          return;
      }
      try {
        unawaited(
          AppDatabase.processScope.syncWebStorageToDisk().catchError(
            (Object error, StackTrace stack) {
              debugPrint('Drift web flush on $state failed: $error\n$stack');
            },
          ),
        );
      } on StateError {
        // processScope not bound yet (tests).
      }
      return;
    }
  }

  Future<AppPreferences> _loadPrefs() async {
    final prefs = await AppPreferences.load();
    _wireProfileBroadcaster(prefs);
    _wireClosedAppPush(prefs);
    return prefs;
  }

  void _wireClosedAppPush(AppPreferences prefs) {
    if (widget.config.apiBaseUrl.host == 'example.invalid') {
      return;
    }
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) {
      return;
    }
    ClosedAppPushRegistrationService.install(
      relay: orch.relayClient,
      prefs: prefs,
    );
    HandshakeOrchestrator.refreshClosedAppPushRegistration = () async {
      await ClosedAppPushRegistrationService.maybeInstance?.sync();
    };
    unawaited(ClosedAppPushRegistrationService.maybeInstance?.sync());

    String routingPushSig() =>
        '${prefs.notificationsEnabled}|'
        '${prefs.notificationCountryStatisticsEnabled}|'
        '${prefs.notificationCountryStatisticsCode ?? ''}';
    _lastRoutingPushPrefsSig = routingPushSig();
    prefs.addListener(() {
      final next = routingPushSig();
      if (next == _lastRoutingPushPrefsSig) {
        return;
      }
      _lastRoutingPushPrefsSig = next;
      HandshakeOrchestrator.requestClosedAppPushRegistrationSync();
    });
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
      key: ValueKey(_prefsLoadGeneration),
      future: _prefs,
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (snapshot.hasError) {
          final error = snapshot.error!;
          final stack = snapshot.stackTrace;
          final lang = WidgetsBinding.instance.platformDispatcher.locale
              .languageCode;
          final pluginLink = isNativePluginLinkError(error);
          final errorTheme = buildAppTheme();
          return MaterialApp(
            theme: errorTheme,
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          lang == 'fr'
                              ? 'Démarrage impossible'
                              : 'Startup failed',
                          style: errorTheme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          pluginLink
                              ? nativePluginLinkErrorRecoveryMessage(
                                  languageCode: lang,
                                )
                              : '$error',
                        ),
                        if (pluginLink && stack != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            lang == 'fr'
                                ? 'Détail technique'
                                : 'Technical detail',
                            style: errorTheme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            '$error\n\n$stack',
                            style: errorTheme.textTheme.bodySmall,
                          ),
                        ] else if (!pluginLink && stack != null) ...[
                          const SizedBox(height: 16),
                          SelectableText('$stack'),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _retryPrefsLoad,
                          child: Text(
                            lang == 'fr' ? 'Réessayer' : 'Retry',
                          ),
                        ),
                      ],
                    ),
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
        path: '/settings/activity-log',
        builder: (context, state) => ActivityLogSettingsScreen(prefs: prefs),
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
            path: 'invite/code/:invitationId',
            builder: (context, state) => GenerateInvitationScreen(
              viewInvitationId: state.pathParameters['invitationId'],
            ),
          ),
          GoRoute(
            path: 'invitations',
            builder: (context, state) => const OutstandingInvitationsScreen(),
          ),
          GoRoute(
            path: 'redeem',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is HousingMissingContactRedeemArgs) {
                return RedeemInvitationScreen(
                  housingMissingParticipantName: extra.displayName,
                );
              }
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
