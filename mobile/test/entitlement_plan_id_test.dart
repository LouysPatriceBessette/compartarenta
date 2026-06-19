import 'package:compartarenta/entitlement/entitlement_plan_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entitlementPlanIdForLocalPlan', () {
    test('maps author plan id to received token from pkg id', () {
      expect(
        entitlementPlanIdForLocalPlan('housing:default'),
        'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA',
      );
    });

    test('leaves received plan ids unchanged', () {
      const received = 'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA';
      expect(entitlementPlanIdForLocalPlan(received), received);
    });
  });
}
