import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_balance.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_line_snapshot.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHousingBalanceData', () {
    const planId = 'plan';
    final participants = [
      const HousingBalanceParticipant(
        participantId: 'p1',
        displayName: 'A',
        letter: 'A',
        orderIndex: 0,
      ),
      const HousingBalanceParticipant(
        participantId: 'p2',
        displayName: 'B',
        letter: 'B',
        orderIndex: 1,
      ),
      const HousingBalanceParticipant(
        participantId: 'p3',
        displayName: 'C',
        letter: 'C',
        orderIndex: 2,
      ),
    ];

    test('should split a normal expense into real debt owed to the payer', () {
      final data = computeHousingBalanceData(
        publishedExpenses: [
          _expense(
            id: 'e1',
            amountMinor: 10000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.normal,
          ),
        ],
        planRatios: _equalRatios(planId, 'line', ['p1', 'p2']),
        participants: participants.take(2).toList(growable: false),
      );

      expect(data.realMode.edges, hasLength(1));
      expect(data.realMode.edges.single.fromParticipantId, 'p2');
      expect(data.realMode.edges.single.toParticipantId, 'p1');
      expect(data.realMode.edges.single.amountMinor, 5000);
    });

    test('should keep opposite directions distinct in real mode', () {
      final data = computeHousingBalanceData(
        publishedExpenses: [
          _expense(
            id: 'expense',
            amountMinor: 100000,
            payerParticipantId: 'p2',
            kind: RealizedExpenseKind.normal,
          ),
          _expense(
            id: 'transfer',
            planLineId: '',
            amountMinor: 50000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: 'p2',
          ),
        ],
        planRatios: _equalRatios(planId, 'line', ['p1', 'p2']),
        participants: participants.take(2).toList(growable: false),
      );

      expect(
        _edgeAmounts(data.realMode.edges),
        equals({'p1->p2': 50000, 'p2->p1': 50000}),
      );
      expect(data.optimizedMode.edges, isEmpty);
    });

    test('should rebuild optimized balances for the three participant example', () {
      final data = computeHousingBalanceData(
        publishedExpenses: [
          _expense(
            id: 'expense',
            amountMinor: 120000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.normal,
          ),
          _expense(
            id: 'b-to-a',
            planLineId: '',
            amountMinor: 40000,
            payerParticipantId: 'p2',
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: 'p1',
          ),
          _expense(
            id: 'c-to-b-loan',
            planLineId: '',
            amountMinor: 10000,
            payerParticipantId: 'p3',
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: 'p2',
          ),
          _expense(
            id: 'c-to-a',
            planLineId: '',
            amountMinor: 40000,
            payerParticipantId: 'p3',
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: 'p1',
          ),
        ],
        planRatios: _equalRatios(planId, 'line', ['p1', 'p2', 'p3']),
        participants: participants,
      );

      expect(
        _edgeAmounts(data.optimizedMode.edges),
        equals({'p2->p3': 10000}),
      );
    });

    test('should rank node diameters by descending outgoing totals', () {
      final data = computeHousingBalanceData(
        publishedExpenses: [
          _expense(
            id: 'e1',
            amountMinor: 20000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.normal,
            planLineId: 'line-a',
          ),
          _expense(
            id: 'e2',
            amountMinor: 10000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.normal,
            planLineId: 'line-b',
          ),
        ],
        planRatios: [
          ..._equalRatios(planId, 'line-a', ['p1', 'p2']),
          ..._equalRatios(planId, 'line-b', ['p1', 'p3']),
        ],
        participants: participants,
      );

      final realNodes = {
        for (final node in data.realMode.nodes) node.participantId: node,
      };
      expect(realNodes['p2']!.diameterPercent, 100);
      expect(realNodes['p3']!.diameterPercent, 50);
      expect(realNodes['p1']!.diameterPercent, 0);
    });

    test('should include published expenses whose plan line was removed', () {
      final expense = _expense(
        id: 'orphan',
        amountMinor: 2000,
        payerParticipantId: 'p1',
        kind: RealizedExpenseKind.normal,
        planLineId: 'removed-line',
        splitRatiosJson:
            '[{"participantId":"p1","weight":5000},{"participantId":"p2","weight":5000}]',
      );
      final data = computeHousingBalanceData(
        publishedExpenses: [expense],
        planRatios: const [],
        participants: participants.take(2).toList(growable: false),
        ratiosByExpenseId: {
          expense.id: planRatiosFromSplitJson(
            splitRatiosJson: expense.splitRatiosJson,
            planId: planId,
            lineId: expense.planLineId,
          ),
        },
      );

      expect(data.realMode.edges, hasLength(1));
      expect(data.realMode.edges.single.fromParticipantId, 'p2');
      expect(data.realMode.edges.single.toParticipantId, 'p1');
      expect(data.realMode.edges.single.amountMinor, 1000);
    });

    test('should prefer per-expense snapshot ratios over live plan ratios', () {
      final expense = _expense(
        id: 'renamed-line',
        amountMinor: 10000,
        payerParticipantId: 'p1',
        kind: RealizedExpenseKind.normal,
        planLineId: 'line-a',
        splitRatiosJson:
            '[{"participantId":"p1","weight":7000},{"participantId":"p2","weight":3000}]',
      );
      final data = computeHousingBalanceData(
        publishedExpenses: [expense],
        planRatios: _equalRatios(planId, 'line-a', ['p1', 'p2']),
        participants: participants.take(2).toList(growable: false),
        ratiosByExpenseId: {
          expense.id: planRatiosFromSplitJson(
            splitRatiosJson: expense.splitRatiosJson,
            planId: planId,
            lineId: expense.planLineId,
          ),
        },
      );

      expect(data.realMode.edges.single.amountMinor, 3000);
    });

    test('should preserve legacy pairwise balances as optimized edges', () {
      final balances = computePairwiseBalances(
        publishedExpenses: [
          _expense(
            id: 'expense',
            amountMinor: 100000,
            payerParticipantId: 'p2',
            kind: RealizedExpenseKind.normal,
          ),
          _expense(
            id: 'transfer',
            planLineId: '',
            amountMinor: 50000,
            payerParticipantId: 'p1',
            kind: RealizedExpenseKind.transfer,
            beneficiaryParticipantId: 'p2',
          ),
        ],
        planRatios: _equalRatios(planId, 'line', ['p1', 'p2']),
        participantIds: ['p1', 'p2'],
      );

      expect(balances, isEmpty);
    });
  });
}

RealizedExpense _expense({
  required String id,
  required int amountMinor,
  required String payerParticipantId,
  required String kind,
  String planLineId = 'line',
  String? beneficiaryParticipantId,
  String? splitRatiosJson,
}) {
  final timestamp = DateTime.utc(2026, 5, 1);
  return RealizedExpense(
    id: id,
    packageId: 'pkg',
    planId: 'plan',
    planLineId: planLineId,
    status: RealizedExpenseStatus.published,
    amountMinor: amountMinor,
    currency: 'CAD',
    paymentDate: timestamp,
    payerParticipantId: payerParticipantId,
    kind: kind,
    beneficiaryParticipantId: beneficiaryParticipantId,
    priorExpenseId: null,
    planLineTitleSnapshot: null,
    splitRatiosJson: splitRatiosJson,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

List<PlanRatio> _equalRatios(
  String planId,
  String lineId,
  List<String> participantIds,
) {
  final weight = 10000 ~/ participantIds.length;
  var remainder = 10000 - (weight * participantIds.length);
  return [
    for (var i = 0; i < participantIds.length; i++)
      PlanRatio(
        id: '$lineId-${participantIds[i]}',
        planId: planId,
        lineId: lineId,
        participantId: participantIds[i],
        weight: weight + (remainder-- > 0 ? 1 : 0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
  ];
}

Map<String, int> _edgeAmounts(List<PairwiseBalanceEntry> edges) {
  return {
    for (final edge in edges)
      '${edge.fromParticipantId}->${edge.toParticipantId}': edge.amountMinor,
  };
}
