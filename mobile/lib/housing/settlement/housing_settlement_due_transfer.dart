import '../realized_expense/realized_expense_balance.dart';

/// Validation for settlement transfers between active participants.
abstract final class HousingSettlementDueTransfer {
  /// Net optimized balance from [selfId] toward [otherId].
  ///
  /// Positive: [otherId] owes [selfId]. Negative: [selfId] owes [otherId].
  static int pairwiseNetFromSelf({
    required List<PairwiseBalanceEntry> edges,
    required String selfId,
    required String otherId,
  }) {
    var selfOwesOther = 0;
    var otherOwesSelf = 0;
    for (final edge in edges) {
      if (edge.fromParticipantId == selfId &&
          edge.toParticipantId == otherId) {
        selfOwesOther += edge.amountMinor;
      }
      if (edge.fromParticipantId == otherId &&
          edge.toParticipantId == selfId) {
        otherOwesSelf += edge.amountMinor;
      }
    }
    return otherOwesSelf - selfOwesOther;
  }

  /// Returns null when valid; otherwise an error code for l10n mapping.
  static String? validateAmount({
    required int amountMinor,
    required int pairwiseNetFromSelfMinor,
  }) {
    if (amountMinor == 0) {
      return 'zero_amount';
    }
    if (amountMinor > 0) {
      if (pairwiseNetFromSelfMinor >= 0) {
        return 'cannot_create_credit';
      }
      if (amountMinor > -pairwiseNetFromSelfMinor) {
        return 'exceeds_debt';
      }
    } else {
      final abs = -amountMinor;
      if (pairwiseNetFromSelfMinor <= 0) {
        return 'cannot_increase_debt';
      }
      if (abs > pairwiseNetFromSelfMinor) {
        return 'exceeds_credit';
      }
    }
    return null;
  }
}
