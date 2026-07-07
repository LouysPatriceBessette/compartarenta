enum VehicleKind {
  car,
  truck,
  motorcycle,
  boat;

  bool get usesHorometer => this == VehicleKind.boat;

  /// Kinds shown in add-vehicle UI. [boat] is implemented but hidden until
  /// the boat release ships (see OpenSpec `vehicle-module` tasks §15).
  static const List<VehicleKind> userSelectableKinds = [
    car,
    truck,
    motorcycle,
  ];

  String get wire => name;

  static VehicleKind? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final k in VehicleKind.values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}
