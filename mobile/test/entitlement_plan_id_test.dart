import 'package:compartarenta/entitlement/entitlement_plan_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entitlementPlanIdForLocalPlan', () {
    test('author local id maps to bare uuid', () {
      const uuid = '55555555-5555-4555-8555-555555555555';
      expect(
        entitlementPlanIdForLocalPlan('housing:$uuid'),
        uuid,
      );
    });

    test('received local id maps to same bare uuid', () {
      const uuid = '55555555-5555-4555-8555-555555555555';
      expect(
        entitlementPlanIdForLocalPlan('received:$uuid'),
        uuid,
      );
    });

    test('bare uuid passes through', () {
      const uuid = '55555555-5555-4555-8555-555555555555';
      expect(entitlementPlanIdForLocalPlan(uuid), uuid);
    });

    test('non-uuid local id passes through unchanged', () {
      expect(entitlementPlanIdForLocalPlan('housing:default'), 'housing:default');
    });
  });
}
