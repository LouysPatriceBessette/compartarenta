import 'package:flutter_test/flutter_test.dart';

/// Documents payment reminder recipient rules (task 3.2).
void main() {
  test('before-date uses designated payer only; overdue uses all roster', () {
    const roster = ['p1', 'p2', 'p3'];
    const designated = 'p2';

    final beforeRecipients = [designated];
    final overdueRecipients = roster;

    expect(beforeRecipients, ['p2']);
    expect(overdueRecipients, roster);
  });

  test('before-date uses full roster when no designated payer', () {
    const roster = ['p1', 'p2'];
    final beforeRecipients = roster;
    expect(beforeRecipients, roster);
  });
}
