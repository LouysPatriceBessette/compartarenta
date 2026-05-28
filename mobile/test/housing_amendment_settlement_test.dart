import 'package:compartarenta/housing/amendment/housing_amendment_settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('archivedAmendmentWasAccepted treats activation archive as accepted', () {
    expect(
      archivedAmendmentWasAccepted({
        'lifecycleState': 'archived',
      }),
      isTrue,
    );
  });

  test('archivedAmendmentWasAccepted treats rejection as refused', () {
    expect(
      archivedAmendmentWasAccepted({
        'lifecycleState': 'archived',
        'invalidatedByStatus': 'rejected',
      }),
      isFalse,
    );
  });

  test('amendmentBaselineRevisionId prefers fork lineage', () {
    expect(
      amendmentBaselineRevisionId(
        revisionPayload: {'forkedFromRevisionId': 'rev:baseline'},
        revisionId: 'rev:new',
        packageActiveRevisionId: 'rev:new',
        isArchived: true,
      ),
      'rev:baseline',
    );
  });
}
