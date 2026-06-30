/// Owner-chosen fuel consumption estimation style for road vehicles.
enum VehicleConsumptionEstimationMode {
  simple,
  detailed;

  String get wire => name;

  static VehicleConsumptionEstimationMode fromWire(String? raw) {
    if (raw == simple.wire) return simple;
    return detailed;
  }
}
