import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/qa_scenario_seed.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_ledger_service.dart';
import 'package:compartarenta/housing/settlement/housing_settlement_window.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settlement_window_open seed opens settlement hub tile', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await applyQaScenario(db, 'settlement_window_open');

    final deviceNow = DateTime(2027, 8, 11, 9);
    await assertQaScenarioPostconditions(
      db: db,
      scenarioId: 'settlement_window_open',
      now: deviceNow,
    );

    final agreement = await db.getAgreementForPlan(kQaSettlementOpenPlanId);
    expect(agreement, isNotNull);
    final ledger = RealizedExpenseLedgerService(db);
    expect(
      await ledger.hasNonZeroOptimizedBalances(kQaSettlementOpenPlanId),
      isTrue,
    );
    expect(
      isSettlementOpen(
        agreement: agreement!,
        hasNonZeroOptimizedBalances: true,
        now: deviceNow,
      ),
      isTrue,
    );
    expect(
      settlementWindowLastDayInclusive(agreement.periodEnd),
      DateTime(2027, 9, 10),
    );
  });
}
