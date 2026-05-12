import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// On-device generator and validator for contact-invitation codes.
///
/// The human-readable code is a Crockford-base32 encoding of a short payload
/// (nonce bytes + invitation id bytes) terminated by a one-character mod-37
/// checksum, grouped into blocks for legibility.
///
/// The code carries:
///  * a 96-bit invitation nonce (consumed by a single successful handshake or
///    by an explicit revocation),
///  * a 64-bit invitation id (the stable identifier in
///    [ContactInvitations.id], so the inviter's device can look the row up),
///  * a 4-bit version tag.
///
/// The encoding is intentionally chosen so the resulting code can be dictated
/// over a phone call: Crockford-base32 drops easily-confused characters
/// (`I`, `L`, `O`, `U`) and the checksum surfaces single-character typos.
///
/// This file deliberately does NOT bind to any cryptographic key material yet.
/// The peer public material exchanged later in the handshake is opaque to
/// this layer; bytes carried in the invitation code are scoped to the
/// invitation, not to the user's long-term identity.
class InvitationCode {
  InvitationCode._({
    required this.version,
    required this.invitationId,
    required this.nonce,
  })  : assert(invitationId.length == invitationIdBytes),
        assert(nonce.length == nonceBytes);

  static const int currentVersion = 1;
  static const int nonceBytes = 12;
  static const int invitationIdBytes = 8;

  final int version;
  final Uint8List invitationId;
  final Uint8List nonce;

  /// Random source used during generation. Override in tests to obtain
  /// deterministic codes; defaults to a secure RNG.
  static Random _rng = Random.secure();

  /// FOR TESTS ONLY: install a deterministic RNG. The repository guards
  /// against accidental use in production via assertions in debug mode.
  static void setRandomForTesting(Random rng) {
    assert(() {
      _rng = rng;
      return true;
    }());
  }

  static void resetRandomForTesting() {
    assert(() {
      _rng = Random.secure();
      return true;
    }());
  }

  /// Generates a fresh invitation code on-device. No network is involved.
  factory InvitationCode.generate() {
    final id = _randomBytes(invitationIdBytes);
    final nonce = _randomBytes(nonceBytes);
    return InvitationCode._(
      version: currentVersion,
      invitationId: id,
      nonce: nonce,
    );
  }

  /// Canonical human-readable rendering: groups of 5 characters separated
  /// by `-` for legibility, terminated with a one-character checksum.
  String renderShort() {
    final payload = _payloadBytes();
    final encoded = _crockfordEncode(payload);
    final checksum = _crockfordChecksum(payload);
    final raw = encoded + checksum;
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 5 == 0) buf.write('-');
      buf.write(raw[i]);
    }
    return buf.toString();
  }

  /// Deep-link representation suitable for OS share sheets and QR encoders.
  /// The scheme is intentionally app-local; the relay does not parse it.
  String renderDeepLink() {
    final encoded =
        base64Url.encode(_payloadBytes()).replaceAll('=', '');
    return 'compartarenta://contact/invite?v=$version&c=$encoded';
  }

  /// Hex representation of the nonce, suitable for storing in the local
  /// invitations table without re-encoding the full code.
  String nonceHex() => _hex(nonce);

  /// Hex representation of the invitation id, used as `ContactInvitations.id`.
  String invitationIdHex() => _hex(invitationId);

  Uint8List _payloadBytes() {
    final buf = Uint8List(1 + invitationIdBytes + nonceBytes);
    buf[0] = version & 0x0F;
    buf.setRange(1, 1 + invitationIdBytes, invitationId);
    buf.setRange(
      1 + invitationIdBytes,
      1 + invitationIdBytes + nonceBytes,
      nonce,
    );
    return buf;
  }

  static Uint8List _randomBytes(int count) {
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }

  static String _hex(Uint8List bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }
}

/// Outcome of decoding and locally validating a typed invitation code.
sealed class InvitationCodeParseResult {
  const InvitationCodeParseResult();
}

class InvitationCodeOk extends InvitationCodeParseResult {
  const InvitationCodeOk(this.code);
  final InvitationCode code;
}

enum InvitationCodeError {
  empty,
  tooShort,
  tooLong,
  invalidCharacters,
  badChecksum,
  unsupportedVersion,
}

class InvitationCodeBad extends InvitationCodeParseResult {
  const InvitationCodeBad(this.error);
  final InvitationCodeError error;
}

/// Parses a user-typed or pasted code. Strips spaces, dashes, and case; then
/// validates the checksum. Returns a structured result; never throws.
InvitationCodeParseResult parseInvitationCode(String input) {
  if (input.isEmpty) return const InvitationCodeBad(InvitationCodeError.empty);

  final cleaned = StringBuffer();
  for (final ch in input.toUpperCase().split('')) {
    if (ch == ' ' || ch == '-' || ch == '\t' || ch == '\n' || ch == '\r') {
      continue;
    }
    cleaned.write(ch);
  }
  final raw = cleaned.toString();

  // 1 version nibble + 8 invitation-id bytes + 12 nonce bytes = 21 bytes payload.
  // Crockford-base32 of 21 bytes = ceil(21*8/5) = 34 chars. Plus 1 checksum = 35.
  const expectedLen = 35;
  if (raw.length < expectedLen) {
    return const InvitationCodeBad(InvitationCodeError.tooShort);
  }
  if (raw.length > expectedLen) {
    return const InvitationCodeBad(InvitationCodeError.tooLong);
  }

  final body = raw.substring(0, raw.length - 1);
  final check = raw.substring(raw.length - 1);

  final Uint8List? payload = _crockfordDecode(body);
  if (payload == null) {
    return const InvitationCodeBad(InvitationCodeError.invalidCharacters);
  }
  if (_crockfordChecksum(payload) != check) {
    return const InvitationCodeBad(InvitationCodeError.badChecksum);
  }
  final version = payload[0] & 0x0F;
  if (version != InvitationCode.currentVersion) {
    return const InvitationCodeBad(InvitationCodeError.unsupportedVersion);
  }
  final invId = Uint8List.fromList(
    payload.sublist(1, 1 + InvitationCode.invitationIdBytes),
  );
  final nonce = Uint8List.fromList(
    payload.sublist(1 + InvitationCode.invitationIdBytes),
  );
  return InvitationCodeOk(
    InvitationCode._(version: version, invitationId: invId, nonce: nonce),
  );
}

// ---------- Crockford base32 with mod-37 checksum ----------
//
// Crockford alphabet: 0-9, A-Z minus I L O U. Case-insensitive on input.

const String _crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const String _crockfordChecksumAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ*~\$=U';

String _crockfordEncode(Uint8List input) {
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final b in input) {
    buffer = (buffer << 8) | (b & 0xFF);
    bits += 8;
    while (bits >= 5) {
      final index = (buffer >> (bits - 5)) & 0x1F;
      out.write(_crockfordAlphabet[index]);
      bits -= 5;
    }
  }
  if (bits > 0) {
    final index = (buffer << (5 - bits)) & 0x1F;
    out.write(_crockfordAlphabet[index]);
  }
  return out.toString();
}

Uint8List? _crockfordDecode(String input) {
  final upper = input.toUpperCase();
  var buffer = 0;
  var bits = 0;
  final out = <int>[];
  for (final ch in upper.split('')) {
    final value = _decodeChar(ch);
    if (value < 0) return null;
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      out.add((buffer >> (bits - 8)) & 0xFF);
      bits -= 8;
    }
  }
  return Uint8List.fromList(out);
}

int _decodeChar(String ch) {
  switch (ch) {
    case 'O':
      return 0;
    case 'I':
    case 'L':
      return 1;
    case 'U':
      return -1;
    default:
      final idx = _crockfordAlphabet.indexOf(ch);
      return idx;
  }
}

String _crockfordChecksum(Uint8List input) {
  // Treat input as a big integer mod 37; pick the corresponding character
  // from the Crockford checksum alphabet. Single-character typos in the
  // body shift the value enough to be caught.
  var mod = 0;
  for (final b in input) {
    mod = ((mod * 256) + b) % 37;
  }
  return _crockfordChecksumAlphabet[mod];
}
