import 'package:compartarenta/housing/split_minor_by_weights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splitMinorByWeights equal thirds sums to basis', () {
    const basis = 90000;
    const w = [3333, 3333, 3334];
    final parts = splitMinorByWeights(basis, w);
    expect(parts, [30000, 30000, 30000]);
    expect(parts.fold<int>(0, (a, b) => a + b), basis);
  });

  test('splitMinorByWeights handles two-way split', () {
    const basis = 101;
    const w = [5000, 5000];
    final parts = splitMinorByWeights(basis, w);
    expect(parts.fold<int>(0, (a, b) => a + b), basis);
    expect((parts[0] - parts[1]).abs(), lessThanOrEqualTo(1));
  });

  test(
    'splitMinorByWeights \$4500 in 7 maximally-balanced parts (minor units)',
    () {
    // 4500.00 USD → 450_000 minor; weights are 10000 bps split as evenly as
    // possible across 7 people: 1429+1429+1429+1429+1428+1428+1428 = 10000.
    const basisMinor = 450000;
    const weightsBps = [1429, 1429, 1429, 1429, 1428, 1428, 1428];
    final parts = splitMinorByWeights(basisMinor, weightsBps);
    expect(parts, [64286, 64286, 64286, 64286, 64286, 64285, 64285]);
    expect(parts.fold<int>(0, (a, b) => a + b), basisMinor);
  });

  test('reassignSplitRemainderToParticipant moves cent to payer index', () {
    const weights = [3333, 3333, 3334];
    const basis = 10000;
    final splits = splitMinorByWeights(basis, weights);
    expect(splits, [3333, 3333, 3334]);
    reassignSplitRemainderToParticipant(splits, weights, basis, 0);
    expect(splits, [3334, 3333, 3333]);
  });

  test('splitPenaltyMinorEquallyFloored floors each share without remainder', () {
    expect(splitPenaltyMinorEquallyFloored(100000, 3), [33333, 33333, 33333]);
    expect(
      splitPenaltyMinorEquallyFloored(100000, 3).fold<int>(0, (a, b) => a + b),
      99999,
    );
    expect(splitPenaltyMinorEquallyFloored(100000, 2), [50000, 50000]);
  });
}
