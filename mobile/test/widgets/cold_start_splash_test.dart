import 'package:compartarenta/widgets/cold_start_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColdStartSplash', () {
    testWidgets('should animate for five seconds then fade for one second', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ColdStartSplash(child: Placeholder())),
      );

      expect(find.byKey(ColdStartSplash.splashKey), findsOneWidget);
      var logoFade = tester.widget<AnimatedOpacity>(
        find.byKey(ColdStartSplash.logoFadeKey),
      );
      expect(logoFade.opacity, 0);
      expect(logoFade.duration, const Duration(milliseconds: 400));

      await tester.pump();
      logoFade = tester.widget<AnimatedOpacity>(
        find.byKey(ColdStartSplash.logoFadeKey),
      );
      expect(logoFade.opacity, 1);

      await tester.pump(const Duration(milliseconds: 4999));
      expect(find.byKey(ColdStartSplash.splashKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(ColdStartSplash.splashKey), findsOneWidget);
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(ColdStartSplash.fadeKey))
            .opacity,
        0,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.byKey(ColdStartSplash.splashKey), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(ColdStartSplash.splashKey), findsNothing);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
