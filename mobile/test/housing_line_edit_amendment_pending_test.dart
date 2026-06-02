import 'dart:convert';

import 'package:compartarenta/housing/amendment/housing_line_add_amendment_pending.dart';
import 'package:compartarenta/housing/amendment/housing_line_edit_amendment_pending.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyLineEditToRevisionPayload replaces line and ratios', () {
    final payload = jsonDecode('''
{
  "plan": {
    "lines": [
      {"id": "plan:line:rent", "title": "Renta", "amountMinor": 71500}
    ],
    "ratios": [
      {"participantId": "plan:self", "lineId": "plan:line:rent", "weight": 5000},
      {"participantId": "plan:p0", "lineId": "plan:line:rent", "weight": 5000}
    ]
  }
}
''') as Map<String, dynamic>;

    applyLineEditToRevisionPayload(
      payload: payload,
      planId: 'plan',
      lineId: 'plan:line:rent',
      lineMap: {
        'id': 'plan:line:rent',
        'title': 'Renta',
        'amountMinor': 72000,
        'currency': 'CAD',
        'isRecurring': false,
        'amountUsesRange': false,
        'amountIsBudgetCap': false,
        'cadence': 'monthly',
      },
      ratioMaps: [
        {
          'participantId': 'plan:self',
          'lineId': 'plan:line:rent',
          'weight': 7000,
        },
        {
          'participantId': 'plan:p0',
          'lineId': 'plan:line:rent',
          'weight': 3000,
        },
      ],
    );

    final plan = payload['plan'] as Map<String, dynamic>;
    final lines = plan['lines'] as List;
    expect(lines, hasLength(1));
    expect((lines.single as Map)['amountMinor'], 72000);

    final ratios = plan['ratios'] as List;
    expect(ratios, hasLength(2));
    expect(
      ratios.map((r) => (r as Map)['weight']).toList()..sort(),
      [3000, 7000],
    );
  });

  test('line add pending appends a new line to proposed payload', () {
    final payload = jsonDecode('''
{"plan": {"lines": [], "ratios": []}}
''') as Map<String, dynamic>;

    HousingLineAddAmendmentPendingStore.set(
      'plan',
      HousingLineEditAmendmentPending(
        lineId: 'line:new',
        lineMap: {
          'id': 'line:new',
          'title': 'Insurance',
          'amountMinor': 12000,
          'currency': 'CAD',
          'isRecurring': true,
          'amountUsesRange': false,
          'amountIsBudgetCap': false,
          'cadence': 'monthly',
        },
        ratioMaps: [
          {
            'participantId': 'plan:self',
            'lineId': 'line:new',
            'weight': 5000,
          },
        ],
      ),
    );
    HousingLineAddAmendmentPendingStore.applyToPayload('plan', payload);
    HousingLineAddAmendmentPendingStore.clear('plan');

    final plan = payload['plan'] as Map<String, dynamic>;
    final lines = plan['lines'] as List;
    expect(lines, hasLength(1));
    expect((lines.single as Map)['title'], 'Insurance');
  });
}
