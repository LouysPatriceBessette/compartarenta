import 'package:compartarenta/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'housing_plan_navigation_e2e_harness.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('housing plan navigation E2E', () {
    late HousingPlanNavigationE2EContext ctx;

    setUp(() async {
      ctx = await setUpHousingPlanNavigationE2E();
    });

    tearDown(() async {
      await tearDownHousingPlanNavigationE2E(ctx);
    });

    testWidgets(
      'after unanimous acceptance, housing entry shows the active hub',
      (tester) async {
        await tester.pumpWidget(CompartarentaApp(config: ctx.config));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Housing'));
        await tester.pumpAndSettle();

        expect(find.text('Submit my plan'), findsOneWidget);
        await _tapSubmitPlanFromSummary(tester);
        await ensurePendingProposalSubmitted(ctx);
        notifySteadyInboxTick(ctx);
        await tester.pumpAndSettle();

        await simulateProposalAccepted(ctx);
        await applyProposalSettlementToUi(tester, ctx);

        expect(
          find.byKey(const ValueKey('active-hub-housing:default')),
          findsOneWidget,
        );
        expect(find.text('Submit an expense'), findsOneWidget);
        expect(find.text('Housing plans'), findsNothing);
      },
    );

    testWidgets(
      'after rejection, housing entry shows the archive list',
      (tester) async {
        await tester.pumpWidget(CompartarentaApp(config: ctx.config));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Housing'));
        await tester.pumpAndSettle();

        await _tapSubmitPlanFromSummary(tester);
        await ensurePendingProposalSubmitted(ctx);
        notifySteadyInboxTick(ctx);
        await tester.pumpAndSettle();
        await simulateProposalRejected(ctx);
        await applyProposalSettlementToUi(tester, ctx);

        expect(find.text('Housing plans'), findsOneWidget);
        expect(find.text('Rejected plan'), findsWidgets);
        expect(find.text('Create a new plan'), findsOneWidget);
        expect(find.text('Active agreement'), findsNothing);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Housing plans'), findsNothing);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      },
    );

    testWidgets(
      'after rejection, create new plan opens the wizard at participants',
      (tester) async {
        await tester.pumpWidget(CompartarentaApp(config: ctx.config));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Housing'));
        await tester.pumpAndSettle();

        await _tapSubmitPlanFromSummary(tester);
        await ensurePendingProposalSubmitted(ctx);
        notifySteadyInboxTick(ctx);
        await tester.pumpAndSettle();
        await simulateProposalRejected(ctx);
        await applyProposalSettlementToUi(tester, ctx);

        expect(find.text('Create a new plan'), findsOneWidget);
        await tester.tap(find.text('Create a new plan'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('2 participants'), findsOneWidget);
        expect(find.text('Housing plan'), findsOneWidget);
        expect(find.text('Housing plans'), findsNothing);
      },
    );
  });
}

/// Taps **Submit my plan** and confirms the response-window / notification dialogs.
Future<void> _tapSubmitPlanFromSummary(WidgetTester tester) async {
  await tester.tap(find.text('Submit my plan'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  final skipNotifications = find.text('No, continue');
  if (skipNotifications.evaluate().isNotEmpty) {
    await tester.tap(skipNotifications);
    await tester.pumpAndSettle();
  }
}
