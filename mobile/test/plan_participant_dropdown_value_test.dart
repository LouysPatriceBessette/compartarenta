import 'package:compartarenta/housing/expense_form/plan_participant_dropdown_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const roster = ['housing:default:self', 'housing:default:p0'];

  test('resolvePlanParticipantDropdownValue returns null for empty stored id', () {
    expect(resolvePlanParticipantDropdownValue(null, roster), isNull);
    expect(resolvePlanParticipantDropdownValue('', roster), isNull);
  });

  test('resolvePlanParticipantDropdownValue matches full participant id', () {
    expect(
      resolvePlanParticipantDropdownValue('housing:default:self', roster),
      'housing:default:self',
    );
  });

  test('resolvePlanParticipantDropdownValue matches legacy tail id', () {
    expect(
      resolvePlanParticipantDropdownValue('self', roster),
      'housing:default:self',
    );
    expect(
      resolvePlanParticipantDropdownValue('p0', roster),
      'housing:default:p0',
    );
  });

  test('resolvePlanParticipantDropdownValue returns null when not in roster', () {
    expect(
      resolvePlanParticipantDropdownValue('housing:other:p0', roster),
      isNull,
    );
  });
}
