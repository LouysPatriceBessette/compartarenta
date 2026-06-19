import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/web_dev_db_write_observer.dart';
import 'package:compartarenta/debug/web_dev_host_session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('write observer notifies after INSERT', () async {
    debugWebDbWriteHook = null;
    devHostDriftOpenTransactions = 0;
    final base = NativeDatabase.memory();
    final observed = devHostSessionWriteObserver(base);
    final db = AppDatabase.forTesting(observed);
    addTearDown(() {
      devHostDriftOpenTransactions = 0;
      db.close();
    });

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

  test('transaction depth returns to zero after commit', () async {
    devHostDriftOpenTransactions = 0;
    final base = NativeDatabase.memory();
    final observed = devHostSessionWriteObserver(base);
    final db = AppDatabase.forTesting(observed);
    addTearDown(() {
      devHostDriftOpenTransactions = 0;
      db.close();
    });

    expect(devHostDriftOpenTransactions, 0);

    await db.transaction(() async {
      expect(devHostDriftOpenTransactions, 1);
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'plan:txn',
              type: 'housing',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          );
    });

    expect(devHostDriftOpenTransactions, 0);
    await waitForDevHostDriftTransactionsIdle();
  });

  test('deferred save suppresses write hook until scope ends', () async {
    devHostSessionSaveDeferDepth = 0;
    final base = NativeDatabase.memory();
    final observed = devHostSessionWriteObserver(base);
    final db = AppDatabase.forTesting(observed);
    addTearDown(() {
      devHostSessionSaveDeferDepth = 0;
      db.close();
    });

    var writes = 0;
    debugWebDbWriteHook = () => writes++;

    await runWithDeferredDevHostSessionSave(db, () async {
      await db.into(db.plans).insert(
            PlansCompanion.insert(
              id: 'plan:defer',
              type: 'housing',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          );
      expect(writes, 0);
      return true;
    });

    expect(writes, 0);
    expect(devHostSessionSaveDeferDepth, 0);
    debugWebDbWriteHook = null;
  });
}
