import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/screens/contacts/contacts_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sortContactsForMainList excludes invitation stubs and sorts connected first', () {
    final older = DateTime.utc(2026, 5, 23, 18, 1);
    final newer = DateTime.utc(2026, 5, 23, 18, 18);
    final stub = Contact(
      id: 'contact:handshake:aaa',
      kind: 'local-only',
      displayName: 'Stub',
      avatarId: 'a01',
      notes: '',
      createdAt: older,
      updatedAt: older,
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
    final local = Contact(
      id: 'contact:local:bob',
      kind: 'local-only',
      displayName: 'Bob',
      avatarId: 'a01',
      notes: '',
      createdAt: newer,
      updatedAt: newer,
      isBlocked: false,
    );

    final sorted = sortContactsForMainList([anna, stub, zed, local]);

    expect(sorted.map((c) => c.id).toList(), [
      anna.id,
      zed.id,
      local.id,
    ]);
  });
}
