import '../../db/app_database.dart';
import '../../housing/split_minor_by_weights.dart';
import 'realized_expense_status.dart';

enum HousingBalanceMode { real, optimized }

/// One directed balance: [fromParticipantId] owes [toParticipantId] [amountMinor].
final class PairwiseBalanceEntry {
  const PairwiseBalanceEntry({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amountMinor,
  });

  final String fromParticipantId;
  final String toParticipantId;
  final int amountMinor;
}

final class HousingBalanceParticipant {
  const HousingBalanceParticipant({
    required this.participantId,
    required this.displayName,
    required this.letter,
    required this.orderIndex,
    this.isInactive = false,
  });

  final String participantId;
  final String displayName;
  final String letter;
  final int orderIndex;

  /// Ledger-only ghost participant after a departure.
  final bool isInactive;
}

final class HousingBalanceNodeEntry {
  const HousingBalanceNodeEntry({
    required this.participantId,
    required this.outgoingAmountMinor,
    required this.diameterPercent,
  });

  final String participantId;
  final int outgoingAmountMinor;
  final double diameterPercent;

  bool get hasOutgoing => outgoingAmountMinor > 0;
}

final class HousingBalanceModeData {
  const HousingBalanceModeData({
    required this.mode,
    required this.edges,
    required this.nodes,
  });

  final HousingBalanceMode mode;
  final List<PairwiseBalanceEntry> edges;
  final List<HousingBalanceNodeEntry> nodes;
}

final class HousingBalanceData {
  const HousingBalanceData({
    required this.participants,
    required this.realMode,
    required this.optimizedMode,
  });

  final List<HousingBalanceParticipant> participants;
  final HousingBalanceModeData realMode;
  final HousingBalanceModeData optimizedMode;

  HousingBalanceModeData modeData(HousingBalanceMode mode) {
    return mode == HousingBalanceMode.real ? realMode : optimizedMode;
  }
}

/// Builds the full housing balances domain from published realized expenses.
///
/// The `real` mode preserves aggregated directed obligations as they occur in
/// the published ledger. The `optimized` mode rebuilds deterministic net
/// settlements from those real obligations.
HousingBalanceData computeHousingBalanceData({
  required List<RealizedExpense> publishedExpenses,
  required List<PlanRatio> planRatios,
  required List<HousingBalanceParticipant> participants,
  Map<String, List<PlanRatio>> ratiosByExpenseId = const {},
  Map<String, String> departedSourceToInactiveId = const {},
}) {
  final participantIds = participants
      .map((participant) => participant.participantId)
      .toList(growable: false);
  final ledger = <String, int>{};

  String mapParticipantId(String id) => departedSourceToInactiveId[id] ?? id;

  String key(String from, String to) => '$from→$to';

  void addOwed(String from, String to, int minor) {
    from = mapParticipantId(from);
    to = mapParticipantId(to);
    if (minor <= 0 || from == to) return;
    ledger[key(from, to)] = (ledger[key(from, to)] ?? 0) + minor;
  }

  for (final expense in publishedExpenses) {
    if (expense.status != RealizedExpenseStatus.published) continue;

    if (expense.kind == RealizedExpenseKind.transfer) {
      final beneficiary = expense.beneficiaryParticipantId;
      if (beneficiary != null) {
        addOwed(
          beneficiary,
          expense.payerParticipantId,
          expense.amountMinor,
        );
      }
      continue;
    }

    final lineRatios = ratiosByExpenseId[expense.id] ??
        planRatios
            .where((r) => r.lineId == expense.planLineId)
            .toList(growable: false);
    if (lineRatios.isEmpty) continue;

    final weights = <int>[];
    final orderedIds = <String>[];
    final sortedRatios = [...lineRatios]
      ..sort((a, b) {
        final orderById = <String, int>{
          for (var i = 0; i < participantIds.length; i++)
            participantIds[i]: i,
        };
        final c = (orderById[a.participantId] ?? 1 << 20).compareTo(
          orderById[b.participantId] ?? 1 << 20,
        );
        if (c != 0) return c;
        return a.participantId.compareTo(b.participantId);
      });
    for (final ratio in sortedRatios) {
      final resolved = departedSourceToInactiveId[ratio.participantId] ??
          ratio.participantId;
      if (!participantIds.contains(resolved)) continue;
      orderedIds.add(resolved);
      weights.add(ratio.weight);
    }
    if (orderedIds.isEmpty || weights.isEmpty) continue;

    final splits = splitMinorByWeights(expense.amountMinor, weights);
    final payer = mapParticipantId(expense.payerParticipantId);
    final payerIdx = orderedIds.indexOf(payer);
    if (payerIdx >= 0) {
      reassignSplitRemainderToParticipant(
        splits,
        weights,
        expense.amountMinor,
        payerIdx,
      );
    }

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

  final realEdges = _entriesFromLedger(ledger, participantIds);
  final optimizedEdges = _computeOptimizedEdges(realEdges, participantIds);

  return HousingBalanceData(
    participants: participants,
    realMode: HousingBalanceModeData(
      mode: HousingBalanceMode.real,
      edges: realEdges,
      nodes: _buildNodeEntries(realEdges, participantIds),
    ),
    optimizedMode: HousingBalanceModeData(
      mode: HousingBalanceMode.optimized,
      edges: optimizedEdges,
      nodes: _buildNodeEntries(optimizedEdges, participantIds),
    ),
  );
}

/// Returns the optimized pairwise balances for legacy callers.
List<PairwiseBalanceEntry> computePairwiseBalances({
  required List<RealizedExpense> publishedExpenses,
  required List<PlanRatio> planRatios,
  required List<String> participantIds,
  Map<String, List<PlanRatio>> ratiosByExpenseId = const {},
}) {
  final participants = [
    for (var i = 0; i < participantIds.length; i++)
      HousingBalanceParticipant(
        participantId: participantIds[i],
        displayName: participantIds[i],
        letter: String.fromCharCode(65 + i),
        orderIndex: i,
      ),
  ];
  return computeHousingBalanceData(
    publishedExpenses: publishedExpenses,
    planRatios: planRatios,
    participants: participants,
    ratiosByExpenseId: ratiosByExpenseId,
  ).optimizedMode.edges;
}

List<PairwiseBalanceEntry> _entriesFromLedger(
  Map<String, int> ledger,
  List<String> participantIds,
) {
  final participantOrder = <String, int>{
    for (var i = 0; i < participantIds.length; i++) participantIds[i]: i,
  };
  final out = <PairwiseBalanceEntry>[];
  for (final entry in ledger.entries) {
    final parts = entry.key.split('→');
    if (parts.length != 2 || entry.value <= 0) {
      continue;
    }
    out.add(
      PairwiseBalanceEntry(
        fromParticipantId: parts[0],
        toParticipantId: parts[1],
        amountMinor: entry.value,
      ),
    );
  }
  out.sort((a, b) {
    final c = (participantOrder[a.fromParticipantId] ?? 1 << 20).compareTo(
      participantOrder[b.fromParticipantId] ?? 1 << 20,
    );
    if (c != 0) {
      return c;
    }
    return (participantOrder[a.toParticipantId] ?? 1 << 20).compareTo(
      participantOrder[b.toParticipantId] ?? 1 << 20,
    );
  });
  return out;
}

List<PairwiseBalanceEntry> _computeOptimizedEdges(
  List<PairwiseBalanceEntry> realEdges,
  List<String> participantIds,
) {
  final outgoing = <String, int>{
    for (final participantId in participantIds) participantId: 0,
  };
  final incoming = <String, int>{
    for (final participantId in participantIds) participantId: 0,
  };
  for (final edge in realEdges) {
    outgoing[edge.fromParticipantId] =
        (outgoing[edge.fromParticipantId] ?? 0) + edge.amountMinor;
    incoming[edge.toParticipantId] =
        (incoming[edge.toParticipantId] ?? 0) + edge.amountMinor;
  }

  final debtorRemainders = <String, int>{};
  final creditorRemainders = <String, int>{};
  for (final participantId in participantIds) {
    final net = (incoming[participantId] ?? 0) - (outgoing[participantId] ?? 0);
    if (net < 0) {
      debtorRemainders[participantId] = -net;
    } else if (net > 0) {
      creditorRemainders[participantId] = net;
    }
  }

  final debtors = participantIds
      .where(debtorRemainders.containsKey)
      .toList(growable: false);
  final creditors = participantIds
      .where(creditorRemainders.containsKey)
      .toList(growable: false);

  final out = <PairwiseBalanceEntry>[];
  var debtorIndex = 0;
  var creditorIndex = 0;
  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtorId = debtors[debtorIndex];
    final creditorId = creditors[creditorIndex];
    final debtorRemaining = debtorRemainders[debtorId]!;
    final creditorRemaining = creditorRemainders[creditorId]!;
    final amount = debtorRemaining < creditorRemaining
        ? debtorRemaining
        : creditorRemaining;
    if (amount > 0) {
      out.add(
        PairwiseBalanceEntry(
          fromParticipantId: debtorId,
          toParticipantId: creditorId,
          amountMinor: amount,
        ),
      );
    }
    final nextDebtorRemaining = debtorRemaining - amount;
    final nextCreditorRemaining = creditorRemaining - amount;
    if (nextDebtorRemaining <= 0) {
      debtorIndex++;
    } else {
      debtorRemainders[debtorId] = nextDebtorRemaining;
    }
    if (nextCreditorRemaining <= 0) {
      creditorIndex++;
    } else {
      creditorRemainders[creditorId] = nextCreditorRemaining;
    }
  }
  return out;
}

List<HousingBalanceNodeEntry> _buildNodeEntries(
  List<PairwiseBalanceEntry> edges,
  List<String> participantIds,
) {
  final outgoing = <String, int>{
    for (final participantId in participantIds) participantId: 0,
  };
  for (final edge in edges) {
    outgoing[edge.fromParticipantId] =
        (outgoing[edge.fromParticipantId] ?? 0) + edge.amountMinor;
  }

  final rankedIds = participantIds
      .where((participantId) => (outgoing[participantId] ?? 0) > 0)
      .toList(growable: false)
    ..sort((a, b) {
      final c = (outgoing[b] ?? 0).compareTo(outgoing[a] ?? 0);
      if (c != 0) {
        return c;
      }
      return participantIds.indexOf(a).compareTo(participantIds.indexOf(b));
    });

  final diameterPercentById = <String, double>{};
  final rankedCount = rankedIds.length;
  for (var rank = 0; rank < rankedCount; rank++) {
    diameterPercentById[rankedIds[rank]] =
        100.0 * (rankedCount - rank) / rankedCount;
  }

  return [
    for (final participantId in participantIds)
      HousingBalanceNodeEntry(
        participantId: participantId,
        outgoingAmountMinor: outgoing[participantId] ?? 0,
        diameterPercent: diameterPercentById[participantId] ?? 0,
      ),
  ];
}
