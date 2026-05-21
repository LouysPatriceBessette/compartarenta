import '../split_minor_by_weights.dart';
import 'expense_ratio_template_repository.dart';

/// One participant row in the split grid.
class ExpenseSplitRow {
  ExpenseSplitRow({
    required this.participantId,
    required this.displayName,
    required this.amountMinor,
    required this.weightBps,
  });

  final String participantId;
  final String displayName;
  int amountMinor;
  int weightBps;
}

/// Mutable split grid state for one expense amount.
class ExpenseSplitGridState {
  ExpenseSplitGridState({
    required this.participantIds,
    required this.displayNames,
    required List<ExpenseSplitRow> rows,
    required this.totalMinor,
  }) : rows = List<ExpenseSplitRow>.from(rows);

  factory ExpenseSplitGridState.equalParts({
    required List<String> participantIds,
    required List<String> displayNames,
    required int totalMinor,
  }) {
    assert(participantIds.length == displayNames.length);
    if (participantIds.isEmpty) {
      return ExpenseSplitGridState(
        participantIds: const [],
        displayNames: const [],
        rows: const [],
        totalMinor: totalMinor,
      );
    }
    final n = participantIds.length;
    final weights = List<int>.filled(n, 0);
    for (var i = 0; i < n - 1; i++) {
      weights[i] = ExpenseRatioTemplateRepository.weightScale ~/ n;
    }
    weights[n - 1] =
        ExpenseRatioTemplateRepository.weightScale -
        weights.take(n - 1).fold<int>(0, (a, b) => a + b);
    final amounts = splitMinorByWeights(totalMinor, weights);
    final rows = <ExpenseSplitRow>[];
    for (var i = 0; i < n; i++) {
      rows.add(
        ExpenseSplitRow(
          participantId: participantIds[i],
          displayName: displayNames[i],
          amountMinor: amounts[i],
          weightBps: weights[i],
        ),
      );
    }
    return ExpenseSplitGridState(
      participantIds: participantIds,
      displayNames: displayNames,
      rows: rows,
      totalMinor: totalMinor,
    );
  }

  final List<String> participantIds;
  final List<String> displayNames;
  final List<ExpenseSplitRow> rows;
  int totalMinor;

  int get sumAmountMinor => rows.fold<int>(0, (a, r) => a + r.amountMinor);

  int get amountDeltaMinor => sumAmountMinor - totalMinor;

  bool get hasAmountMismatch => totalMinor > 0 && amountDeltaMinor != 0;

  bool get weightsAreEqualParts =>
      rows.isNotEmpty &&
      weightsAreMaximallyBalanced(
        [for (final r in rows) r.weightBps],
        weightScale: ExpenseRatioTemplateRepository.weightScale,
      );

  void resetEqualParts() {
    final next = ExpenseSplitGridState.equalParts(
      participantIds: participantIds,
      displayNames: displayNames,
      totalMinor: totalMinor,
    );
    rows
      ..clear()
      ..addAll(next.rows);
  }

  void applyWeights(Map<String, int> weightsByParticipant) {
    final ordered = <int>[
      for (final pid in participantIds) weightsByParticipant[pid] ?? 0,
    ];
    final amounts = splitMinorByWeights(totalMinor, ordered);
    for (var i = 0; i < rows.length; i++) {
      rows[i].weightBps = ordered[i];
      rows[i].amountMinor = amounts[i];
    }
  }

  void setTotalMinor(int nextTotal) {
    totalMinor = nextTotal;
    if (totalMinor <= 0) return;
    final weights = [for (final r in rows) r.weightBps];
    final amounts = splitMinorByWeights(totalMinor, weights);
    for (var i = 0; i < rows.length; i++) {
      rows[i].amountMinor = amounts[i];
    }
  }

  void onAmountEdited(int index, int amountMinor) {
    if (index < 0 || index >= rows.length || totalMinor <= 0) return;
    rows[index].amountMinor = amountMinor.clamp(0, 1 << 31);
    rows[index].weightBps =
        ((rows[index].amountMinor * ExpenseRatioTemplateRepository.weightScale) /
                totalMinor)
            .round();
  }

  void onPercentTenthsEdited(int index, int percentTenths) {
    if (index < 0 || index >= rows.length || totalMinor <= 0) return;
    final w = (percentTenths * ExpenseRatioTemplateRepository.weightScale ~/ 1000)
        .clamp(0, ExpenseRatioTemplateRepository.weightScale);
    rows[index].weightBps = w;
    rows[index].amountMinor =
        (totalMinor * w ~/ ExpenseRatioTemplateRepository.weightScale);
  }

  Map<String, int> weightsByParticipant() => {
    for (final r in rows) r.participantId: r.weightBps,
  };
}
