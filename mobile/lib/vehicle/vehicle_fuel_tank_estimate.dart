import '../db/app_database.dart';
import 'vehicle_known_tank_state.dart';

class VehicleFuelTankSnapshot {
  const VehicleFuelTankSnapshot({
    required this.volumeLiters,
    required this.isCalculated,
  });

  final double volumeLiters;
  final bool isCalculated;
}

class VehicleFuelTankEstimate {
  VehicleFuelTankEstimate(this._db);

  final AppDatabase _db;

  Future<VehicleFuelTankSnapshot?> forVehicle(String vehicleId) async {
    final vehicle = await (_db.select(_db.vehicles)
          ..where((t) => t.id.equals(vehicleId)))
        .getSingleOrNull();
    if (vehicle == null) return null;

    final capacity = vehicle.fuelTankCapacityLiters;
    if (capacity == null || capacity <= 0) return null;

    final tankState = await VehicleKnownTankState.latest(_db, vehicleId);
    if (tankState == null) return null;

    final percent = tankState.tankPercent;
    if (percent == null) return null;

    return VehicleFuelTankSnapshot(
      volumeLiters: (capacity * (percent / 100.0)).clamp(0.0, capacity),
      isCalculated: true,
    );
  }
}
