import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'debug/local_storage_startup_log.dart';
import 'debug/qa_e2e_environment.dart';
import 'debug/qa_e2e_meter_photo.dart';
import 'debug/qa_scenario_seed.dart';
import 'debug/web_dev_db_write_observer.dart';
import 'debug/web_dev_host_session.dart';
import 'entitlement/entitlement_coordinator.dart';
import 'entitlement/participant_installation_store.dart';
import 'entitlement/plan_participant_installation_registry.dart';
import 'relay/relay_diagnostics.dart';
import 'debug/web_storage_flush.dart';
import 'contacts/contact_invitations_repository.dart';
import 'db/app_database.dart';
import 'db/repositories/contacts_repository.dart';
import 'notifications/notification_permission_gate.dart';
import 'notifications/push_notification_service.dart';
import 'notifications/push_background_registration_stub.dart'
    if (dart.library.io) 'notifications/push_background_registration_io.dart';
import 'notifications/closed_app_push_workmanager_stub.dart'
    if (dart.library.io) 'notifications/closed_app_push_workmanager_io.dart';
import 'relay/handshake_orchestrator.dart';
import 'relay/identity_keystore.dart';
import 'relay/relay_client.dart';

Future<void> bootstrap() async {
  final config = AppConfig.fromDartDefines();
  final sentryDsn = const String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  await runZonedGuarded(
    () async {
      // Drift (path_provider), secure storage, and plugins require binding first.
      // Opening [AppDatabase] before this can hang on Android (stuck native splash).
      WidgetsFlutterBinding.ensureInitialized();
      registerPushBackgroundHandler();

      if (kDebugMode && kIsWeb) {
        await wipeWebDevBrowserStorageOnLaunchIfRequested(
          clearRelayIdentity: config.apiBaseUrl.host != 'example.invalid',
        );
      }

      final appDb = AppDatabase();
      AppDatabase.bindProcessScope(appDb);
      if (kDebugMode && kIsWeb) {
        debugWebDbFlushHook = scheduleDevHostSessionSave;
        debugWebDbWriteHook = () => scheduleDevHostSessionSave(appDb);
      }
      installWebStorageFlushOnPageHide();
      try {
        await appDb.warmUpStorage();
        if (kDebugMode && !kIsWeb) {
          await restoreQaE2eEnvironmentIfPresent();
          await maybeApplyQaAndroidSeed(appDb);
          await restoreQaE2eEnvironmentIfPresent();
          await syncQaE2eFlagsFromPrefs();
        }
        if (kDebugMode && kIsWeb) {
          await restoreDevSessionFromHostIfNeeded(appDb);
          await reconcileDevOnboardingIfNeeded(appDb);
        }
        await logLocalStorageStartupDiagnostics(appDb);
      } catch (error, stack) {
        debugPrint(
          'AppDatabase warmUpStorage failed (stop melos, force-quit app, '
          'then `dart run melos run run:dev`): $error\n$stack',
        );
      }

      unawaited(_initializePushIfAlreadyAuthorized());
      if (!kIsWeb) {
        unawaited(
          scheduleClosedAppPushKeepAlive().catchError((
            Object error,
            StackTrace stack,
          ) {
            debugPrint(
              'Closed-app push WorkManager schedule failed: $error\n$stack',
            );
          }),
        );
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (sentryDsn.isNotEmpty) {
          Sentry.captureException(details.exception, stackTrace: details.stack);
        }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (sentryDsn.isNotEmpty) {
          Sentry.captureException(error, stackTrace: stack);
        }
        return false;
      };

      // Wire the relay / Contacts handshake plumbing once per process so any
      // screen can reach it through [HandshakeOrchestrator.instance]. We
      // skip the install when no relay base URL is configured (default
      // `https://example.invalid` in dart-defines) so test/dev runs that
      // do not target a live relay don't accidentally spam HTTP requests.
      if (config.apiBaseUrl.host != 'example.invalid') {
        try {
          final identity = IdentityKeystore.secureStorage();
          final relay = HttpRelayClient(baseUrl: config.apiBaseUrl);
          EntitlementCoordinator? entitlementCoordinator;
          if (config.entitlementGateEnabled) {
            final registry = await PlanParticipantInstallationRegistry.load();
            entitlementCoordinator = EntitlementCoordinator(
              config: config,
              installationStore: ParticipantInstallationStore.secureStorage(),
              registry: registry,
            );
            EntitlementCoordinator.install(entitlementCoordinator);
            if (config.entitlementEnabled) {
              unawaited(entitlementCoordinator.ensureRegistered());
            }
          }
          final orchestrator = HandshakeOrchestrator(
            db: appDb,
            identity: identity,
            relay: relay,
            contacts: ContactsRepository(appDb),
            invitations: ContactInvitationsRepository(appDb),
            entitlement: entitlementCoordinator,
          );
          HandshakeOrchestrator.install(orchestrator);
          if (kDebugMode) {
            RelayDiagnostics.steadyInboxPollLogging = true;
          }
          unawaited(
            orchestrator.processAllPendingHandshakes().catchError((
              Object error,
              StackTrace stack,
            ) {
              debugPrint('Initial handshake polling failed: $error\n$stack');
            }),
          );
          unawaited(
            orchestrator.pollSteadyStateInboxes().catchError((
              Object error,
              StackTrace stack,
            ) {
              debugPrint('Initial steady inbox poll failed: $error\n$stack');
            }),
          );
          orchestrator.startPolling();
        } catch (error, stack) {
          debugPrint('Relay handshake bootstrap failed: $error\n$stack');
        }
      }

      if (sentryDsn.isEmpty) {
        runApp(CompartarentaApp(config: config));
        return;
      }

      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.environment = config.environment.name;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
      }, appRunner: () => runApp(CompartarentaApp(config: config)));
    },
    (error, stack) async {
      if (sentryDsn.isNotEmpty) {
        await Sentry.captureException(error, stackTrace: stack);
      }
    },
  );
}

Future<void> _initializePushIfAlreadyAuthorized() async {
  try {
    final status = await NotificationPermissionGate.instance.status();
    if (status == NotificationSystemPermissionStatus.granted ||
        status == NotificationSystemPermissionStatus.provisional) {
      await PushNotificationService.initialize();
    }
  } catch (e, st) {
    debugPrint('Push notification authorization check failed: $e\n$st');
  }
}
