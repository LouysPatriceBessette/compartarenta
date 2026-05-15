import '../db/app_database.dart';

extension ContactDisplayX on Contact {
  /// Name shown in lists and pickers: local label overrides peer canonical.
  String get effectiveDisplayName {
    final o = localDisplayLabel?.trim();
    if (o != null && o.isNotEmpty) return o;
    return displayName;
  }

  /// True when the UI should show an extra line for the peer's asserted
  /// canonical name (local list label is set **and** differs from it).
  bool get showsDistinctPeerCanonicalForDisplay {
    final o = localDisplayLabel?.trim();
    if (o == null || o.isEmpty) return false;
    return o != displayName.trim();
  }

  /// Formerly connected; demoted after disconnect (`disconnectedAt` set).
  bool get showsDisconnectedStatus =>
      kind == 'local-only' && disconnectedAt != null;
}
