enum VehicleKind {
  car,
  truck,
  motorcycle,
  boat;

  bool get usesHorometer => this == VehicleKind.boat;

  String get wire => name;

  static VehicleKind? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final k in VehicleKind.values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}
