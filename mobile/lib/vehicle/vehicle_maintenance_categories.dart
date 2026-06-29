import '../l10n/app_localizations.dart';

/// Persisted maintenance category wire values.
enum VehicleMaintenanceCategoryWire {
  oil('oil'),
  otherFluids('other_fluids'),
  tires('tires'),
  brakes('brakes'),
  lights('lights'),
  cleaning('cleaning'),
  other('other');

  const VehicleMaintenanceCategoryWire(this.wire);

  final String wire;

  static VehicleMaintenanceCategoryWire? fromWire(String? raw) {
    if (raw == null) return null;
    for (final c in VehicleMaintenanceCategoryWire.values) {
      if (c.wire == raw) return c;
    }
    return null;
  }

  bool get requiresOdometer => this == VehicleMaintenanceCategoryWire.oil;
}

String vehicleMaintenanceCategoryLabel(
  AppLocalizations l10n,
  String categoryWire,
) {
  return switch (VehicleMaintenanceCategoryWire.fromWire(categoryWire)) {
    VehicleMaintenanceCategoryWire.oil => l10n.vehicleMaintenanceCategoryOil,
    VehicleMaintenanceCategoryWire.otherFluids =>
      l10n.vehicleMaintenanceCategoryOtherFluids,
    VehicleMaintenanceCategoryWire.tires => l10n.vehicleMaintenanceCategoryTires,
    VehicleMaintenanceCategoryWire.brakes => l10n.vehicleMaintenanceCategoryBrakes,
    VehicleMaintenanceCategoryWire.lights => l10n.vehicleMaintenanceCategoryLights,
    VehicleMaintenanceCategoryWire.cleaning =>
      l10n.vehicleMaintenanceCategoryCleaning,
    VehicleMaintenanceCategoryWire.other => l10n.vehicleMaintenanceCategoryOther,
    null => categoryWire,
  };
}
