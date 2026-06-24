import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/settlement/housing_agreement_month_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HousingAgreementMonthWindow.fromAgreement', () {
    Agreement testAgreement({
      required DateTime start,
      required DateTime end,
    }) =>
        Agreement(
          id: 'a1',
          planId: 'plan',
          periodStart: start,
          periodEnd: end,
          minNoticeDays: 0,
          penaltyMinor: 0,
          clauses: '',
          withdrawalSameForAll: 'true',
          withdrawalPerParticipantJson: '{}',
          agreementRulesJson: '{}',
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
        );

    test('mid-month end does not extend without settlement', () {
      final window = HousingAgreementMonthWindow.fromAgreement(
        testAgreement(
          start: DateTime(2026, 5, 25),
          end: DateTime(2026, 10, 15),
        ),
      );
      expect(window.firstMonth, DateTime(2026, 5));
      expect(window.lastMonth, DateTime(2026, 10));
    });

    test('near end of month extends following month', () {
      final window = HousingAgreementMonthWindow.fromAgreement(
        testAgreement(
          start: DateTime(2026, 6, 3),
          end: DateTime(2026, 10, 28),
        ),
      );
      expect(window.firstMonth, DateTime(2026, 6));
      expect(window.lastMonth, DateTime(2026, 11));
    });

    test('settlement-open exposes settlement month beyond periodEnd month', () {
      final window = HousingAgreementMonthWindow.fromAgreement(
        testAgreement(
          start: DateTime(2026, 5, 25),
          end: DateTime(2026, 10, 15),
        ),
        settlementOpen: true,
      );
      expect(window.lastMonth, DateTime(2026, 11));
    });
  });
}
