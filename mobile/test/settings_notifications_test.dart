import 'package:compartarenta/config/app_config.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/notifications/notification_permission_gate.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:compartarenta/screens/settings/notification_settings_screen.dart';
import 'package:compartarenta/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings navigates to persisted notification controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.complete': true,
      'prefs.languageCode': 'en',
    });
    final prefs = await AppPreferences.load();
    final permissionClient = _FakePermissionClient(
      NotificationSystemPermissionStatus.granted,
    );
    final gate = NotificationPermissionGate(client: permissionClient);
    final router = _settingsRouter(prefs: prefs, gate: gate);

    await tester.pumpWidget(_TestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Not requested yet'), findsOneWidget);
    expect(permissionClient.getStatusCount, 0);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Add requests'), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Plan submission received'), findsOneWidget);
    expect(prefs.notificationsEnabled, isFalse);

    final masterTile = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text('Allow app notifications'),
        matching: find.byType(SwitchListTile),
      ),
    );
    masterTile.onChanged!(true);
    await tester.pumpAndSettle();

    expect(prefs.notificationsEnabled, isTrue);
    expect(permissionClient.getStatusCount, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Sound'), findsOneWidget);
  });

  testWidgets(
    'notifications page disables stale app switch when system denied',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding.complete': true,
        'prefs.languageCode': 'en',
        'notifications.enabled': true,
      });
      final prefs = await AppPreferences.load();
      final permissionClient = _FakePermissionClient(
        NotificationSystemPermissionStatus.denied,
      );
      final gate = NotificationPermissionGate(client: permissionClient);
      final router = _settingsRouter(prefs: prefs, gate: gate);

      await tester.pumpWidget(_TestApp(router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(permissionClient.getStatusCount, 1);
      expect(prefs.notificationsEnabled, isFalse);
      expect(find.text('Blocked by the system'), findsOneWidget);
    },
  );
}

GoRouter _settingsRouter({
  required AppPreferences prefs,
  required NotificationPermissionGate gate,
}) {
  final config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: Uri.parse('https://example.invalid'),
  );

  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            SettingsScreen(config: config, prefs: prefs),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) =>
            NotificationSettingsScreen(prefs: prefs, permissionGate: gate),
      ),
      GoRoute(
        path: '/settings/units',
        builder: (context, state) => const Scaffold(body: Text('Units')),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const Scaffold(body: Text('About')),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const Scaffold(body: Text('Profile')),
      ),
    ],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

final class _FakePermissionClient implements NotificationPermissionClient {
  _FakePermissionClient(this.status);

  final NotificationSystemPermissionStatus status;
  int getStatusCount = 0;
  int requestCount = 0;

  @override
  Future<NotificationSystemPermissionStatus> getStatus() async {
    getStatusCount++;
    return status;
  }

  @override
  Future<NotificationSystemPermissionStatus> request() async {
    requestCount++;
    return status;
  }
}
