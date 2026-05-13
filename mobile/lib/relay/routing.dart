import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

/// Pure deterministic derivations used by the Contacts handshake and the
/// steady-state routing identifiers shipped with `contacts-domain-model`
/// and `contact-handshake-over-relay`.
///
/// Every output here is a function of public values only (invitation id +
/// nonce for the handshake, peer + self long-term X25519 public keys for
/// the steady state). Anything that requires a private key is in
/// `envelopes.dart` and the per-side keystore.
///
/// Conventions:
/// * Handshake addresses are 16 bytes; they are used as `self_identity` /
///   `recipient_identity` / `sender_identity` on the relay's HTTP API.
///   The relay rejects identities outside `[8, 64]` bytes, so 16 is well
///   in-range.
/// * `relayRoutingId` for a connected contact, stored on the local device
///   in `Contacts.relayRoutingId`, follows the convention from the design
///   doc: `HKDF(peer_pub || self_pub, info="compartarenta/relay-routing/v1")`
///   truncated to 16 bytes. That value is the **peer's listen address**
///   from the local POV: the address to which envelopes addressed to the
///   peer are sent. Symmetrically each device computes its OWN listen
///   address as `HKDF(self_pub || peer_pub, ...)` and registers that with
///   the relay via `/v1/handshake/establish`.
class RelayRouting {
  RelayRouting._();

  static const int handshakeAddressBytes = 16;
  static const int steadyStateAddressBytes = 16;
  static const int handshakePrivateKeyBytes = 32;

  static const String _handshakePrivInfo =
      'compartarenta/handshake-v1/handshake-priv';
  static const String _addrInviterInfo =
      'compartarenta/handshake-v1/inviter-listen-addr';
  static const String _addrInviteeInfo =
      'compartarenta/handshake-v1/invitee-listen-addr';
  static const String _steadyStateInfo =
      'compartarenta/relay-routing/v1';

  /// Concatenates `invitationId || nonce` for use as HKDF salt.
  static Uint8List _invitationSalt(Uint8List invitationId, Uint8List nonce) {
    final out = Uint8List(invitationId.length + nonce.length);
    out.setRange(0, invitationId.length, invitationId);
    out.setRange(invitationId.length, out.length, nonce);
    return out;
  }

  /// Derives the inviter's one-time handshake X25519 private key from the
  /// invitation code's `invitationId || nonce`. The corresponding public key
  /// can be obtained by passing the derived private bytes into the X25519
  /// algorithm; see [handshakePublicKey].
  ///
  /// Both inviter and invitee compute this same value from the code, which
  /// is exactly what enables the invitee to encrypt `hello` and the inviter
  /// to decrypt it without any prior network round trip. Code-sharing is
  /// the security boundary: anyone who has the code can derive this seed.
  /// This matches the design's "share with one person only" stance and the
  /// nonce-consumption rule that prevents replay.
  static Future<Uint8List> handshakePrivateKey({
    required Uint8List invitationId,
    required Uint8List nonce,
  }) async {
    return _hkdf(
      ikm: _invitationSalt(invitationId, nonce),
      info: _handshakePrivInfo,
      salt: const <int>[],
      length: handshakePrivateKeyBytes,
    );
  }

  /// Derives the inviter's listen address (where the invitee posts `hello`
  /// and the invitee polls for the `ack` once it arrives back).
  static Future<Uint8List> inviterHandshakeAddress({
    required Uint8List invitationId,
    required Uint8List nonce,
  }) async {
    return _hkdf(
      ikm: _invitationSalt(invitationId, nonce),
      info: _addrInviterInfo,
      salt: const <int>[],
      length: handshakeAddressBytes,
    );
  }

  /// Derives the invitee's listen address (the `sender_identity` they use
  /// when posting `hello`, and the address they poll for the inviter's
  /// `ack`).
  static Future<Uint8List> inviteeHandshakeAddress({
    required Uint8List invitationId,
    required Uint8List nonce,
  }) async {
    return _hkdf(
      ikm: _invitationSalt(invitationId, nonce),
      info: _addrInviteeInfo,
      salt: const <int>[],
      length: handshakeAddressBytes,
    );
  }

  /// Steady-state routing address. The convention stored locally is:
  ///   `Contacts.relayRoutingId` (on Alice's device for Bob's row)
  ///   = HKDF(bob_pub || alice_pub, info="compartarenta/relay-routing/v1")
  /// That value is the **peer's listen address from the local POV**.
  ///
  /// Each device computes its OWN listen address by flipping the inputs
  /// (`self_pub || peer_pub`) — same formula, swapped order.
  static Future<Uint8List> steadyStateAddress({
    required Uint8List firstPub,
    required Uint8List secondPub,
  }) async {
    final ikm = Uint8List(firstPub.length + secondPub.length);
    ikm.setRange(0, firstPub.length, firstPub);
    ikm.setRange(firstPub.length, ikm.length, secondPub);
    return _hkdf(
      ikm: ikm,
      info: _steadyStateInfo,
      salt: const <int>[],
      length: steadyStateAddressBytes,
    );
  }

  /// Computes the X25519 public key corresponding to the supplied 32-byte
  /// scalar. The scalar is used as-is (the X25519 algorithm applies the
  /// usual bit-clamping internally).
  static Future<Uint8List> handshakePublicKey(Uint8List privateBytes) async {
    final algo = Cryptography.instance.x25519();
    final keyPair = await algo.newKeyPairFromSeed(privateBytes);
    final pk = await keyPair.extractPublicKey();
    return Uint8List.fromList(pk.bytes);
  }

  /// Convenience: base64url (no padding) used by the relay HTTP API.
  static String b64(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Convenience: decode base64url (no padding) used by the relay HTTP API.
  static Uint8List unb64(String value) {
    final padding = (4 - value.length % 4) % 4;
    return Uint8List.fromList(base64Url.decode(value + '=' * padding));
  }
}

/// Single-shot HKDF-SHA-256 used by every derivation in this file.
///
/// `cryptography_plus` implements the extract step as
/// `HMAC-SHA-256(key=salt, ikm)`, and HMAC rejects an empty key. Per
/// RFC 5869 §2.2 an empty salt is equivalent to `HashLen` zero bytes, so
/// we substitute that here when callers pass `[]`.
Future<Uint8List> _hkdf({
  required List<int> ikm,
  required String info,
  required List<int> salt,
  required int length,
}) async {
  final effectiveSalt = salt.isEmpty ? Uint8List(32) : salt;
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: length);
  final out = await hkdf.deriveKey(
    secretKey: SecretKey(ikm),
    nonce: effectiveSalt,
    info: utf8.encode(info),
  );
  final bytes = await out.extractBytes();
  return Uint8List.fromList(bytes);
}
