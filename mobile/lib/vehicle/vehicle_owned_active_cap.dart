/// Product cap: at most this many **active** owned vehicles per Propriétaire.
const int kMaxActiveOwnedVehicles = 3;

/// Thrown when [VehiclesRepository.createVehicle] would exceed
/// [kMaxActiveOwnedVehicles].
class VehicleActiveCapExceededException implements Exception {
  const VehicleActiveCapExceededException();

  @override
  String toString() =>
      'VehicleActiveCapExceededException: at most $kMaxActiveOwnedVehicles '
      'active owned vehicles';
}

/// Thrown when a write or use-session is attempted on a deactivated vehicle.
class VehicleDeactivatedException implements Exception {
  const VehicleDeactivatedException(this.vehicleId);

  final String vehicleId;

  @override
  String toString() =>
      'VehicleDeactivatedException: vehicle $vehicleId is deactivated';
}

/// Thrown when deactivation is refused because a use session is still open.
class VehicleHasOpenUseException implements Exception {
  const VehicleHasOpenUseException(this.vehicleId);

  final String vehicleId;

  @override
  String toString() =>
      'VehicleHasOpenUseException: vehicle $vehicleId has an open use session';
}
