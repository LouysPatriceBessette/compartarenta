import 'dart:math';

/// Housing plan identifiers: opaque UUID assigned at draft creation.
///
/// **Local** Drift rows use role prefixes (`housing:<uuid>` author,
/// `received:<uuid>` invitee) so two representations of the same agreement can
/// coexist in import/remap logic.
///
/// **Server** entitlement and relay gates use the bare UUID only. Module scope
/// is carried separately (`module=housing` on introspection), not in `plan_id`.
const String kHousingPlanIdPrefix = 'housing:';
const String kReceivedPlanIdPrefix = 'received:';

/// Generates `housing:<uuid-v4>` for a new draft plan row.
String newHousingPlanId() => '$kHousingPlanIdPrefix${newUuidV4()}';

/// Bare plan UUID for entitlement roster, relay gates, and migration HTTP.
String entitlementPlanIdForLocalPlan(String localPlanId) {
  return barePlanUuidFromLocalPlanId(localPlanId) ?? localPlanId;
}

/// Extracts a UUID v4 from a bare, `housing:`, or `received:` plan row id.
String? barePlanUuidFromLocalPlanId(String localPlanId) {
  if (looksLikeUuid(localPlanId)) return localPlanId;
  for (final prefix in [kHousingPlanIdPrefix, kReceivedPlanIdPrefix]) {
    if (localPlanId.startsWith(prefix)) {
      final suffix = localPlanId.substring(prefix.length);
      if (looksLikeUuid(suffix)) return suffix;
    }
  }
  return null;
}

/// Author-side local plan row id for any local or wire plan identifier.
String localAuthorPlanId(String planId) {
  final bare = barePlanUuidFromLocalPlanId(planId);
  if (bare != null) return '$kHousingPlanIdPrefix$bare';
  if (planId.startsWith(kHousingPlanIdPrefix)) return planId;
  return planId;
}

/// Local peer plan row id for a proposal authored on another device.
String receivedPlanIdForAuthorPlan(String authorPlanId) {
  final bare = barePlanUuidFromLocalPlanId(authorPlanId);
  if (bare != null) return '$kReceivedPlanIdPrefix$bare';
  if (authorPlanId.startsWith(kHousingPlanIdPrefix)) {
    return '$kReceivedPlanIdPrefix${authorPlanId.substring(kHousingPlanIdPrefix.length)}';
  }
  return '$kReceivedPlanIdPrefix$authorPlanId';
}

/// Reads the author's local plan id from a proposal payload (export or relay).
String? authorPlanIdFromProposalPayload(Map<String, dynamic> payload) {
  final explicit = payload['entitlementPlanId'];
  if (explicit is String && explicit.isNotEmpty) {
    return localAuthorPlanId(explicit);
  }

  for (final id in _participantSourceIds(payload)) {
    final prefix = planIdPrefixFromParticipantId(id);
    if (prefix != null) return prefix;
  }

  final packageId = payload['packageId'];
  if (packageId is String && packageId.startsWith('pkg:$kHousingPlanIdPrefix')) {
    return packageId.substring('pkg:'.length);
  }
  if (packageId is String && packageId.startsWith('pkg:')) {
    final tail = packageId.substring('pkg:'.length);
    final bare = barePlanUuidFromLocalPlanId(tail);
    if (bare != null) return '$kHousingPlanIdPrefix$bare';
  }
  return null;
}

String? planIdPrefixFromParticipantId(String participantId) {
  final idx = participantId.lastIndexOf(':');
  if (idx <= 0) return null;
  final prefix = participantId.substring(0, idx);
  if (prefix.startsWith(kHousingPlanIdPrefix) ||
      prefix.startsWith(kReceivedPlanIdPrefix)) {
    return localAuthorPlanId(prefix);
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
