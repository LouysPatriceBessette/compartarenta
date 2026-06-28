import 'package:flutter/foundation.dart';

/// Module identifiers per OpenSpec (`vehicle`, `vehicle-sharing`).
enum VehicleModuleId {
  vehicle('vehicle'),
  vehicleSharing('vehicle-sharing');

  const VehicleModuleId(this.wire);
  final String wire;
}

/// Local entitlement gate until per-module store licensing ships.
///
/// Debug builds treat both modules as entitled. Release builds hide vehicle
/// modules until Play/App Store SKUs and entitlement introspection are wired
/// (`vehicle-module-licensing`, `per-module-licensing-and-bundles`).
class VehicleModuleAccess {
  const VehicleModuleAccess();

  bool get hasVehicleEntitlement => kDebugMode;

  bool get hasVehicleSharingEntitlement => kDebugMode;

  bool get vehicleModuleEnabled => true;

  bool get vehicleSharingModuleEnabled => true;

  bool get showVehicleHomeTile =>
      hasVehicleEntitlement && vehicleModuleEnabled;

  bool get showVehicleSharingHomeTile =>
      hasVehicleSharingEntitlement && vehicleSharingModuleEnabled;

  bool get canOfferSharing =>
      hasVehicleEntitlement && hasVehicleSharingEntitlement;

  bool get canLogAsBorrower => hasVehicleSharingEntitlement;
}
