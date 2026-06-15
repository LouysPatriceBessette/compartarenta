import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:compartarenta/prefs/time_zone_preference_field.dart';
import 'package:compartarenta/prefs/week_start.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/widgets/supported_currency_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('cold start shows onboarding welcome', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();

    final router = _testRouter(prefs);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [],
        supportedLocales: const [Locale('en')],
        builder: (context, child) => child ?? const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('currency picker fits above Android keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () => showSupportedCurrencyPicker(
                  context,
                  searchHint: 'Search',
                ),
                child: const Text('Open picker'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ARS — peso argentin'), findsOneWidget);
  });

  test('completeOnboarding applies default regional prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();
    await prefs.completeOnboarding();
    expect(prefs.currency, 'CAD');
    expect(prefs.dateFormat, 'YYYY-MM-DD');
    expect(prefs.distanceUnit, DistanceUnit.km);
    expect(prefs.weekStart, WeekStart.sunday);
    expect(prefs.usesDeviceTimeZone, isTrue);
  });
}

GoRouter _testRouter(AppPreferences prefs) {
  String? redirect(BuildContext context, GoRouterState state) {
    final isOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (prefs.onboardingComplete) {
      return isOnboarding ? '/' : null;
    }

    if (isOnboarding) {
      return state.matchedLocation == '/onboarding/welcome'
          ? null
          : '/onboarding/welcome';
    }
    return '/onboarding/welcome';
  }

  return GoRouter(
    refreshListenable: prefs,
    redirect: redirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const Text('Welcome'),
      ),
    ],
  );
}
