import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import 'vehicle_consumption_metrics.dart';
import 'vehicle_kind.dart';

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

    final purchases = await (_db.select(_db.fuelPurchases)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)]))
        .get();
    if (purchases.isEmpty) return null;

    final latest = purchases.first;
    final vol = latest.volumeLiters;
    if (vol == null || vol <= 0) return null;

    final capacity = vehicle.fuelTankCapacityLiters;
    final kind = VehicleKind.fromWire(vehicle.vehicleKind);
    final usesHorometer = kind?.usesHorometer ?? false;
    final metrics = await VehicleConsumptionMetrics(_db).forVehicle(vehicleId);

    final levelAfterPurchase = _tankLevelAfterPurchase(
      capacityLiters: capacity,
      purchase: latest,
    );
    if (levelAfterPurchase == null) {
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    final currentMeter =
        await VehiclesRepository(_db).latestMeterValue(vehicleId);
    final purchaseMeter = latest.meterReadingValue;

    if (latest.isFullTank && capacity != null && capacity > 0) {
      return _snapshotAfterDriving(
        levelAfterPurchase: levelAfterPurchase,
        purchaseMeter: purchaseMeter,
        currentMeter: currentMeter,
        capacity: capacity,
        usesHorometer: usesHorometer,
        metrics: metrics,
      );
    }

    if (capacity == null ||
        capacity <= 0 ||
        !metrics.hasSufficientData ||
        purchaseMeter == null) {
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    return _snapshotAfterDriving(
      levelAfterPurchase: levelAfterPurchase,
      purchaseMeter: purchaseMeter,
      currentMeter: currentMeter,
      capacity: capacity,
      usesHorometer: usesHorometer,
      metrics: metrics,
    );
  }

  VehicleFuelTankSnapshot _snapshotAfterDriving({
    required double levelAfterPurchase,
    required int? purchaseMeter,
    required int? currentMeter,
    required double capacity,
    required bool usesHorometer,
    required VehicleConsumptionSnapshot metrics,
  }) {
    if (purchaseMeter == null || currentMeter == null) {
      return VehicleFuelTankSnapshot(
        volumeLiters: levelAfterPurchase,
        isCalculated: true,
      );
    }

    final deltaTenths = currentMeter - purchaseMeter;
    if (deltaTenths <= 0 || !metrics.hasSufficientData) {
      return VehicleFuelTankSnapshot(
        volumeLiters: levelAfterPurchase,
        isCalculated: true,
      );
    }

    final remaining = usesHorometer
        ? _remainingForHorometer(
            levelAfterPurchase: levelAfterPurchase,
            deltaTenths: deltaTenths,
            litersPerHour: metrics.litersPerHour,
          )
        : _remainingForOdometer(
            levelAfterPurchase: levelAfterPurchase,
            deltaTenths: deltaTenths,
            litersPer100Km: metrics.litersPer100Km,
          );

    if (remaining == null) {
      return VehicleFuelTankSnapshot(
        volumeLiters: levelAfterPurchase,
        isCalculated: true,
      );
    }

    return VehicleFuelTankSnapshot(
      volumeLiters: remaining.clamp(0.0, capacity),
      isCalculated: true,
    );
  }

  double? _tankLevelAfterPurchase({
    required double? capacityLiters,
    required FuelPurchase purchase,
  }) {
    final added = purchase.volumeLiters ?? 0;
    if (purchase.isFullTank) {
      final capacity = capacityLiters;
      if (capacity == null || capacity <= 0) return null;
      return capacity;
    }
    final capacity = capacityLiters;
    if (capacity == null || capacity <= 0) return null;
    final percent = purchase.tankFillFraction;
    if (percent == null) return null;
    final before = capacity * (percent / 100.0);
    return (before + added).clamp(0.0, capacity);
  }

  double? _remainingForOdometer({
    required double levelAfterPurchase,
    required int deltaTenths,
    required double? litersPer100Km,
  }) {
    if (litersPer100Km == null || litersPer100Km <= 0) return null;
    final km = deltaTenths / 10.0;
    final consumed = km * (litersPer100Km / 100.0);
    return levelAfterPurchase - consumed;
  }

  double? _remainingForHorometer({
    required double levelAfterPurchase,
    required int deltaTenths,
    required double? litersPerHour,
  }) {
    if (litersPerHour == null || litersPerHour <= 0) return null;
    final hours = deltaTenths / 10.0;
    final consumed = hours * litersPerHour;
    return levelAfterPurchase - consumed;
  }
}
