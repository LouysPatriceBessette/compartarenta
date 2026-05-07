import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';

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

