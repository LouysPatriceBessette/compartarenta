import 'package:compartarenta/app_root_navigator.dart';
import 'package:compartarenta/housing/housing_module_exit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'exitHousingModule from PopScope navigates home without navigator lock',
    (tester) async {
      final router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/housing',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('home')),
            ),
          ),
          GoRoute(
            path: '/housing',
            builder: (context, state) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) exitHousingModule(context);
              },
              child: const Scaffold(
                body: Center(child: Text('housing hub')),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('housing hub'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home'), findsOneWidget);
      expect(router.state.matchedLocation, '/');
    },
  );

  testWidgets(
    'exitHousingModule from nested PopScope (entry + active hub) avoids lock',
    (tester) async {
      final router = GoRouter(
        navigatorKey: appRootNavigatorKey,
        initialLocation: '/housing',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('home')),
            ),
          ),
          GoRoute(
            path: '/housing',
            builder: (context, state) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) exitHousingModule(context);
              },
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) exitHousingModule(context);
                },
                child: const Scaffold(
                  body: Center(child: Text('active hub')),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('active hub'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home'), findsOneWidget);
      expect(router.state.matchedLocation, '/');
    },
  );
}
