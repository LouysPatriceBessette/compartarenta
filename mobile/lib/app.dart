import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_error_boundary.dart';
import 'widgets/connectivity_banner.dart';

class CompartarentaApp extends StatelessWidget {
  const CompartarentaApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(config: config),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(config: config),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Compartarenta',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      routerConfig: router,
      builder: (context, child) => AppErrorBoundary(
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

