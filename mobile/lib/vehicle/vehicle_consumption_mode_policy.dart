import '../db/app_database.dart';
import 'vehicle_consumption_estimation_mode.dart';
import 'vehicle_driving_condition_consumption.dart';
import 'vehicle_kind.dart';
import 'vehicle_usage_context.dart';

/// Whether the session-end form must collect route / city / traffic percents.
bool shouldCollectDetailedDrivingMix({
  required Vehicle vehicle,
  required VehicleUsageContext usageContext,
}) {
  final kind = VehicleKind.fromWire(vehicle.vehicleKind);
  if (kind?.usesHorometer ?? false) return false;

  final ownerMode =
      VehicleConsumptionEstimationMode.fromWire(vehicle.consumptionEstimationMode);
  if (ownerMode == VehicleConsumptionEstimationMode.detailed) {
    if (usageContext.isOwner) return true;
    return vehicle.requireDetailedDrivingMixForBorrowers;
  }
  return false;
}

/// Effective mode recorded when a use session ends.
VehicleConsumptionEstimationMode sessionConsumptionModeForClose({
  required bool collectedDetailedMix,
}) {
  return collectedDetailedMix
      ? VehicleConsumptionEstimationMode.detailed
      : VehicleConsumptionEstimationMode.simple;
}

VehicleConsumptionEstimationMode effectiveSessionConsumptionMode(VehicleUse use) {
  final stored = use.sessionConsumptionMode;
  if (stored != null && stored.isNotEmpty) {
    return VehicleConsumptionEstimationMode.fromWire(stored);
  }
  final route = use.drivingRoutePercent;
  final city = use.drivingCityPercent;
  final traffic = use.drivingTrafficPercent;
  if (route != null &&
      city != null &&
      traffic != null &&
      drivingMixPercentsValid(route, city, traffic)) {
    return VehicleConsumptionEstimationMode.detailed;
  }
  return VehicleConsumptionEstimationMode.simple;
}
