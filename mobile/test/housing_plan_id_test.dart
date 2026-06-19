import 'package:compartarenta/housing/housing_plan_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('newHousingPlanId', () {
    test('returns housing-prefixed uuid v4', () {
      final id = newHousingPlanId();
      expect(id.startsWith(kHousingPlanIdPrefix), isTrue);
      final uuid = id.substring(kHousingPlanIdPrefix.length);
      expect(looksLikeUuid(uuid), isTrue);
    });
  });

  group('entitlementPlanIdForLocalPlan', () {
    const authorId = 'housing:11111111-1111-4111-8111-111111111111';
    const peerId = 'received:11111111-1111-4111-8111-111111111111';

    test('uses author plan id as-is', () {
      expect(entitlementPlanIdForLocalPlan(authorId), authorId);
    });

    test('maps received uuid suffix to author plan id', () {
      expect(entitlementPlanIdForLocalPlan(peerId), authorId);
    });

    test('legacy housing:default keeps derived received token', () {
      expect(
        entitlementPlanIdForLocalPlan('housing:default'),
        'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA',
      );
    });
  });

  group('receivedPlanIdForAuthorPlan', () {
    test('uses uuid suffix without hashing', () {
      const authorId = 'housing:22222222-2222-4222-8222-222222222222';
      expect(
        receivedPlanIdForAuthorPlan(authorId),
        'received:22222222-2222-4222-8222-222222222222',
      );
    });

    test('legacy author id keeps token derivation', () {
      expect(
        receivedPlanIdForAuthorPlan('housing:default'),
        'received:cGtnOmhvdXNpbmc6ZGVmYXVsdA',
      );
    });
  });

  group('authorPlanIdFromProposalPayload', () {
    test('reads explicit entitlementPlanId', () {
      expect(
        authorPlanIdFromProposalPayload({
          'entitlementPlanId': 'housing:33333333-3333-4333-8333-333333333333',
        }),
        'housing:33333333-3333-4333-8333-333333333333',
      );
    });

    test('derives from participant ids', () {
      expect(
        authorPlanIdFromProposalPayload({
          'proposerParticipantId':
              'housing:44444444-4444-4444-8444-444444444444:self',
        }),
        'housing:44444444-4444-4444-8444-444444444444',
      );
    });
  });
}
