/// Resolves a stored plan participant id to a value present in [participantIds].
///
/// Lines may store full ids (`planId:self`) or legacy tails (`self`, `p0`). The
/// dropdown must only use ids from the current roster passed into the form.
String? resolvePlanParticipantDropdownValue(
  String? stored,
  List<String> participantIds,
) {
  if (stored == null || stored.isEmpty) {
    return null;
  }
  if (participantIds.contains(stored)) {
    return stored;
  }
  if (!stored.contains(':')) {
    for (final id in participantIds) {
      if (id.endsWith(':$stored')) {
        return id;
      }
    }
    return null;
  }
  final lastColon = stored.lastIndexOf(':');
  final planPrefix = stored.substring(0, lastColon + 1);
  final tail = stored.substring(lastColon + 1);
  for (final id in participantIds) {
    if (id.startsWith(planPrefix) && id == '$planPrefix$tail') {
      return id;
    }
  }
  return null;
}
