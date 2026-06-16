import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/screens/contacts/contact_invitation_list_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sortSentInvitationsForList keeps pending and expired, newest first', () {
    final older = DateTime.utc(2026, 5, 23, 18, 1);
    final newer = DateTime.utc(2026, 5, 23, 18, 18);
    final pending = ContactInvitation(
      id: 'aaa',
      nonce: '00',
      status: 'pending',
      createdAt: older,
      expiresAt: newer,
    );
    final expired = ContactInvitation(
      id: 'bbb',
      nonce: '00',
      status: 'expired',
      createdAt: newer,
      expiresAt: newer,
    );
    final used = ContactInvitation(
      id: 'ccc',
      nonce: '00',
      status: 'used',
      createdAt: newer,
      expiresAt: newer,
    );

    final sorted = sortSentInvitationsForList([pending, used, expired]);

    expect(sorted.map((r) => r.id).toList(), [expired.id, pending.id]);
  });
}
