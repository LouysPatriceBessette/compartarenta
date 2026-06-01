import 'package:compartarenta/housing/amendment/housing_rules_amendment_pending.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyToPayload patches agreement without touching live tables', () {
    const planId = 'p1';
    HousingRulesAmendmentPendingStore.set(
      planId,
      const HousingRulesAmendmentPending(
        agreementRulesJson: '{"v":1,"earlyWithdrawalEnabled":false}',
        clauses: 'x',
        minNoticeDays: 0,
        penaltyMinor: 0,
        withdrawalSameForAll: 'true',
        withdrawalPerParticipantJson: '{}',
      ),
    );

    final payload = <String, dynamic>{
      'agreement': {
        'agreementRulesJson': '{"v":1,"earlyWithdrawalEnabled":true}',
        'clauses': 'old',
        'minNoticeDays': 30,
        'penalty': {'amountMinor': 100},
      },
    };

    HousingRulesAmendmentPendingStore.applyToPayload(planId, payload);

    final agr = payload['agreement'] as Map<String, dynamic>;
    expect(agr['agreementRulesJson'], contains('false'));
    expect(agr['clauses'], 'x');
    expect(agr['minNoticeDays'], 0);
    expect((agr['penalty'] as Map)['amountMinor'], 0);

    HousingRulesAmendmentPendingStore.clear(planId);
  });
}
