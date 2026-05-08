import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:flutter/material.dart';
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
        builder: (context, child) => child ?? const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });
}

GoRouter _testRouter(AppPreferences prefs) {
  String? redirect(GoRouterState state) {
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
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const Text('Welcome'),
      ),
    ],
  );
}

