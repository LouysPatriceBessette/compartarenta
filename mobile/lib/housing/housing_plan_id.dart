import 'dart:convert';
import 'dart:math';

/// Housing plan identifiers: opaque UUID assigned at draft creation.
///
/// Author devices store `housing:<uuid>`. Peers store `received:<uuid>` with the
/// same uuid suffix. Entitlement and relay gates use `housing:<uuid>` on every
/// device — transmitted as-is in proposal payloads, without hashing or
/// base64 derivation.
const String kHousingPlanIdPrefix = 'housing:';
const String kReceivedPlanIdPrefix = 'received:';

/// Generates `housing:<uuid-v4>` for a new draft plan row.
String newHousingPlanId() => '$kHousingPlanIdPrefix${newUuidV4()}';

/// Stable entitlement [`plan_id`] for relay gates and roster HTTP.
String entitlementPlanIdForLocalPlan(String localPlanId) {
  if (localPlanId.startsWith(kHousingPlanIdPrefix)) {
    final suffix = localPlanId.substring(kHousingPlanIdPrefix.length);
    if (looksLikeUuid(suffix)) {
      return localPlanId;
    }
    return _legacyEntitlementPlanId(localPlanId);
  }
  if (localPlanId.startsWith(kReceivedPlanIdPrefix)) {
    final suffix = localPlanId.substring(kReceivedPlanIdPrefix.length);
    if (looksLikeUuid(suffix)) {
      return '$kHousingPlanIdPrefix$suffix';
    }
  }
  return _legacyEntitlementPlanId(localPlanId);
}

/// Local peer plan row id for a proposal authored on another device.
String receivedPlanIdForAuthorPlan(String authorPlanId) {
  if (authorPlanId.startsWith(kHousingPlanIdPrefix)) {
    final suffix = authorPlanId.substring(kHousingPlanIdPrefix.length);
    if (looksLikeUuid(suffix)) {
      return '$kReceivedPlanIdPrefix$suffix';
    }
  }
  return '$kReceivedPlanIdPrefix${_legacyReceivedToken(authorPlanId)}';
}

/// Reads the author's plan id from a proposal payload (export or relay body).
String? authorPlanIdFromProposalPayload(Map<String, dynamic> payload) {
  final explicit = payload['entitlementPlanId'];
  if (explicit is String && explicit.startsWith(kHousingPlanIdPrefix)) {
    return explicit;
  }

  for (final id in _participantSourceIds(payload)) {
    final prefix = planIdPrefixFromParticipantId(id);
    if (prefix != null) return prefix;
  }

  final packageId = payload['packageId'];
  if (packageId is String && packageId.startsWith('pkg:$kHousingPlanIdPrefix')) {
    return packageId.substring('pkg:'.length);
  }
  return null;
}

String? planIdPrefixFromParticipantId(String participantId) {
  final idx = participantId.lastIndexOf(':');
  if (idx <= 0) return null;
  final prefix = participantId.substring(0, idx);
  if (prefix.startsWith(kHousingPlanIdPrefix) ||
      prefix.startsWith(kReceivedPlanIdPrefix)) {
    return prefix.startsWith(kReceivedPlanIdPrefix)
        ? entitlementPlanIdForLocalPlan(prefix)
        : prefix;
  }
  return null;
}

bool looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}

String newUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
      '${hex(bytes[4])}${hex(bytes[5])}-'
      '${hex(bytes[6])}${hex(bytes[7])}-'
      '${hex(bytes[8])}${hex(bytes[9])}-'
      '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}'
      '${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
}

Iterable<String> _participantSourceIds(Map<String, dynamic> payload) sync* {
  final proposer = payload['proposerParticipantId'];
  if (proposer is String && proposer.isNotEmpty) yield proposer;

  final snapshots = payload['participantSnapshots'];
  if (snapshots is List) {
    for (final item in snapshots) {
      if (item is Map) {
        final id = item['id'];
        if (id is String && id.isNotEmpty) yield id;
      }
    }
  }

  final sourceIds = payload['participantSourceIds'];
  if (sourceIds is Map) {
    for (final id in sourceIds.keys) {
      if (id is String && id.isNotEmpty) yield id;
    }
  }
}

/// Pre-UUID plans (`housing:default`, microsecond drafts): keep prior token so
/// existing rows and tests still resolve consistently.
String _legacyEntitlementPlanId(String localPlanId) {
  if (localPlanId.startsWith(kReceivedPlanIdPrefix)) {
    return localPlanId;
  }
  final packageId = 'pkg:$localPlanId';
  final token = base64Url.encode(utf8.encode(packageId)).replaceAll('=', '');
  return '$kReceivedPlanIdPrefix$token';
}

String _legacyReceivedToken(String authorPlanId) {
  final packageId = 'pkg:$authorPlanId';
  return base64Url.encode(utf8.encode(packageId)).replaceAll('=', '');
}
