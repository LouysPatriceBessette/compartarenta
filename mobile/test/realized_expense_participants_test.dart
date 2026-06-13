import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_participants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sortParticipantsByDisplayName orders actives A to Z', () {
    final sorted = sortParticipantsByDisplayName([
      Participant(
        id: 'plan:self',
        displayName: 'Monica',
        avatarId: 'a01',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      Participant(
        id: 'plan:p1',
        displayName: 'Louys',
        avatarId: 'a02',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ]);

    expect(sorted.map((p) => p.displayName).toList(), ['Louys', 'Monica']);
  });

  test('compareParticipantDisplayNames is case-insensitive', () {
    expect(compareParticipantDisplayNames('bravo', 'Alpha'), greaterThan(0));
    expect(compareParticipantDisplayNames('Alpha', 'bravo'), lessThan(0));
  });
}
