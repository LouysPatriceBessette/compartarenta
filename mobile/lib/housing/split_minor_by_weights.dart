import 'dart:math' as math;

/// True when [weightsBps] sums to [weightScale] and every weight differs by at
/// most 1 from every other (the only way to split [weightScale] across [n]
/// integers as fairly as possible, e.g. 3333/3333/3334 for n=3).
bool weightsAreMaximallyBalanced(
  List<int> weightsBps, {
  int weightScale = 10000,
}) {
  if (weightsBps.isEmpty) return false;
  final sum = weightsBps.fold<int>(0, (a, b) => a + b);
  if (sum != weightScale) return false;
  var minW = weightsBps.first;
  var maxW = weightsBps.first;
  for (final w in weightsBps.skip(1)) {
    minW = math.min(minW, w);
    maxW = math.max(maxW, w);
  }
  return maxW - minW <= 1;
}

/// Splits [basisMinor] across participants in lockstep with [weightsBps].
///
/// - When weights are **maximally balanced** (any two differ by at most 1 and
///   they sum to [weightScale]), each participant gets the same integer share
///   `basisMinor ~/ n`, and the `basisMinor % n` leftover cents go to those
///   with the **largest** weights first (then stable index), matching the idea
///   that the slightly larger weight (e.g. 3334 vs 3333) absorbs rounding.
/// - Otherwise uses **largest-remainder (Hamilton)** on proportional quotas so
///   parts still sum to [basisMinor] exactly.
List<int> splitMinorByWeights(
  int basisMinor,
  List<int> weightsBps, {
  int weightScale = 10000,
}) {
  if (weightsBps.isEmpty) return const [];
  if (basisMinor <= 0) {
    return List<int>.filled(weightsBps.length, 0);
  }
  final sumW = weightsBps.fold<int>(0, (a, b) => a + b);
  if (sumW != weightScale) {
    return List<int>.filled(weightsBps.length, 0);
  }

  final n = weightsBps.length;
  if (weightsAreMaximallyBalanced(weightsBps, weightScale: weightScale)) {
    final base = basisMinor ~/ n;
    final rem = basisMinor % n;
    final out = List<int>.filled(n, base);
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final c = weightsBps[b].compareTo(weightsBps[a]);
        if (c != 0) return c;
        return a.compareTo(b);
      });
    for (var k = 0; k < rem; k++) {
      out[order[k]]++;
    }
    return out;
  }

  final out = List<int>.generate(
    n,
    (i) => (basisMinor * weightsBps[i]) ~/ weightScale,
  );
  var deficit = basisMinor - out.fold<int>(0, (a, b) => a + b);
  if (deficit <= 0) {
    return out;
  }

  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) {
      final ra = (basisMinor * weightsBps[a]) % weightScale;
      final rb = (basisMinor * weightsBps[b]) % weightScale;
      final c = rb.compareTo(ra);
      if (c != 0) return c;
      return a.compareTo(b);
    });

  for (var k = 0; k < deficit && k < order.length; k++) {
    out[order[k]]++;
  }
  return out;
}

/// Moves integer remainder cents from [splits] onto [recipientIndex].
///
/// Used when the payer fronted the expense: any +1 cent from Hamilton (or
/// equal-part) rounding is attributed to them, not the last roster slot.
void reassignSplitRemainderToParticipant(
  List<int> splits,
  List<int> weightsBps,
  int basisMinor,
  int recipientIndex, {
  int weightScale = 10000,
}) {
  if (recipientIndex < 0 ||
      recipientIndex >= splits.length ||
      splits.isEmpty) {
    return;
  }

  final floors = List<int>.generate(
    splits.length,
    (i) => weightsAreMaximallyBalanced(weightsBps, weightScale: weightScale)
        ? basisMinor ~/ splits.length
        : (basisMinor * weightsBps[i]) ~/ weightScale,
  );

  for (var i = 0; i < splits.length; i++) {
    if (i == recipientIndex) continue;
    final extra = splits[i] - floors[i];
    if (extra <= 0) continue;
    splits[i] -= extra;
    splits[recipientIndex] += extra;
  }
}
