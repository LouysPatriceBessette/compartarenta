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
    const uuid = '11111111-1111-4111-8111-111111111111';
    const authorId = 'housing:$uuid';
    const peerId = 'received:$uuid';

    test('strips housing prefix to bare uuid', () {
      expect(entitlementPlanIdForLocalPlan(authorId), uuid);
    });

    test('strips received prefix to bare uuid', () {
      expect(entitlementPlanIdForLocalPlan(peerId), uuid);
    });
  });

  group('receivedPlanIdForAuthorPlan', () {
    test('uses uuid suffix without hashing', () {
      const uuid = '22222222-2222-4222-8222-222222222222';
      expect(
        receivedPlanIdForAuthorPlan('housing:$uuid'),
        'received:$uuid',
      );
    });

    test('accepts bare uuid author id', () {
      const uuid = '22222222-2222-4222-8222-222222222222';
      expect(
        receivedPlanIdForAuthorPlan(uuid),
        'received:$uuid',
      );
    });
  });

  group('authorPlanIdFromProposalPayload', () {
    test('reads bare entitlementPlanId as local author row id', () {
      const uuid = '33333333-3333-4333-8333-333333333333';
      expect(
        authorPlanIdFromProposalPayload({
          'entitlementPlanId': uuid,
        }),
        'housing:$uuid',
      );
    });

    test('derives from participant ids', () {
      const uuid = '44444444-4444-4444-8444-444444444444';
      expect(
        authorPlanIdFromProposalPayload({
          'proposerParticipantId': 'housing:$uuid:self',
        }),
        'housing:$uuid',
      );
    });
  });
}
