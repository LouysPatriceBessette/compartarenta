import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/util/deadline_remaining.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLabel(
    WidgetTester tester, {
    required DateTime deadline,
    Widget Function(BuildContext context, AppLocalizations l10n)? builder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return builder?.call(context, l10n) ??
                  DeadlineRelativeLabel(
                    deadlineUtc: deadline,
                    l10n: l10n,
                  );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('DeadlineDisplay shows title and date lines', (tester) async {
    final deadline = DateTime.utc(2026, 6, 1, 14, 30);
    await pumpLabel(
      tester,
      deadline: deadline,
      builder: (context, l10n) => DeadlineDisplay(
        title: l10n.housingInviteResponseDeadlineTitle,
        deadlineUtc: deadline,
        dateFormat: 'YYYY-MM-DD',
        l10n: l10n,
      ),
    );
    expect(
      find.text('Fin du délai de réponse :'),
      findsOneWidget,
    );
    expect(find.textContaining('2026-06-01'), findsOneWidget);
  });

  testWidgets('shows days when more than 24 hours remain', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(hours: 50));
    await pumpLabel(tester, deadline: deadline);
    expect(find.textContaining('Dans'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsNothing);
  });

  testWidgets('shows today between 4 and 24 hours', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(hours: 10));
    await pumpLabel(tester, deadline: deadline);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('shows red countdown within 4 hours', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(hours: 2));
    await pumpLabel(tester, deadline: deadline);
    expect(find.textContaining('Dans 0'), findsOneWidget);
  });

  testWidgets('shows expired after deadline', (tester) async {
    final deadline = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    await pumpLabel(tester, deadline: deadline);
    expect(find.text('Expiré'), findsOneWidget);
  });
}
