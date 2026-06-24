import '../../db/app_database.dart';
import '../amendment/housing_active_agreement_service.dart';
import '../realized_expense/realized_expense_ledger_service.dart';
import 'housing_settlement_window.dart';

/// Hub tile mode for realized-expense entry on the active plan screen.
enum HousingHubExpenseEntryMode {
  enterExpense,
  settlementDue,
  disabled,
}

/// Resolved hub expense-entry state for an agreement.
class HousingHubExpenseEntry {
  const HousingHubExpenseEntry({
    required this.mode,
    this.settlementWindowEnd,
  });

  final HousingHubExpenseEntryMode mode;
  final DateTime? settlementWindowEnd;
}

/// Resolves which hub expense tile to show.
Future<HousingHubExpenseEntry> resolveHubExpenseEntry(
  AppDatabase db,
  String planId, {
  required bool participationEnterEnabled,
}) async {
  if (!participationEnterEnabled) {
    return const HousingHubExpenseEntry(mode: HousingHubExpenseEntryMode.disabled);
  }
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) {
    return const HousingHubExpenseEntry(mode: HousingHubExpenseEntryMode.disabled);
  }
  final agreementSvc = HousingActiveAgreementService(db);
  if (agreementSvc.isAgreementPeriodOpen(agreement)) {
    return const HousingHubExpenseEntry(
      mode: HousingHubExpenseEntryMode.enterExpense,
    );
  }
  final ledger = RealizedExpenseLedgerService(db);
  final hasNonZero = await ledger.hasNonZeroOptimizedBalances(planId);
  if (isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
  )) {
    return HousingHubExpenseEntry(
      mode: HousingHubExpenseEntryMode.settlementDue,
      settlementWindowEnd: settlementWindowLastDayInclusive(
        agreement.periodEnd,
      ),
    );
  }
  return const HousingHubExpenseEntry(mode: HousingHubExpenseEntryMode.disabled);
}
