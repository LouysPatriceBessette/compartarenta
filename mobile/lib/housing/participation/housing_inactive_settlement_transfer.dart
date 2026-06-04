/// Validation for closure transfers toward an inactive participant.
abstract final class HousingInactiveSettlementTransfer {
  /// Returns null when valid; otherwise a user-facing error key or message.
  static String? validateAmount({
    required int amountMinor,
    required int inactiveNetBalanceMinor,
  }) {
    if (amountMinor == 0) {
      return 'zero_amount';
    }
    // Positive: active pays inactive (reduces debt owed to inactive).
    // Negative: inactive pays active (reduces debt inactive owes).
    if (amountMinor > 0) {
      if (inactiveNetBalanceMinor >= 0) {
        return 'cannot_create_credit_for_inactive';
      }
      if (amountMinor > -inactiveNetBalanceMinor) {
        return 'exceeds_inactive_debt';
      }
    } else {
      final abs = -amountMinor;
      if (inactiveNetBalanceMinor <= 0) {
        return 'cannot_increase_inactive_debt';
      }
      if (abs > inactiveNetBalanceMinor) {
        return 'exceeds_inactive_credit';
      }
    }
    return null;
  }
}
