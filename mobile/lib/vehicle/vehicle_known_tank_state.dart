import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Latest declared tank fill state from fuel purchases or meter readings.
class VehicleKnownTankState {
  const VehicleKnownTankState({
    required this.recordedAt,
    required this.isFullTank,
    required this.tankFillFraction,
  });

  final DateTime recordedAt;
  final bool isFullTank;
  final int? tankFillFraction;

  int? get tankPercent => isFullTank ? 100 : tankFillFraction;

  static Future<VehicleKnownTankState?> latest(
    AppDatabase db,
    String vehicleId,
  ) async {
    VehicleKnownTankState? best;

    void consider({
      required DateTime recordedAt,
      required bool isFullTank,
      required int? tankFillFraction,
    }) {
      if (best == null || recordedAt.isAfter(best!.recordedAt)) {
        best = VehicleKnownTankState(
          recordedAt: recordedAt,
          isFullTank: isFullTank,
          tankFillFraction: tankFillFraction,
        );
      }
    }

    final purchases = await (db.select(db.fuelPurchases)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    for (final purchase in purchases) {
      consider(
        recordedAt: purchase.purchasedAt,
        isFullTank: purchase.isFullTank,
        tankFillFraction: purchase.tankFillFraction,
      );
    }

    final readings = await (db.select(db.vehicleMeterReadings)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) & t.isFullTank.isNotNull(),
          ))
        .get();
    for (final reading in readings) {
      consider(
        recordedAt: reading.recordedAt,
        isFullTank: reading.isFullTank!,
        tankFillFraction: reading.tankFillFraction,
      );
    }

    return best;
  }
}
