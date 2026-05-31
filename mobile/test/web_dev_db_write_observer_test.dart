import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/web_dev_db_write_observer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('write observer notifies after INSERT', () async {
    debugWebDbWriteHook = null;
    final base = NativeDatabase.memory();
    final observed = devHostSessionWriteObserver(base);
    final db = AppDatabase.forTesting(observed);
    addTearDown(db.close);

    var writes = 0;
    debugWebDbWriteHook = () => writes++;

    await db.into(db.plans).insert(
          PlansCompanion.insert(
            id: 'plan:observer',
            type: 'housing',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    expect(writes, 1);
    debugWebDbWriteHook = null;
  });
}
