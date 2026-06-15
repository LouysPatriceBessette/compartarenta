import 'package:compartarenta/contacts/contact_module_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('agreementVoteExpiryApplies', () {
    test('applies from local midnight after period end', () {
      final periodEnd = DateTime.utc(2026, 6, 14, 12);
      final before = DateTime(2026, 6, 14, 23, 59);
      final atExpiry = DateTime(2026, 6, 15, 0, 0);
      expect(
        agreementVoteExpiryApplies(periodEnd: periodEnd, now: before),
        isFalse,
      );
      expect(
        agreementVoteExpiryApplies(periodEnd: periodEnd, now: atExpiry),
        isTrue,
      );
    });
  });

  group('agreementVoteExpiryStartsAtLocal', () {
    test('is start of day after inclusive end', () {
      final start = agreementVoteExpiryStartsAtLocal(
        DateTime.utc(2026, 3, 31, 18),
      );
      expect(start, DateTime(2026, 4, 1));
    });
  });
}
