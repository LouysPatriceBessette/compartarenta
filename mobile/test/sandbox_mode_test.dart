import 'package:compartarenta/sandbox/sandbox_bot_catalog.dart';
import 'package:compartarenta/sandbox/sandbox_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:compartarenta/prefs/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bot catalog is seven fixed names', () {
    expect(SandboxBotCatalog.displayNames, hasLength(7));
    expect(SandboxBotCatalog.displayNames.first, 'Louys');
    expect(SandboxBotCatalog.displayNames.last, 'Youkie');
    expect(SandboxBotCatalog.maxBots, 7);
  });

  test('sandbox prefs survive conceptual wipe keys', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();
    expect(prefs.sandboxMode, isFalse);
    await prefs.setSandboxMode(true);
    await prefs.setSandboxEnteredAt(DateTime.utc(2026, 7, 15, 12));
    expect(SandboxMode.isActive(prefs), isTrue);
    expect(prefs.sandboxEnteredAt, isNotNull);
    await prefs.clearSandboxLifecyclePrefs();
    expect(prefs.sandboxMode, isFalse);
  });
}
