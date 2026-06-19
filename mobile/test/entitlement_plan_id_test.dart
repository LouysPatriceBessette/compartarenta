import 'package:compartarenta/entitlement/entitlement_plan_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entitlementPlanIdForLocalPlan', () {
    test('author uuid plan id is used as-is', () {
      const authorId = 'housing:55555555-5555-4555-8555-555555555555';
      expect(entitlementPlanIdForLocalPlan(authorId), authorId);
    });

    test('received uuid maps to author plan id', () {
      expect(
        entitlementPlanIdForLocalPlan(
          'received:55555555-5555-4555-8555-555555555555',
        ),
        'housing:55555555-5555-4555-8555-555555555555',
      );
    });

    test('legacy housing:default keeps derived token', () {
      expect(
        entitlementPlanIdForLocalPlan('housing:default'),
        'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA',
      );
    });

    test('leaves legacy received token unchanged', () {
      const received = 'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA';
      expect(entitlementPlanIdForLocalPlan(received), received);
    });
  });
}
