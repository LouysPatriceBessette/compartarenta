import 'package:compartarenta/widgets/bojairu_animated_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BojairuAnimatedLogo', () {
    testWidgets('should animate the eight SVG layers every frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 320,
              child: BojairuAnimatedLogo(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsNWidgets(8));
      final initial = tester
          .widget<Transform>(find.byKey(BojairuAnimatedLogo.spiralKey))
          .transform
          .storage
          .toList();

      await tester.pump(const Duration(milliseconds: 16));

      final next = tester
          .widget<Transform>(find.byKey(BojairuAnimatedLogo.spiralKey))
          .transform
          .storage
          .toList();
      expect(next, isNot(initial));
    });
  });
}
