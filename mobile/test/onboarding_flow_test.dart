import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/screens/onboarding/steps/onboarding_preferences_step.dart';
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

    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingPreferencesStep(prefs: prefs, onFinish: () {}),
        ),
      ),
    );

    // Currency field is the first read-only TextFormField; timezone is second.
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ARS — peso argentin'), findsOneWidget);
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
