import 'package:compartarenta/housing/participation/housing_inactive_settlement_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HousingInactiveSettlementTransfer.validateAmount', () {
    test('rejects zero amount', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: 0,
          inactiveNetBalanceMinor: -500,
        ),
        'zero_amount',
      );
    });

    test('rejects positive amount when inactive has no debt', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: 100,
          inactiveNetBalanceMinor: 0,
        ),
        'cannot_create_credit_for_inactive',
      );
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: 100,
          inactiveNetBalanceMinor: 200,
        ),
        'cannot_create_credit_for_inactive',
      );
    });

    test('rejects positive amount exceeding inactive debt', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: 600,
          inactiveNetBalanceMinor: -500,
        ),
        'exceeds_inactive_debt',
      );
    });

    test('accepts positive amount up to inactive debt', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: 500,
          inactiveNetBalanceMinor: -500,
        ),
        isNull,
      );
    });

    test('rejects negative amount when inactive has no credit', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: -100,
          inactiveNetBalanceMinor: 0,
        ),
        'cannot_increase_inactive_debt',
      );
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: -100,
          inactiveNetBalanceMinor: -200,
        ),
        'cannot_increase_inactive_debt',
      );
    });

    test('rejects negative amount exceeding inactive credit', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: -600,
          inactiveNetBalanceMinor: 500,
        ),
        'exceeds_inactive_credit',
      );
    });

    test('accepts negative amount up to inactive credit', () {
      expect(
        HousingInactiveSettlementTransfer.validateAmount(
          amountMinor: -500,
          inactiveNetBalanceMinor: 500,
        ),
        isNull,
      );
    });
  });
}
