import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/qa_scenario_seed.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_ledger_service.dart';
import 'package:compartarenta/housing/settlement/housing_settlement_window.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final scenarios = <String, DateTime>{
    'period_end_day': DateTime(2027, 8, 11, 9),
    'settlement_open': DateTime(2027, 8, 11, 9),
    'settlement_window_open': DateTime(2027, 8, 11, 9),
    'settlement_last_day': DateTime(2027, 9, 10, 9),
    'settlement_closed': DateTime(2027, 9, 11, 9),
    'renewal_fork_visible': DateTime(2027, 8, 15, 9),
    'voluntary_withdrawal_ack_j5': DateTime(2027, 8, 11, 9),
    'voluntary_withdrawal_effective': DateTime(2027, 8, 11, 9),
    'proposal_response_expired': DateTime(2027, 8, 11, 9),
    'proposal_wizard_expenses': DateTime(2027, 6, 15, 9),
  };

  for (final entry in scenarios.entries) {
    test('${entry.key} seed satisfies postconditions', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await applyQaScenario(db, entry.key);
      await assertQaScenarioPostconditions(
        db: db,
        scenarioId: entry.key,
        now: entry.value,
      );
    });
  }

  test('settlement_open has non-zero balances and window end 2027-09-10', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await applyQaScenario(db, 'settlement_open');

    final agreement = await db.getAgreementForPlan(kQaSettlementOpenPlanId);
    expect(agreement, isNotNull);
    final ledger = RealizedExpenseLedgerService(db);
    expect(
      await ledger.hasNonZeroOptimizedBalances(kQaSettlementOpenPlanId),
      isTrue,
    );
    expect(
      settlementWindowLastDayInclusive(agreement!.periodEnd),
      DateTime(2027, 9, 10),
    );
  });

  test('all scenario ids have manifests in kQaScenarioIds', () {
    expect(kQaScenarioIds, containsAll(scenarios.keys));
  });
}
