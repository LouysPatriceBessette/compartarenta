import 'package:compartarenta/housing/proposals/housing_activation_notification_service.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

void main() {
  test('maybeNotifyAgreementActivated dedupes by revisionId', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final db = _DbForTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final svc = HousingActivationNotificationService(db);

    expect(await svc.alreadyNotified('rev:1'), isFalse);
    await svc.markNotified('rev:1');
    expect(await svc.alreadyNotified('rev:1'), isTrue);
    expect(await svc.alreadyNotified('rev:2'), isFalse);
  });
}
