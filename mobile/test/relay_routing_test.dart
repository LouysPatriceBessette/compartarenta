import 'dart:typed_data';

import 'package:compartarenta/relay/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelayRouting', () {
    final inviteId = Uint8List.fromList(List<int>.generate(8, (i) => i + 1));
    final nonce = Uint8List.fromList(List<int>.generate(12, (i) => 0xA0 + i));

    test('handshake addresses are 16 bytes and deterministic', () async {
      final addrInviter = await RelayRouting.inviterHandshakeAddress(
        invitationId: inviteId,
        nonce: nonce,
      );
      final addrInvitee = await RelayRouting.inviteeHandshakeAddress(
        invitationId: inviteId,
        nonce: nonce,
      );
      expect(addrInviter.length, RelayRouting.handshakeAddressBytes);
      expect(addrInvitee.length, RelayRouting.handshakeAddressBytes);
      expect(addrInviter, isNot(equals(addrInvitee)));

      final addrInviter2 = await RelayRouting.inviterHandshakeAddress(
        invitationId: inviteId,
        nonce: nonce,
      );
      expect(addrInviter2, equals(addrInviter));
    });

    test('handshake addresses depend on invitation id and nonce', () async {
      final addrA = await RelayRouting.inviterHandshakeAddress(
        invitationId: inviteId,
        nonce: nonce,
      );
      final otherNonce = Uint8List.fromList(List<int>.generate(12, (i) => i));
      final addrB = await RelayRouting.inviterHandshakeAddress(
        invitationId: inviteId,
        nonce: otherNonce,
      );
      expect(addrA, isNot(equals(addrB)));
    });

    test('handshake private key is 32 bytes and reproducible', () async {
      final seed1 = await RelayRouting.handshakePrivateKey(
        invitationId: inviteId,
        nonce: nonce,
      );
      final seed2 = await RelayRouting.handshakePrivateKey(
        invitationId: inviteId,
        nonce: nonce,
      );
      expect(seed1.length, RelayRouting.handshakePrivateKeyBytes);
      expect(seed1, equals(seed2));
    });

    test('handshake public key derives from the seed', () async {
      final seed = await RelayRouting.handshakePrivateKey(
        invitationId: inviteId,
        nonce: nonce,
      );
      final pub = await RelayRouting.handshakePublicKey(seed);
      expect(pub.length, 32);
    });

    test(
        'steady-state address is symmetric in the sense that flipping inputs '
        'yields a different value (peer vs self listen address)', () async {
      final alicePub = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final bobPub = Uint8List.fromList(List<int>.generate(32, (i) => 100 + i));

      // Alice's row for Bob -> peer || self with peer=Bob, self=Alice.
      final aliceRowForBob = await RelayRouting.steadyStateAddress(
        firstPub: bobPub,
        secondPub: alicePub,
      );
      // Bob's listen address that he registers with the relay -> self || peer
      // with self=Bob, peer=Alice -> bob || alice -> same bytes.
      final bobOwnListen = await RelayRouting.steadyStateAddress(
        firstPub: bobPub,
        secondPub: alicePub,
      );
      expect(aliceRowForBob, equals(bobOwnListen));

      // The reciprocal pairing is necessarily different.
      final bobRowForAlice = await RelayRouting.steadyStateAddress(
        firstPub: alicePub,
        secondPub: bobPub,
      );
      expect(bobRowForAlice, isNot(equals(aliceRowForBob)));
    });

    test('b64 / unb64 are inverses', () {
      final source = Uint8List.fromList(List<int>.generate(16, (i) => i * 17));
      final encoded = RelayRouting.b64(source);
      expect(encoded.contains('='), isFalse);
      final decoded = RelayRouting.unb64(encoded);
      expect(decoded, equals(source));
    });
  });
}
