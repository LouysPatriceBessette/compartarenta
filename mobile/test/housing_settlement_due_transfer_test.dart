import 'package:compartarenta/housing/realized_expense/realized_expense_balance.dart';
import 'package:compartarenta/housing/settlement/housing_settlement_due_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HousingSettlementDueTransfer', () {
    const edges = [
      PairwiseBalanceEntry(
        fromParticipantId: 'self',
        toParticipantId: 'p2',
        amountMinor: 5000,
      ),
    ];

    test('pairwiseNetFromSelf is negative when self owes other', () {
      expect(
        HousingSettlementDueTransfer.pairwiseNetFromSelf(
          edges: edges,
          selfId: 'self',
          otherId: 'p2',
        ),
        -5000,
      );
    });

    test('validateAmount accepts paying up to debt', () {
      expect(
        HousingSettlementDueTransfer.validateAmount(
          amountMinor: 5000,
          pairwiseNetFromSelfMinor: -5000,
        ),
        isNull,
      );
    });

    test('validateAmount rejects excess payment', () {
      expect(
        HousingSettlementDueTransfer.validateAmount(
          amountMinor: 6000,
          pairwiseNetFromSelfMinor: -5000,
        ),
        'exceeds_debt',
      );
    });

    test('validateAmount rejects payment when other owes self', () {
      expect(
        HousingSettlementDueTransfer.validateAmount(
          amountMinor: 1000,
          pairwiseNetFromSelfMinor: 2000,
        ),
        'cannot_create_credit',
      );
    });
  });
}
