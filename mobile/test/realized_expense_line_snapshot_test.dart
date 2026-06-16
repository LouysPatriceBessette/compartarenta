import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_balance.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_line_snapshot.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePlanRatiosToLocalRoster', () {
    const localPlanId = 'received:pkg:abc';
    const foreignPlanId = 'received:pkg:xyz';
    const lineId = '$localPlanId:line:rent';

    final roster = [
      Participant(
        id: '$localPlanId:self',
        displayName: 'Monica',
        avatarId: '0',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      Participant(
        id: '$localPlanId:p0',
        displayName: 'Louys',
        avatarId: '1',
        contactId: 'contact:louys',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    test('remaps peer split ratios to the local roster', () {
      final foreignJson =
          '[{"participantId":"$foreignPlanId:self","weight":5000},'
          '{"participantId":"$foreignPlanId:p0","weight":5000}]';

      final normalized = normalizePlanRatiosToLocalRoster(
        planId: localPlanId,
        lineId: lineId,
        ratios: planRatiosFromSplitJson(
          splitRatiosJson: foreignJson,
          planId: localPlanId,
          lineId: lineId,
        ),
        roster: roster,
        sourceToLocal: {
          '$foreignPlanId:self': '$localPlanId:self',
          '$foreignPlanId:p0': '$localPlanId:p0',
        },
      );

      expect(normalized, hasLength(2));
      expect(
        normalized.map((ratio) => ratio.participantId).toSet(),
        {
          '$localPlanId:self',
          '$localPlanId:p0',
        },
      );
    });

    test('feeds balance calculation after remapping foreign split ratios', () {
      const amountMinor = 1800;
      final expense = RealizedExpense(
        id: 'realized:1',
        packageId: 'pkg',
        planId: localPlanId,
        planLineId: lineId,
        status: RealizedExpenseStatus.published,
        amountMinor: amountMinor,
        paymentChartCarryForwardMinor: 0,
        currency: 'CAD',
        paymentDate: DateTime.utc(2026, 5, 30),
        payerParticipantId: '$localPlanId:p0',
        kind: RealizedExpenseKind.normal,
        beneficiaryParticipantId: null,
        priorExpenseId: null,
        planLineTitleSnapshot: 'Loyer',
        splitRatiosJson:
            '[{"participantId":"$foreignPlanId:self","weight":5000},'
            '{"participantId":"$foreignPlanId:p0","weight":5000}]',
        createdAt: DateTime.utc(2026, 5, 30),
        updatedAt: DateTime.utc(2026, 5, 30),
      );

      final normalized = normalizePlanRatiosToLocalRoster(
        planId: localPlanId,
        lineId: lineId,
        ratios: planRatiosFromSplitJson(
          splitRatiosJson: expense.splitRatiosJson,
          planId: localPlanId,
          lineId: lineId,
        ),
        roster: roster,
        sourceToLocal: {
          '$foreignPlanId:self': '$localPlanId:self',
          '$foreignPlanId:p0': '$localPlanId:p0',
        },
      );

      final data = computeHousingBalanceData(
        publishedExpenses: [expense],
        planRatios: const [],
        participants: [
          HousingBalanceParticipant(
            participantId: '$localPlanId:self',
            displayName: 'Monica',
            letter: 'A',
            orderIndex: 0,
          ),
          HousingBalanceParticipant(
            participantId: '$localPlanId:p0',
            displayName: 'Louys',
            letter: 'B',
            orderIndex: 1,
          ),
        ],
        ratiosByExpenseId: {expense.id: normalized},
      );

      expect(data.realMode.edges, hasLength(1));
      expect(data.realMode.edges.single.fromParticipantId, '$localPlanId:self');
      expect(data.realMode.edges.single.toParticipantId, '$localPlanId:p0');
      expect(data.realMode.edges.single.amountMinor, amountMinor ~/ 2);
    });
  });
}
