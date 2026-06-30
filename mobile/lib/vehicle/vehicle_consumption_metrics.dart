import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import 'vehicle_kind.dart';

/// Derived consumption metrics from stored fuel facts (not authoritative).
class VehicleConsumptionSnapshot {
  const VehicleConsumptionSnapshot({
    required this.hasSufficientData,
    this.litersPer100Km,
    this.litersPerHour,
    this.anchorStartAt,
    this.anchorEndAt,
    this.distanceInWindow,
    this.volumeInWindow,
  });

  final bool hasSufficientData;
  final double? litersPer100Km;
  final double? litersPerHour;
  final DateTime? anchorStartAt;
  final DateTime? anchorEndAt;
  final int? distanceInWindow;
  final double? volumeInWindow;
}

class VehicleConsumptionMetrics {
  VehicleConsumptionMetrics(this._db);

  final AppDatabase _db;

  Future<VehicleConsumptionSnapshot> forVehicle(String vehicleId) async {
    final vehicle = await (_db.select(_db.vehicles)
          ..where((t) => t.id.equals(vehicleId)))
        .getSingleOrNull();
    if (vehicle == null) {
      return const VehicleConsumptionSnapshot(hasSufficientData: false);
    }
    final kind = VehicleKind.fromWire(vehicle.vehicleKind);
    final anchors = await (_db.select(_db.fuelPurchases)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.isFullTank.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)]))
        .get();
    if (anchors.length < 2) {
      return const VehicleConsumptionSnapshot(hasSufficientData: false);
    }
    final newest = anchors[0];
    final previous = anchors[1];
    // Use meter readings at full-tank anchors when present.
    final endMeter = newest.meterReadingValue;
    final startMeter = previous.meterReadingValue;
    if (endMeter == null || startMeter == null || endMeter <= startMeter) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        anchorStartAt: previous.purchasedAt,
        anchorEndAt: newest.purchasedAt,
      );
    }
    final delta = endMeter - startMeter;
    if (delta <= 0) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        anchorStartAt: previous.purchasedAt,
        anchorEndAt: newest.purchasedAt,
      );
    }
    final vol = newest.volumeLiters;
    if (vol == null || vol <= 0) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        anchorStartAt: previous.purchasedAt,
        anchorEndAt: newest.purchasedAt,
      );
    }
    if (kind?.usesHorometer ?? false) {
      final hours = delta / 10.0;
      if (hours <= 0) {
        return const VehicleConsumptionSnapshot(hasSufficientData: false);
      }
      return VehicleConsumptionSnapshot(
        hasSufficientData: true,
        litersPerHour: vol / hours,
        anchorStartAt: previous.purchasedAt,
        anchorEndAt: newest.purchasedAt,
        distanceInWindow: delta,
        volumeInWindow: vol,
      );
    }
    return VehicleConsumptionSnapshot(
      hasSufficientData: true,
      litersPer100Km: (vol / delta) * 1000,
      anchorStartAt: previous.purchasedAt,
      anchorEndAt: newest.purchasedAt,
      distanceInWindow: delta,
      volumeInWindow: vol,
    );
  }

  Future<int> totalLifetimeUsage(String vehicleId) async {
    final repo = VehiclesRepository(_db);
    final latest = await repo.latestMeterAnchor(vehicleId);
    final earliest = await repo.earliestMeterAnchor(vehicleId);
    if (latest != null && earliest != null) {
      final delta = latest.value - earliest.value;
      if (delta > 0) return delta;
    }

    final uses = await (_db.select(_db.vehicleUses)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    var total = 0;
    for (final u in uses) {
      total += u.usageAmount ?? 0;
    }
    return total;
  }
}
