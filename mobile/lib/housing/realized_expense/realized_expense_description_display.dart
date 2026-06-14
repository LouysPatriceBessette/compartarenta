import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Stored [RealizedExpense.description] for system early-withdrawal penalties.
const kEarlyWithdrawalPenaltyDescriptionKey = 'early_withdrawal_penalty';

bool isEarlyWithdrawalPenaltyExpense(RealizedExpense expense) {
  return expense.description?.trim() == kEarlyWithdrawalPenaltyDescriptionKey;
}

String realizedExpenseDescriptionForList(
  AppLocalizations l10n,
  RealizedExpense expense,
) {
  if (isEarlyWithdrawalPenaltyExpense(expense)) {
    return l10n.housingEarlyWithdrawalPenaltyDescription;
  }
  return (expense.description ?? '').trim();
}

String realizedExpenseDescriptionForDetail(
  AppLocalizations l10n,
  RealizedExpense expense, {
  required String beneficiaryDisplayName,
}) {
  if (isEarlyWithdrawalPenaltyExpense(expense)) {
    final name = beneficiaryDisplayName.trim();
    if (name.isEmpty) {
      return l10n.housingEarlyWithdrawalPenaltyDescription;
    }
    return '${l10n.housingEarlyWithdrawalPenaltyDescription}\n'
        '${l10n.housingEarlyWithdrawalPenaltyOwedTo(name)}';
  }
  return (expense.description ?? '').trim();
}
