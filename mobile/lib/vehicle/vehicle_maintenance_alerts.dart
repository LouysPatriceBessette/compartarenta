import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'vehicle_kind.dart';

class VehicleMaintenanceAlert {
  const VehicleMaintenanceAlert({
    required this.category,
    required this.remainingAmount,
    required this.isDueNow,
  });

  final String category;
  final int remainingAmount;
  final bool isDueNow;
}

class VehicleMaintenanceAlerts {
  VehicleMaintenanceAlerts(this._db);

  final AppDatabase _db;

  Future<List<VehicleMaintenanceAlert>> alertsForVehicle(
    String vehicleId, {
    required int currentMeter,
  }) async {
    final rules = await (_db.select(_db.vehicleMaintenanceRules)
          ..where((t) => t.vehicleId.equals(vehicleId)))
        .get();
    if (rules.isEmpty) return const [];

    final initialBaseline = await _initialMeterBaseline(vehicleId);
    if (initialBaseline == null) return const [];

    final events = await (_db.select(_db.maintenanceEvents)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.servicedAt)]))
        .get();

    final out = <VehicleMaintenanceAlert>[];
    for (final rule in rules) {
      final lastForCategory = events
          .where((e) => e.category == rule.category)
          .map((e) => e.meterAtService)
          .whereType<int>()
          .fold<int?>(null, (prev, v) => prev == null || v > prev ? v : prev);
      final baseline = lastForCategory ?? initialBaseline;
      final dueAt = baseline + rule.intervalAmount;
      final remaining = dueAt - currentMeter;
      if (remaining > rule.previewWindowAmount) continue;
      out.add(
        VehicleMaintenanceAlert(
          category: rule.category,
          remainingAmount: remaining,
          isDueNow: remaining <= 0,
        ),
      );
    }
    return out;
  }

  Future<int?> _initialMeterBaseline(String vehicleId) async {
    final rows = await (_db.select(_db.vehicleMeterReadings)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(1))
        .get();
    return rows.firstOrNull?.value;
  }

  static List<VehicleMaintenanceRule> defaultRulesForKind(
    String vehicleId,
    VehicleKind kind,
  ) {
    final interval = kind.usesHorometer ? 100 : 50000;
    final preview = kind.usesHorometer ? 10 : 5000;
    return [
      VehicleMaintenanceRule(
        id: '$vehicleId:rule:oil',
        vehicleId: vehicleId,
        category: 'oil',
        intervalAmount: interval,
        previewWindowAmount: preview,
      ),
    ];
  }
}
