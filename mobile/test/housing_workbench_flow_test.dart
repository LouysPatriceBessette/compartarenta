import 'package:compartarenta/app.dart';
import 'package:compartarenta/config/app_config.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('two housing plans with self show workbench listing', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.complete': true,
      'profile.displayName': 'Tester',
      'profile.avatarId': 'mdi:0',
      'prefs.currency': 'CAD',
      'prefs.dateFormat': 'yyyy-MM-dd',
      'prefs.distanceUnit': 'km',
      'plans.enabled': <String>['housing'],
      'prefs.languageCode': 'en',
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);

    addTearDown(() async {
      await db.close();
      AppDatabase.clearProcessScopeIfReferencing(db);
    });

    for (final (id, title) in [
      ('wb-alpha', 'Workbench Alpha'),
      ('wb-beta', 'Workbench Beta'),
    ]) {
      await db.upsertPlan(
        PlansCompanion.insert(
          id: id,
          type: 'housing',
          createdAt: DateTime.utc(2026, 5, 1),
          title: drift.Value(title),
          currency: const drift.Value('CAD'),
          notes: const drift.Value.absent(),
        ),
      );
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$id:self',
          displayName: 'Me',
          avatarId: 'mdi:0',
          createdAt: DateTime.utc(2026, 5, 1),
        ),
      );
    }

    final config = AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: Uri.parse('https://example.invalid'),
    );

    await tester.pumpWidget(CompartarentaApp(config: config));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();

    expect(find.text('Housing plans'), findsOneWidget);
    expect(find.text('Plan with 1 participants'), findsNWidgets(2));
    expect(find.text('Draft(s)'), findsOneWidget);
  });
}
