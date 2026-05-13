import 'dart:typed_data';

import 'package:compartarenta/relay/envelopes.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvelopeCodec hello', () {
    final invitationId = Uint8List.fromList(List<int>.generate(8, (i) => i));
    final invitationNonce =
        Uint8List.fromList(List<int>.generate(12, (i) => 0x10 + i));

    setUp(() {
      // Use a fixed nonce in tests so failures point at logic, not RNG.
      setNonceSourceForTesting(
        () => Uint8List.fromList(List<int>.generate(12, (i) => 0xC0 + i)),
      );
    });
    tearDown(resetNonceSourceForTesting);

    test('round-trips display name and avatar id through inviter', () async {
      final inviteeKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );
      final inviteePriv = await inviteeKeystore.loadOrCreatePrivateKey();
      final inviteePub = await inviteeKeystore.publicKey();

      final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
        invitationId: invitationId,
        nonce: invitationNonce,
      );
      final inviterHandshakePub =
          await RelayRouting.handshakePublicKey(inviterHandshakePriv);

      final frame = await EnvelopeCodec.encryptHello(
        envelope: HelloEnvelope(
          invitationId: invitationId,
          inviteeLongTermPublicKey: inviteePub,
          displayName: 'Alice',
          avatarId: 'cat',
          echoedNonce: invitationNonce,
        ),
        invitationNonce: invitationNonce,
        inviteeLongTermPrivateKey: inviteePriv,
        inviterHandshakePublicKey: inviterHandshakePub,
      );

      // Header is observable.
      final header = EnvelopeCodec.peekHelloHeader(frame);
      expect(header.invitationId, equals(invitationId));
      expect(header.inviteeLongTermPublicKey, equals(inviteePub));

      // Inviter decrypts using the locally stored nonce.
      final decoded = await EnvelopeCodec.decryptHello(
        frame: frame,
        invitationNonce: invitationNonce,
        inviterHandshakePrivateKey: inviterHandshakePriv,
      );
      expect(decoded.displayName, 'Alice');
      expect(decoded.avatarId, 'cat');
      expect(decoded.echoedNonce, equals(invitationNonce));
      expect(decoded.inviteeLongTermPublicKey, equals(inviteePub));
    });

    test('decrypt rejects wrong nonce (per nonce-mixed-into-salt rule)',
        () async {
      final inviteeKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );
      final inviteePriv = await inviteeKeystore.loadOrCreatePrivateKey();
      final inviteePub = await inviteeKeystore.publicKey();

      final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
        invitationId: invitationId,
        nonce: invitationNonce,
      );
      final inviterHandshakePub =
          await RelayRouting.handshakePublicKey(inviterHandshakePriv);

      final frame = await EnvelopeCodec.encryptHello(
        envelope: HelloEnvelope(
          invitationId: invitationId,
          inviteeLongTermPublicKey: inviteePub,
          displayName: 'Alice',
          avatarId: 'cat',
          echoedNonce: invitationNonce,
        ),
        invitationNonce: invitationNonce,
        inviteeLongTermPrivateKey: inviteePriv,
        inviterHandshakePublicKey: inviterHandshakePub,
      );

      final wrongNonce = Uint8List.fromList(
        List<int>.generate(12, (i) => i + 1),
      );

      expect(
        () => EnvelopeCodec.decryptHello(
          frame: frame,
          invitationNonce: wrongNonce,
          inviterHandshakePrivateKey: inviterHandshakePriv,
        ),
        throwsA(isA<EnvelopeDecryptionError>()),
      );
    });

    test('rejects wrong framing version / kind', () async {
      final frame = Uint8List.fromList([0x02, 0x01, ...List<int>.filled(80, 0)]);
      expect(
        () => EnvelopeCodec.peekHelloHeader(frame),
        throwsA(isA<EnvelopeDecryptionError>()),
      );
    });
  });

  group('EnvelopeCodec ack', () {
    final invitationId = Uint8List.fromList(List<int>.generate(8, (i) => i));
    final invitationNonce =
        Uint8List.fromList(List<int>.generate(12, (i) => 0x10 + i));

    setUp(() => setNonceSourceForTesting(
          () => Uint8List.fromList(List<int>.generate(12, (i) => 0x33 + i)),
        ));
    tearDown(resetNonceSourceForTesting);

    test('round-trips accepted ack with inviter profile', () async {
      final inviterKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => 0x80 + i)),
      );
      final inviteeKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );

      final inviterPub = await inviterKeystore.publicKey();
      final inviteePriv = await inviteeKeystore.loadOrCreatePrivateKey();
      final inviteePub = await inviteeKeystore.publicKey();

      final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
        invitationId: invitationId,
        nonce: invitationNonce,
      );

      final frame = await EnvelopeCodec.encryptAck(
        envelope: AckEnvelope(
          invitationId: invitationId,
          inviterLongTermPublicKey: inviterPub,
          accepted: true,
          displayName: 'Bob',
          avatarId: 'dog',
        ),
        invitationNonce: invitationNonce,
        inviterHandshakePrivateKey: inviterHandshakePriv,
        inviteeLongTermPublicKey: inviteePub,
      );

      final decoded = await EnvelopeCodec.decryptAck(
        frame: frame,
        invitationId: invitationId,
        invitationNonce: invitationNonce,
        inviteeLongTermPrivateKey: inviteePriv,
      );
      expect(decoded.accepted, isTrue);
      expect(decoded.displayName, 'Bob');
      expect(decoded.avatarId, 'dog');
      expect(decoded.inviterLongTermPublicKey, equals(inviterPub));
    });

    test('round-trips rejected ack without leaking profile fields', () async {
      final inviterKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => 0x80 + i)),
      );
      final inviteeKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );

      final inviterPub = await inviterKeystore.publicKey();
      final inviteePriv = await inviteeKeystore.loadOrCreatePrivateKey();
      final inviteePub = await inviteeKeystore.publicKey();

      final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
        invitationId: invitationId,
        nonce: invitationNonce,
      );

      final frame = await EnvelopeCodec.encryptAck(
        envelope: AckEnvelope(
          invitationId: invitationId,
          inviterLongTermPublicKey: inviterPub,
          accepted: false,
        ),
        invitationNonce: invitationNonce,
        inviterHandshakePrivateKey: inviterHandshakePriv,
        inviteeLongTermPublicKey: inviteePub,
      );

      final decoded = await EnvelopeCodec.decryptAck(
        frame: frame,
        invitationId: invitationId,
        invitationNonce: invitationNonce,
        inviteeLongTermPrivateKey: inviteePriv,
      );
      expect(decoded.accepted, isFalse);
      expect(decoded.displayName, isEmpty);
      expect(decoded.avatarId, isEmpty);
    });
  });

  group('EnvelopeCodec steady-state', () {
    setUp(() => setNonceSourceForTesting(
          () => Uint8List.fromList(List<int>.generate(12, (i) => 0x55 + i)),
        ));
    tearDown(resetNonceSourceForTesting);

    test('profile_update round-trips between two connected contacts',
        () async {
      final aliceKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );
      final bobKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => 0x40 + i)),
      );
      final alicePriv = await aliceKeystore.loadOrCreatePrivateKey();
      final alicePub = await aliceKeystore.publicKey();
      final bobPriv = await bobKeystore.loadOrCreatePrivateKey();
      final bobPub = await bobKeystore.publicKey();

      final frame = await EnvelopeCodec.encryptProfileUpdate(
        envelope: ProfileUpdateEnvelope(
          senderLongTermPublicKey: alicePub,
          displayName: 'Alice (renamed)',
          avatarId: 'bird',
        ),
        senderLongTermPrivateKey: alicePriv,
        peerLongTermPublicKey: bobPub,
      );
      final decoded = await EnvelopeCodec.decryptProfileUpdate(
        frame: frame,
        receiverLongTermPrivateKey: bobPriv,
      );
      expect(decoded.displayName, 'Alice (renamed)');
      expect(decoded.avatarId, 'bird');
      expect(decoded.senderLongTermPublicKey, equals(alicePub));
    });

    test('disconnect round-trips an empty payload', () async {
      final aliceKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      );
      final bobKeystore = InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => 0x40 + i)),
      );
      final alicePriv = await aliceKeystore.loadOrCreatePrivateKey();
      final alicePub = await aliceKeystore.publicKey();
      final bobPriv = await bobKeystore.loadOrCreatePrivateKey();
      final bobPub = await bobKeystore.publicKey();

      final frame = await EnvelopeCodec.encryptDisconnect(
        envelope: DisconnectEnvelope(senderLongTermPublicKey: alicePub),
        senderLongTermPrivateKey: alicePriv,
        peerLongTermPublicKey: bobPub,
      );
      final decoded = await EnvelopeCodec.decryptDisconnect(
        frame: frame,
        receiverLongTermPrivateKey: bobPriv,
      );
      expect(decoded.senderLongTermPublicKey, equals(alicePub));
    });
  });
}
