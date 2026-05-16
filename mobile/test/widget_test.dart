// Basic Flutter widget test: app shell reaches [HomeScreen] after prefs load.

import 'package:compartarenta/app.dart';
import 'package:compartarenta/config/app_config.dart';
import 'package:compartarenta/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {
      'onboarding.complete': true,
    });
  });

  testWidgets('App starts and shows HomeScreen', (WidgetTester tester) async {
    final config = AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: Uri.parse('https://example.invalid'),
    );

    await tester.pumpWidget(CompartarentaApp(config: config));
    // Loading uses [CircularProgressIndicator] (non-terminating ticker);
    // avoid [pumpAndSettle] until prefs have loaded and the router is built.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(HomeScreen).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
