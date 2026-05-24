import '../../db/app_database.dart';
import '../../housing/split_minor_by_weights.dart';
import 'realized_expense_status.dart';

/// One directed balance: [fromParticipantId] owes [toParticipantId] [amountMinor].
class PairwiseBalanceEntry {
  const PairwiseBalanceEntry({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amountMinor,
  });

  final String fromParticipantId;
  final String toParticipantId;
  final int amountMinor;
}

/// Net settlement from published realized expenses (pairwise, deterministic).
///
/// For each published expense, split [amountMinor] by plan-line weights, then:
/// - **normal** / **advance**: each non-payer owes the payer their split share.
/// - **reimbursement**: the beneficiary owes the payer their split share.
List<PairwiseBalanceEntry> computePairwiseBalances({
  required List<RealizedExpense> publishedExpenses,
  required List<PlanRatio> planRatios,
  required List<String> participantIds,
}) {
  final ledger = <String, int>{};

  String key(String from, String to) => '$from→$to';

  void addOwed(String from, String to, int minor) {
    if (minor <= 0 || from == to) return;
    ledger[key(from, to)] = (ledger[key(from, to)] ?? 0) + minor;
  }

  for (final expense in publishedExpenses) {
    if (expense.status != RealizedExpenseStatus.published) continue;

    final lineRatios = planRatios
        .where((r) => r.lineId == expense.planLineId)
        .toList(growable: false);
    if (lineRatios.isEmpty) continue;

    final weights = <int>[];
    final orderedIds = <String>[];
    for (final id in participantIds) {
      final match = lineRatios.where((r) => r.participantId == id);
      if (match.isEmpty) continue;
      orderedIds.add(id);
      weights.add(match.first.weight);
    }
    if (orderedIds.isEmpty || weights.isEmpty) continue;

    final splits = splitMinorByWeights(expense.amountMinor, weights);
    final payer = expense.payerParticipantId;

    if (expense.kind == RealizedExpenseKind.reimbursement) {
      final beneficiary = expense.beneficiaryParticipantId;
      if (beneficiary != null) {
        final idx = orderedIds.indexOf(beneficiary);
        if (idx >= 0) addOwed(beneficiary, payer, splits[idx]);
      }
    } else {
      for (var i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        if (id == payer) continue;
        addOwed(id, payer, splits[i]);
      }
    }
  }

  // Net opposite directions between the same pair.
  final pairs = ledger.keys.toList(growable: false);
  for (final k in pairs) {
    final parts = k.split('→');
    if (parts.length != 2) continue;
    final reverse = key(parts[1], parts[0]);
    final reverseAmount = ledger[reverse];
    if (reverseAmount == null) continue;
    final forward = ledger[k]!;
    if (forward > reverseAmount) {
      ledger[k] = forward - reverseAmount;
      ledger.remove(reverse);
    } else if (reverseAmount > forward) {
      ledger[reverse] = reverseAmount - forward;
      ledger.remove(k);
    } else {
      ledger.remove(k);
      ledger.remove(reverse);
    }
  }

  final out = <PairwiseBalanceEntry>[];
  for (final entry in ledger.entries) {
    final parts = entry.key.split('→');
    if (parts.length != 2 || entry.value <= 0) continue;
    out.add(
      PairwiseBalanceEntry(
        fromParticipantId: parts[0],
        toParticipantId: parts[1],
        amountMinor: entry.value,
      ),
    );
  }
  out.sort((a, b) {
    final c = a.fromParticipantId.compareTo(b.fromParticipantId);
    if (c != 0) return c;
    return a.toParticipantId.compareTo(b.toParticipantId);
  });
  return out;
}
