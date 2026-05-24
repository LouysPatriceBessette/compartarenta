import 'package:compartarenta/housing/amendment/housing_amendment_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveAmendmentType reads explicit wire value', () {
    expect(
      resolveAmendmentType(
        pendingPayload: {'amendmentType': 'agreement_end'},
        activeRevisionId: 'rev:active',
        pendingRevisionId: 'rev:pending',
      ),
      HousingAmendmentType.agreementEnd,
    );
  });

  test('resolveAmendmentType infers forked in-force amendment', () {
    expect(
      resolveAmendmentType(
        pendingPayload: {
          'forkedFromRevisionId': 'rev:active',
          'amendmentTargetLineId': 'line-1',
        },
        activeRevisionId: 'rev:active',
        pendingRevisionId: 'rev:pending',
      ),
      HousingAmendmentType.lineAmount,
    );
  });

  test('resolveAmendmentType rejects initial proposal pending pointer', () {
    expect(
      resolveAmendmentType(
        pendingPayload: const {},
        activeRevisionId: 'rev:active',
        pendingRevisionId: 'rev:active',
      ),
      isNull,
    );
  });
}
