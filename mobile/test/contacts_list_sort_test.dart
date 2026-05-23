import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/screens/contacts/contacts_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sortContactsForMainList orders invitations then connected', () {
    final older = DateTime.utc(2026, 5, 23, 18, 1);
    final newer = DateTime.utc(2026, 5, 23, 18, 18);
    final stubOld = Contact(
      id: 'contact:handshake:aaa',
      kind: 'local-only',
      displayName: 'Old stub',
      avatarId: 'a01',
      notes: '',
      createdAt: older,
      updatedAt: older,
      isBlocked: false,
    );
    final stubNew = Contact(
      id: 'contact:handshake:bbb',
      kind: 'local-only',
      displayName: 'New stub',
      avatarId: 'a01',
      notes: '',
      createdAt: newer,
      updatedAt: newer,
      isBlocked: false,
    );
    final zed = Contact(
      id: 'contact:connected:zed',
      kind: 'connected',
      displayName: 'Zed',
      avatarId: 'a01',
      notes: '',
      createdAt: older,
      updatedAt: older,
      isBlocked: false,
      relayRoutingId: 'r',
      peerPublicMaterial: 'p',
    );
    final anna = Contact(
      id: 'contact:connected:anna',
      kind: 'connected',
      displayName: 'Anna',
      avatarId: 'a01',
      notes: '',
      createdAt: newer,
      updatedAt: newer,
      isBlocked: false,
      relayRoutingId: 'r',
      peerPublicMaterial: 'p',
    );
    final invitations = {
      stubOld.id: ContactInvitation(
        id: 'aaa',
        nonce: '00',
        status: 'pending',
        createdAt: older,
        expiresAt: newer,
        contactStubId: stubOld.id,
      ),
      stubNew.id: ContactInvitation(
        id: 'bbb',
        nonce: '00',
        status: 'pending',
        createdAt: newer,
        expiresAt: newer.add(const Duration(hours: 1)),
        contactStubId: stubNew.id,
      ),
    };

    final sorted = sortContactsForMainList(
      [anna, stubOld, zed, stubNew],
      invitations,
    );

    expect(sorted.map((c) => c.id).toList(), [
      stubNew.id,
      stubOld.id,
      anna.id,
      zed.id,
    ]);
  });
}
