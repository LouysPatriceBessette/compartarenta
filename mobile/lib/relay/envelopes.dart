import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

import 'routing.dart';

/// Envelope kinds, encoded as the `kind` byte on the wire of the relay.
///
/// The relay only sees the integer value; the framing and AEAD live in
/// the `ciphertext` payload below.
class EnvelopeKind {
  static const int hello = 1;
  static const int ack = 2;
  static const int profileUpdate = 3;
  static const int disconnect = 4;
  static const int housingProposal = 5;
}

/// One byte at the start of every envelope frame so we can evolve the
/// layout without breaking older clients. Bumped only when the header or
/// AEAD framing changes in a way old clients cannot ignore.
const int _framingVersion = 1;

/// Hello envelope: invitee -> inviter, encrypted to the inviter's
/// derived handshake public key.
///
/// On the wire (inside the relay `ciphertext` field):
/// `[ framing_version | kind=1 | inv_id(8) | invitee_long_term_pub(32) |
///    aead_nonce(12) | aead_ciphertext_with_tag ]`
///
/// The AEAD plaintext is a JSON object:
/// `{ "display_name": "...", "avatar_id": "...", "echo_nonce_b64": "..." }`
///
/// The AEAD associated data is the entire header (everything before the
/// AEAD output), so the relay's view of the addresses cannot be silently
/// swapped without making decryption fail.
class HelloEnvelope {
  HelloEnvelope({
    required this.invitationId,
    required this.inviteeLongTermPublicKey,
    required this.displayName,
    required this.avatarId,
    required this.echoedNonce,
  });

  final Uint8List invitationId;
  final Uint8List inviteeLongTermPublicKey;
  final String displayName;
  final String avatarId;

  /// Copy of the invitation nonce as received in the code. The inviter's
  /// device cross-checks this against its locally stored nonce before
  /// accepting the envelope.
  final Uint8List echoedNonce;
}

/// Ack envelope: inviter -> invitee, encrypted under the same shared
/// secret as the hello (different HKDF `info` string => different key).
///
/// On the wire:
/// `[ framing_version | kind=2 | inv_id(8) | inviter_long_term_pub(32) |
///    aead_nonce(12) | aead_ciphertext_with_tag ]`
///
/// The AEAD plaintext is a JSON object:
/// `{ "decision": "accepted"|"rejected",
///    "display_name": "...",     # omitted when decision=rejected
///    "avatar_id": "..." }`
class AckEnvelope {
  AckEnvelope({
    required this.invitationId,
    required this.inviterLongTermPublicKey,
    required this.accepted,
    this.displayName = '',
    this.avatarId = '',
  });

  final Uint8List invitationId;
  final Uint8List inviterLongTermPublicKey;
  final bool accepted;
  final String displayName;
  final String avatarId;
}

/// Steady-state profile update sent between two connected contacts.
///
/// Wire layout:
/// `[ framing_version | kind=3 | sender_long_term_pub(32) |
///    aead_nonce(12) | aead_ciphertext_with_tag ]`
///
/// AEAD plaintext: `{ "display_name": "...", "avatar_id": "..." }` and
/// optionally `how_i_label_you` when the sender includes how they list
/// the recipient on their device (encrypted appearance notice).
class ProfileUpdateEnvelope {
  ProfileUpdateEnvelope({
    required this.senderLongTermPublicKey,
    required this.displayName,
    required this.avatarId,
    this.hasHowILabelYou = false,
    this.howILabelYou = '',
  });

  final Uint8List senderLongTermPublicKey;
  final String displayName;
  final String avatarId;

  /// When true, [howILabelYou] was present on the wire (possibly empty,
  /// meaning the sender cleared their local label for the recipient).
  final bool hasHowILabelYou;
  final String howILabelYou;
}

/// Steady-state disconnect notice. No payload beyond identifying the
/// sender; receipt drops the connected contact locally on the peer's
/// device.
///
/// Wire layout identical to [ProfileUpdateEnvelope] with empty plaintext
/// (just framing + AEAD).
class DisconnectEnvelope {
  DisconnectEnvelope({required this.senderLongTermPublicKey});

  final Uint8List senderLongTermPublicKey;
}

/// Steady-state Housing proposal sent to a connected contact.
class HousingProposalEnvelope {
  HousingProposalEnvelope({
    required this.senderLongTermPublicKey,
    required this.proposalJson,
    required this.targetParticipantId,
  });

  final Uint8List senderLongTermPublicKey;
  final String proposalJson;
  final String targetParticipantId;
}

// ---------- HKDF info strings ----------

const String _helloAeadInfo = 'compartarenta/handshake-v1/hello-aead';
const String _ackAeadInfo = 'compartarenta/handshake-v1/ack-aead';
const String _profileUpdateAeadInfo =
    'compartarenta/steady-v1/profile-update-aead';
const String _disconnectAeadInfo = 'compartarenta/steady-v1/disconnect-aead';
const String _housingProposalAeadInfo =
    'compartarenta/steady-v1/housing-proposal-aead';

// ---------- Public encode / decode API ----------

/// Source of 12-byte AEAD nonces. Swapped out in tests for deterministic
/// nonces; production uses `Random.secure`.
typedef NonceSource = Uint8List Function();

NonceSource _defaultNonceSource = _randomNonce;

Uint8List _randomNonce() {
  final r = Random.secure();
  final out = Uint8List(12);
  for (var i = 0; i < 12; i++) {
    out[i] = r.nextInt(256);
  }
  return out;
}

/// FOR TESTS ONLY. Override the AEAD nonce source.
void setNonceSourceForTesting(NonceSource source) {
  _defaultNonceSource = source;
}

/// FOR TESTS ONLY. Reset to the secure default.
void resetNonceSourceForTesting() {
  _defaultNonceSource = _randomNonce;
}

class EnvelopeCodec {
  EnvelopeCodec._();

  /// Encrypts a [HelloEnvelope] for the inviter's handshake public key.
  ///
  /// The result is the bytes to put in the relay's `ciphertext` field on
  /// `POST /v1/envelopes`. Pass [inviterHandshakePublicKey] derived from
  /// the invitation code via [RelayRouting.handshakePublicKey].
  static Future<Uint8List> encryptHello({
    required HelloEnvelope envelope,
    required Uint8List invitationNonce,
    required Uint8List inviteeLongTermPrivateKey,
    required Uint8List inviterHandshakePublicKey,
  }) async {
    final shared = await _x25519(
      privateKey: inviteeLongTermPrivateKey,
      peerPublicKey: inviterHandshakePublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: invitationNonce,
      info: _helloAeadInfo,
      length: 32,
    );
    final header = _helloHeader(
      invitationId: envelope.invitationId,
      inviteePub: envelope.inviteeLongTermPublicKey,
      aeadNonce: _defaultNonceSource(),
    );
    final plaintext = utf8.encode(
      jsonEncode({
        'display_name': envelope.displayName,
        'avatar_id': envelope.avatarId,
        'echo_nonce_b64': RelayRouting.b64(envelope.echoedNonce),
      }),
    );
    final aeadNonce = header.sublist(header.length - 12);
    final body = await _aeadEncrypt(
      key: key,
      nonce: aeadNonce,
      plaintext: plaintext,
      aad: header,
    );
    return _concat(header, body);
  }

  /// Reads the unauthenticated header of a hello envelope. The inviter
  /// calls this to learn `invitationId` (to look the nonce up in the
  /// local invitations table) and `inviteeLongTermPub` (to compute the
  /// shared secret) before invoking [decryptHello].
  static HelloHeader peekHelloHeader(Uint8List frame) {
    _expectKind(frame, EnvelopeKind.hello);
    final invitationId = Uint8List.fromList(frame.sublist(2, 10));
    final inviteePub = Uint8List.fromList(frame.sublist(10, 42));
    final aeadNonce = Uint8List.fromList(frame.sublist(42, 54));
    return HelloHeader(
      invitationId: invitationId,
      inviteeLongTermPublicKey: inviteePub,
      aeadNonce: aeadNonce,
    );
  }

  /// Validates and decrypts a hello envelope on the inviter's side.
  ///
  /// Requires the locally stored `invitationNonce` (which the inviter
  /// trusts because the row exists in their database) and the locally
  /// derived `inviterHandshakePrivateKey`.
  ///
  /// Throws [EnvelopeDecryptionError] when AEAD validation fails or the
  /// echoed nonce inside the plaintext does not match the stored one.
  static Future<HelloEnvelope> decryptHello({
    required Uint8List frame,
    required Uint8List invitationNonce,
    required Uint8List inviterHandshakePrivateKey,
  }) async {
    _expectKind(frame, EnvelopeKind.hello);
    final header = peekHelloHeader(frame);
    final body = frame.sublist(54);
    final shared = await _x25519(
      privateKey: inviterHandshakePrivateKey,
      peerPublicKey: header.inviteeLongTermPublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: invitationNonce,
      info: _helloAeadInfo,
      length: 32,
    );
    final plain = await _aeadDecrypt(
      key: key,
      nonce: header.aeadNonce,
      cipherWithTag: body,
      aad: Uint8List.fromList(frame.sublist(0, 54)),
    );
    final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final echoed = RelayRouting.unb64(json['echo_nonce_b64'] as String);
    if (!_constantTimeEquals(echoed, invitationNonce)) {
      throw const EnvelopeDecryptionError('echoed_nonce_mismatch');
    }
    return HelloEnvelope(
      invitationId: header.invitationId,
      inviteeLongTermPublicKey: header.inviteeLongTermPublicKey,
      displayName: (json['display_name'] as String?) ?? '',
      avatarId: (json['avatar_id'] as String?) ?? '',
      echoedNonce: echoed,
    );
  }

  /// Encrypts an [AckEnvelope] for the invitee's long-term public key,
  /// reusing the same shared secret as the hello (different HKDF info).
  static Future<Uint8List> encryptAck({
    required AckEnvelope envelope,
    required Uint8List invitationNonce,
    required Uint8List inviterHandshakePrivateKey,
    required Uint8List inviteeLongTermPublicKey,
  }) async {
    final shared = await _x25519(
      privateKey: inviterHandshakePrivateKey,
      peerPublicKey: inviteeLongTermPublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: invitationNonce,
      info: _ackAeadInfo,
      length: 32,
    );
    final header = _ackHeader(
      invitationId: envelope.invitationId,
      inviterPub: envelope.inviterLongTermPublicKey,
      aeadNonce: _defaultNonceSource(),
    );
    final body = utf8.encode(
      jsonEncode({
        'decision': envelope.accepted ? 'accepted' : 'rejected',
        if (envelope.accepted) ...{
          'display_name': envelope.displayName,
          'avatar_id': envelope.avatarId,
        },
      }),
    );
    final aeadNonce = header.sublist(header.length - 12);
    final encrypted = await _aeadEncrypt(
      key: key,
      nonce: aeadNonce,
      plaintext: body,
      aad: header,
    );
    return _concat(header, encrypted);
  }

  /// Reads the unauthenticated header of an ack envelope.
  static AckHeader peekAckHeader(Uint8List frame) {
    _expectKind(frame, EnvelopeKind.ack);
    final invitationId = Uint8List.fromList(frame.sublist(2, 10));
    final inviterPub = Uint8List.fromList(frame.sublist(10, 42));
    final aeadNonce = Uint8List.fromList(frame.sublist(42, 54));
    return AckHeader(
      invitationId: invitationId,
      inviterLongTermPublicKey: inviterPub,
      aeadNonce: aeadNonce,
    );
  }

  /// Validates and decrypts an ack envelope on the invitee's side.
  ///
  /// The ack uses the SAME shared secret as the hello (different HKDF
  /// `info` string => different AEAD key). The invitee re-derives the
  /// inviter's one-time handshake public key from the invitation code
  /// bytes it has stored locally; the inviter's long-term public key is
  /// **only** carried in the ack header (and is transferred to the local
  /// Contact stub once the AEAD passes).
  static Future<AckEnvelope> decryptAck({
    required Uint8List frame,
    required Uint8List invitationId,
    required Uint8List invitationNonce,
    required Uint8List inviteeLongTermPrivateKey,
  }) async {
    _expectKind(frame, EnvelopeKind.ack);
    final header = peekAckHeader(frame);
    final body = frame.sublist(54);
    final inviterHandshakePriv = await RelayRouting.handshakePrivateKey(
      invitationId: invitationId,
      nonce: invitationNonce,
    );
    final inviterHandshakePub = await RelayRouting.handshakePublicKey(
      inviterHandshakePriv,
    );
    final shared = await _x25519(
      privateKey: inviteeLongTermPrivateKey,
      peerPublicKey: inviterHandshakePub,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: invitationNonce,
      info: _ackAeadInfo,
      length: 32,
    );
    final plain = await _aeadDecrypt(
      key: key,
      nonce: header.aeadNonce,
      cipherWithTag: body,
      aad: Uint8List.fromList(frame.sublist(0, 54)),
    );
    final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final accepted = (json['decision'] as String? ?? '') == 'accepted';
    return AckEnvelope(
      invitationId: header.invitationId,
      inviterLongTermPublicKey: header.inviterLongTermPublicKey,
      accepted: accepted,
      displayName: (json['display_name'] as String?) ?? '',
      avatarId: (json['avatar_id'] as String?) ?? '',
    );
  }

  /// Encrypts a steady-state profile-update envelope addressed to a
  /// connected contact.
  static Future<Uint8List> encryptProfileUpdate({
    required ProfileUpdateEnvelope envelope,
    required Uint8List senderLongTermPrivateKey,
    required Uint8List peerLongTermPublicKey,
  }) async {
    final shared = await _x25519(
      privateKey: senderLongTermPrivateKey,
      peerPublicKey: peerLongTermPublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _profileUpdateAeadInfo,
      length: 32,
    );
    final header = _steadyHeader(
      kind: EnvelopeKind.profileUpdate,
      senderPub: envelope.senderLongTermPublicKey,
      aeadNonce: _defaultNonceSource(),
    );
    final payload = <String, dynamic>{
      'display_name': envelope.displayName,
      'avatar_id': envelope.avatarId,
    };
    if (envelope.hasHowILabelYou) {
      payload['how_i_label_you'] = envelope.howILabelYou;
    }
    final body = utf8.encode(jsonEncode(payload));
    final aeadNonce = header.sublist(header.length - 12);
    final encrypted = await _aeadEncrypt(
      key: key,
      nonce: aeadNonce,
      plaintext: body,
      aad: header,
    );
    return _concat(header, encrypted);
  }

  /// Decrypts a steady-state profile-update envelope.
  static Future<ProfileUpdateEnvelope> decryptProfileUpdate({
    required Uint8List frame,
    required Uint8List receiverLongTermPrivateKey,
  }) async {
    _expectKind(frame, EnvelopeKind.profileUpdate);
    final senderPub = Uint8List.fromList(frame.sublist(2, 34));
    final aeadNonce = Uint8List.fromList(frame.sublist(34, 46));
    final body = frame.sublist(46);
    final shared = await _x25519(
      privateKey: receiverLongTermPrivateKey,
      peerPublicKey: senderPub,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _profileUpdateAeadInfo,
      length: 32,
    );
    final plain = await _aeadDecrypt(
      key: key,
      nonce: aeadNonce,
      cipherWithTag: body,
      aad: Uint8List.fromList(frame.sublist(0, 46)),
    );
    final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final hasHow = json.containsKey('how_i_label_you');
    final howRaw = hasHow ? (json['how_i_label_you'] as String? ?? '') : '';
    return ProfileUpdateEnvelope(
      senderLongTermPublicKey: senderPub,
      displayName: (json['display_name'] as String?) ?? '',
      avatarId: (json['avatar_id'] as String?) ?? '',
      hasHowILabelYou: hasHow,
      howILabelYou: howRaw,
    );
  }

  /// Encrypts a steady-state disconnect envelope addressed to the
  /// previously-connected peer.
  static Future<Uint8List> encryptDisconnect({
    required DisconnectEnvelope envelope,
    required Uint8List senderLongTermPrivateKey,
    required Uint8List peerLongTermPublicKey,
  }) async {
    final shared = await _x25519(
      privateKey: senderLongTermPrivateKey,
      peerPublicKey: peerLongTermPublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _disconnectAeadInfo,
      length: 32,
    );
    final header = _steadyHeader(
      kind: EnvelopeKind.disconnect,
      senderPub: envelope.senderLongTermPublicKey,
      aeadNonce: _defaultNonceSource(),
    );
    final aeadNonce = header.sublist(header.length - 12);
    final encrypted = await _aeadEncrypt(
      key: key,
      nonce: aeadNonce,
      plaintext: const <int>[],
      aad: header,
    );
    return _concat(header, encrypted);
  }

  /// Decrypts a steady-state disconnect envelope.
  static Future<DisconnectEnvelope> decryptDisconnect({
    required Uint8List frame,
    required Uint8List receiverLongTermPrivateKey,
  }) async {
    _expectKind(frame, EnvelopeKind.disconnect);
    final senderPub = Uint8List.fromList(frame.sublist(2, 34));
    final aeadNonce = Uint8List.fromList(frame.sublist(34, 46));
    final body = frame.sublist(46);
    final shared = await _x25519(
      privateKey: receiverLongTermPrivateKey,
      peerPublicKey: senderPub,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _disconnectAeadInfo,
      length: 32,
    );
    await _aeadDecrypt(
      key: key,
      nonce: aeadNonce,
      cipherWithTag: body,
      aad: Uint8List.fromList(frame.sublist(0, 46)),
    );
    return DisconnectEnvelope(senderLongTermPublicKey: senderPub);
  }

  /// Encrypts a steady-state Housing proposal envelope.
  static Future<Uint8List> encryptHousingProposal({
    required HousingProposalEnvelope envelope,
    required Uint8List senderLongTermPrivateKey,
    required Uint8List peerLongTermPublicKey,
  }) async {
    final shared = await _x25519(
      privateKey: senderLongTermPrivateKey,
      peerPublicKey: peerLongTermPublicKey,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _housingProposalAeadInfo,
      length: 32,
    );
    final header = _steadyHeader(
      kind: EnvelopeKind.housingProposal,
      senderPub: envelope.senderLongTermPublicKey,
      aeadNonce: _defaultNonceSource(),
    );
    final body = utf8.encode(
      jsonEncode({
        'proposal_json': envelope.proposalJson,
        'target_participant_id': envelope.targetParticipantId,
      }),
    );
    final aeadNonce = header.sublist(header.length - 12);
    final encrypted = await _aeadEncrypt(
      key: key,
      nonce: aeadNonce,
      plaintext: body,
      aad: header,
    );
    return _concat(header, encrypted);
  }

  /// Decrypts a steady-state Housing proposal envelope.
  static Future<HousingProposalEnvelope> decryptHousingProposal({
    required Uint8List frame,
    required Uint8List receiverLongTermPrivateKey,
  }) async {
    _expectKind(frame, EnvelopeKind.housingProposal);
    final senderPub = Uint8List.fromList(frame.sublist(2, 34));
    final aeadNonce = Uint8List.fromList(frame.sublist(34, 46));
    final body = frame.sublist(46);
    final shared = await _x25519(
      privateKey: receiverLongTermPrivateKey,
      peerPublicKey: senderPub,
    );
    final key = await _hkdf(
      ikm: shared,
      salt: const <int>[],
      info: _housingProposalAeadInfo,
      length: 32,
    );
    final plain = await _aeadDecrypt(
      key: key,
      nonce: aeadNonce,
      cipherWithTag: body,
      aad: Uint8List.fromList(frame.sublist(0, 46)),
    );
    final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    return HousingProposalEnvelope(
      senderLongTermPublicKey: senderPub,
      proposalJson: (json['proposal_json'] as String?) ?? '{}',
      targetParticipantId: (json['target_participant_id'] as String?) ?? '',
    );
  }
}

/// Header view of a hello envelope returned by [EnvelopeCodec.peekHelloHeader].
class HelloHeader {
  HelloHeader({
    required this.invitationId,
    required this.inviteeLongTermPublicKey,
    required this.aeadNonce,
  });

  final Uint8List invitationId;
  final Uint8List inviteeLongTermPublicKey;
  final Uint8List aeadNonce;
}

/// Header view of an ack envelope returned by [EnvelopeCodec.peekAckHeader].
class AckHeader {
  AckHeader({
    required this.invitationId,
    required this.inviterLongTermPublicKey,
    required this.aeadNonce,
  });

  final Uint8List invitationId;
  final Uint8List inviterLongTermPublicKey;
  final Uint8List aeadNonce;
}

class EnvelopeDecryptionError implements Exception {
  const EnvelopeDecryptionError(this.reason);
  final String reason;

  @override
  String toString() => 'EnvelopeDecryptionError($reason)';
}

// ---------- internal helpers ----------

Uint8List _helloHeader({
  required Uint8List invitationId,
  required Uint8List inviteePub,
  required Uint8List aeadNonce,
}) {
  assert(invitationId.length == 8);
  assert(inviteePub.length == 32);
  assert(aeadNonce.length == 12);
  final out = Uint8List(2 + 8 + 32 + 12);
  out[0] = _framingVersion;
  out[1] = EnvelopeKind.hello;
  out.setRange(2, 10, invitationId);
  out.setRange(10, 42, inviteePub);
  out.setRange(42, 54, aeadNonce);
  return out;
}

Uint8List _ackHeader({
  required Uint8List invitationId,
  required Uint8List inviterPub,
  required Uint8List aeadNonce,
}) {
  assert(invitationId.length == 8);
  assert(inviterPub.length == 32);
  assert(aeadNonce.length == 12);
  final out = Uint8List(2 + 8 + 32 + 12);
  out[0] = _framingVersion;
  out[1] = EnvelopeKind.ack;
  out.setRange(2, 10, invitationId);
  out.setRange(10, 42, inviterPub);
  out.setRange(42, 54, aeadNonce);
  return out;
}

Uint8List _steadyHeader({
  required int kind,
  required Uint8List senderPub,
  required Uint8List aeadNonce,
}) {
  assert(senderPub.length == 32);
  assert(aeadNonce.length == 12);
  final out = Uint8List(2 + 32 + 12);
  out[0] = _framingVersion;
  out[1] = kind;
  out.setRange(2, 34, senderPub);
  out.setRange(34, 46, aeadNonce);
  return out;
}

Uint8List _concat(Uint8List a, Uint8List b) {
  final out = Uint8List(a.length + b.length);
  out.setRange(0, a.length, a);
  out.setRange(a.length, out.length, b);
  return out;
}

void _expectKind(Uint8List frame, int kind) {
  if (frame.length < 2) {
    throw const EnvelopeDecryptionError('frame_too_short');
  }
  if (frame[0] != _framingVersion) {
    throw const EnvelopeDecryptionError('unsupported_framing_version');
  }
  if (frame[1] != kind) {
    throw const EnvelopeDecryptionError('wrong_envelope_kind');
  }
}

Future<Uint8List> _x25519({
  required Uint8List privateKey,
  required Uint8List peerPublicKey,
}) async {
  final algo = Cryptography.instance.x25519();
  final ourKeyPair = await algo.newKeyPairFromSeed(privateKey);
  final peer = SimplePublicKey(peerPublicKey, type: KeyPairType.x25519);
  final shared = await algo.sharedSecretKey(
    keyPair: ourKeyPair,
    remotePublicKey: peer,
  );
  final bytes = await shared.extractBytes();
  return Uint8List.fromList(bytes);
}

Future<Uint8List> _hkdf({
  required List<int> ikm,
  required List<int> salt,
  required String info,
  required int length,
}) async {
  // Per RFC 5869 §2.2, an empty salt is treated as `HashLen` zero bytes.
  // `cryptography_plus` rejects an empty HMAC key, so we substitute here.
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

Future<Uint8List> _aeadEncrypt({
  required Uint8List key,
  required Uint8List nonce,
  required List<int> plaintext,
  required List<int> aad,
}) async {
  final algo = Chacha20.poly1305Aead();
  final secretBox = await algo.encrypt(
    plaintext,
    secretKey: SecretKey(key),
    nonce: nonce,
    aad: aad,
  );
  final out = Uint8List(
    secretBox.cipherText.length + secretBox.mac.bytes.length,
  );
  out.setRange(0, secretBox.cipherText.length, secretBox.cipherText);
  out.setRange(secretBox.cipherText.length, out.length, secretBox.mac.bytes);
  return out;
}

Future<Uint8List> _aeadDecrypt({
  required Uint8List key,
  required Uint8List nonce,
  required List<int> cipherWithTag,
  required List<int> aad,
}) async {
  if (cipherWithTag.length < 16) {
    throw const EnvelopeDecryptionError('body_too_short');
  }
  final cipher = cipherWithTag.sublist(0, cipherWithTag.length - 16);
  final tag = cipherWithTag.sublist(cipherWithTag.length - 16);
  final algo = Chacha20.poly1305Aead();
  try {
    final plain = await algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return Uint8List.fromList(plain);
  } on SecretBoxAuthenticationError {
    throw const EnvelopeDecryptionError('aead_authentication_failed');
  }
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
