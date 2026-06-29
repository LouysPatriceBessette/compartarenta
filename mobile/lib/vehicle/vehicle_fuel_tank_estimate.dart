import 'package:drift/drift.dart';

import '../db/app_database.dart';
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

    if (capacity == null ||
        capacity <= 0 ||
        !metrics.hasSufficientData ||
        latest.meterReadingValue == null) {
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    final currentMeter = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.recordedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (currentMeter == null) {
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    final levelAfterPurchase = _tankLevelAfterPurchase(
      capacityLiters: capacity,
      purchase: latest,
    );
    if (levelAfterPurchase == null) {
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    final deltaTenths = currentMeter.value - latest.meterReadingValue!;
    if (deltaTenths <= 0) {
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
      return VehicleFuelTankSnapshot(volumeLiters: vol, isCalculated: false);
    }

    return VehicleFuelTankSnapshot(
      volumeLiters: remaining.clamp(0.0, capacity),
      isCalculated: true,
    );
  }

  double? _tankLevelAfterPurchase({
    required double capacityLiters,
    required FuelPurchase purchase,
  }) {
    final added = purchase.volumeLiters ?? 0;
    if (purchase.isFullTank) {
      return capacityLiters;
    }
    final percent = purchase.tankFillFraction;
    if (percent == null) return null;
    final before = capacityLiters * (percent / 100.0);
    return (before + added).clamp(0.0, capacityLiters);
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
