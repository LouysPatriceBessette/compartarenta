import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'contacts/contact_invitations_repository.dart';
import 'db/app_database.dart';
import 'db/repositories/contacts_repository.dart';
import 'relay/handshake_orchestrator.dart';
import 'relay/identity_keystore.dart';
import 'relay/relay_client.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromDartDefines();
  final sentryDsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');

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
      final db = AppDatabase();
      final identity = IdentityKeystore.secureStorage();
      final relay = HttpRelayClient(baseUrl: config.apiBaseUrl);
      final orchestrator = HandshakeOrchestrator(
        db: db,
        identity: identity,
        relay: relay,
        contacts: ContactsRepository(db),
        invitations: ContactInvitationsRepository(db),
      );
      HandshakeOrchestrator.install(orchestrator);
      unawaited(
        orchestrator.processAllPendingHandshakes().catchError(
          (Object error, StackTrace stack) {
            debugPrint('Initial handshake polling failed: $error\n$stack');
          },
        ),
      );
      orchestrator.startPolling();
    } catch (error, stack) {
      debugPrint('Relay handshake bootstrap failed: $error\n$stack');
    }
  }

  await runZonedGuarded(() async {
    if (sentryDsn.isEmpty) {
      runApp(CompartarentaApp(config: config));
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = config.environment.name;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
      },
      appRunner: () => runApp(CompartarentaApp(config: config)),
    );
  }, (error, stack) async {
    if (sentryDsn.isNotEmpty) {
      await Sentry.captureException(error, stackTrace: stack);
    }
  });
}

