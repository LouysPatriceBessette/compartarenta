import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import 'vehicle_consumption_reliability.dart';
import 'vehicle_driving_condition_consumption.dart';
import 'vehicle_kind.dart';

/// One plein→plein interval used in consumption calculations.
class FullTankConsumptionInterval {
  const FullTankConsumptionInterval({
    required this.startAt,
    required this.endAt,
    required this.distanceTenths,
    required this.fuelLiters,
    required this.routeKm,
    required this.cityKm,
    required this.trafficKm,
  });

  final DateTime startAt;
  final DateTime endAt;
  final int distanceTenths;
  final double fuelLiters;
  final double routeKm;
  final double cityKm;
  final double trafficKm;

  bool get hasDrivingMix => routeKm + cityKm + trafficKm > 0;

  DrivingConditionConsumptionInput? get modeInput {
    if (!hasDrivingMix) return null;
    return DrivingConditionConsumptionInput(
      routeKm: routeKm,
      cityKm: cityKm,
      trafficKm: trafficKm,
      fuelLiters: fuelLiters,
    );
  }
}

/// Derived consumption metrics from stored fuel facts (not authoritative).
class VehicleConsumptionSnapshot {
  const VehicleConsumptionSnapshot({
    required this.hasSufficientData,
    this.reliability = VehicleConsumptionReliability.none,
    this.periodsInWindow = 0,
    this.litersPer100Km,
    this.litersPerHour,
    this.litersPer100KmRoute,
    this.litersPer100KmCity,
    this.litersPer100KmTraffic,
    this.hasModeBreakdown = false,
    this.anchorStartAt,
    this.anchorEndAt,
    this.distanceInWindow,
    this.volumeInWindow,
  });

  final bool hasSufficientData;
  final VehicleConsumptionReliability reliability;
  final int periodsInWindow;
  final double? litersPer100Km;
  final double? litersPerHour;
  final double? litersPer100KmRoute;
  final double? litersPer100KmCity;
  final double? litersPer100KmTraffic;
  final bool hasModeBreakdown;
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
    if (kind?.usesHorometer ?? false) {
      return _forHorometerVehicle(vehicleId);
    }
    final snapshot = await _forRoadVehicle(vehicleId);
    await _maybeRecordReliableHistory(vehicleId: vehicleId, snapshot: snapshot);
    return snapshot;
  }

  Future<List<VehicleConsumptionEstimateHistoryData>>
      listReliableEstimateHistory(
    String vehicleId,
  ) {
    return (_db.select(_db.vehicleConsumptionEstimateHistory)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.desc(t.anchorEndAt)]))
        .get();
  }

  Future<VehicleConsumptionSnapshot> _forHorometerVehicle(
    String vehicleId,
  ) async {
    final anchors = await _fullTankAnchorsNewestFirst(vehicleId);
    if (anchors.length < 2) {
      return const VehicleConsumptionSnapshot(hasSufficientData: false);
    }
    final newest = anchors[0];
    final previous = anchors[1];
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
    final vol = newest.volumeLiters;
    if (vol == null || vol <= 0 || delta <= 0) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        anchorStartAt: previous.purchasedAt,
        anchorEndAt: newest.purchasedAt,
      );
    }
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

  Future<VehicleConsumptionSnapshot> _forRoadVehicle(String vehicleId) async {
    final anchors = await _fullTankAnchorsNewestFirst(vehicleId);
    final allIntervals = await _buildFullTankIntervals(vehicleId, anchors);
    if (allIntervals.isEmpty) {
      return const VehicleConsumptionSnapshot(hasSufficientData: false);
    }

    final window = _rollingConsumptionWindow(allIntervals);
    final periodsInWindow = window.length;
    final reliability = consumptionReliabilityFromPeriodCount(periodsInWindow);
    if (reliability == VehicleConsumptionReliability.none) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        reliability: reliability,
        periodsInWindow: periodsInWindow,
        anchorStartAt: window.firstOrNull?.startAt,
        anchorEndAt: window.lastOrNull?.endAt,
      );
    }

    var totalDistanceTenths = 0;
    var totalFuel = 0.0;
    for (final interval in window) {
      totalDistanceTenths += interval.distanceTenths;
      totalFuel += interval.fuelLiters;
    }
    if (totalDistanceTenths <= 0 || totalFuel <= 0) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: false,
        reliability: reliability,
        periodsInWindow: periodsInWindow,
        anchorStartAt: window.first.startAt,
        anchorEndAt: window.last.endAt,
      );
    }

    final blended = (totalFuel / totalDistanceTenths) * 1000;
    final modeIntervals = window
        .map((i) => i.modeInput)
        .whereType<DrivingConditionConsumptionInput>()
        .toList();
    final modeFit = solveDrivingConditionConsumption(modeIntervals);

    if (modeFit == null) {
      return VehicleConsumptionSnapshot(
        hasSufficientData: true,
        reliability: reliability,
        periodsInWindow: periodsInWindow,
        litersPer100Km: blended,
        anchorStartAt: window.first.startAt,
        anchorEndAt: window.last.endAt,
        distanceInWindow: totalDistanceTenths,
        volumeInWindow: totalFuel,
      );
    }

    var totalRoute = 0.0;
    var totalCity = 0.0;
    var totalTraffic = 0.0;
    for (final interval in modeIntervals) {
      totalRoute += interval.routeKm;
      totalCity += interval.cityKm;
      totalTraffic += interval.trafficKm;
    }

    return VehicleConsumptionSnapshot(
      hasSufficientData: true,
      reliability: reliability,
      periodsInWindow: periodsInWindow,
      litersPer100Km: modeFit.blendedLitersPer100Km(
        totalRouteKm: totalRoute,
        totalCityKm: totalCity,
        totalTrafficKm: totalTraffic,
      ),
      litersPer100KmRoute: modeFit.litersPer100KmRoute,
      litersPer100KmCity: modeFit.litersPer100KmCity,
      litersPer100KmTraffic: modeFit.litersPer100KmTraffic,
      hasModeBreakdown: true,
      anchorStartAt: window.first.startAt,
      anchorEndAt: window.last.endAt,
      distanceInWindow: totalDistanceTenths,
      volumeInWindow: totalFuel,
    );
  }

  List<FullTankConsumptionInterval> _rollingConsumptionWindow(
    List<FullTankConsumptionInterval> chronological,
  ) {
    if (chronological.length <= kMaxFullTankIntervalsInConsumptionWindow) {
      return chronological;
    }
    return chronological.sublist(
      chronological.length - kMaxFullTankIntervalsInConsumptionWindow,
    );
  }

  Future<void> _maybeRecordReliableHistory({
    required String vehicleId,
    required VehicleConsumptionSnapshot snapshot,
  }) async {
    if (!consumptionReliabilityIsReliableOrBetter(snapshot.reliability)) {
      return;
    }
    final anchorEnd = snapshot.anchorEndAt;
    final blended = snapshot.litersPer100Km;
    if (anchorEnd == null || blended == null) return;

    final existing = await (_db.select(_db.vehicleConsumptionEstimateHistory)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.anchorEndAt.equals(anchorEnd),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.vehicleConsumptionEstimateHistory).insert(
          VehicleConsumptionEstimateHistoryCompanion.insert(
            id: _newConsumptionHistoryId(),
            vehicleId: vehicleId,
            anchorEndAt: anchorEnd,
            recordedAt: DateTime.now().toUtc(),
            reliability: snapshot.reliability.wire,
            litersPer100Km: blended,
            litersPer100KmRoute: Value(snapshot.litersPer100KmRoute),
            litersPer100KmCity: Value(snapshot.litersPer100KmCity),
            litersPer100KmTraffic: Value(snapshot.litersPer100KmTraffic),
            periodsInWindow: snapshot.periodsInWindow,
          ),
        );
  }

  Future<List<FuelPurchase>> _fullTankAnchorsNewestFirst(
    String vehicleId,
  ) {
    return (_db.select(_db.fuelPurchases)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.isFullTank.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)]))
        .get();
  }

  Future<List<FullTankConsumptionInterval>> _buildFullTankIntervals(
    String vehicleId,
    List<FuelPurchase> anchorsNewestFirst,
  ) async {
    if (anchorsNewestFirst.length < 2) return const [];

    final chronological = anchorsNewestFirst.reversed.toList();
    final uses = await (_db.select(_db.vehicleUses)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.endedAt.isNotNull() &
                t.drivingRoutePercent.isNotNull() &
                t.drivingCityPercent.isNotNull() &
                t.drivingTrafficPercent.isNotNull(),
          ))
        .get();

    final intervals = <FullTankConsumptionInterval>[];
    for (var i = 1; i < chronological.length; i++) {
      final start = chronological[i - 1];
      final end = chronological[i];
      final vol = end.volumeLiters;
      final endMeter = end.meterReadingValue;
      final startMeter = start.meterReadingValue;
      if (vol == null ||
          vol <= 0 ||
          endMeter == null ||
          startMeter == null ||
          endMeter <= startMeter) {
        continue;
      }

      final windowUses = uses.where((u) {
        final ended = u.endedAt;
        if (ended == null) return false;
        return !ended.isBefore(start.purchasedAt) &&
            !ended.isAfter(end.purchasedAt);
      });

      var routeKm = 0.0;
      var cityKm = 0.0;
      var trafficKm = 0.0;
      for (final use in windowUses) {
        final amount = use.usageAmount;
        final routePct = use.drivingRoutePercent;
        final cityPct = use.drivingCityPercent;
        final trafficPct = use.drivingTrafficPercent;
        if (amount == null ||
            routePct == null ||
            cityPct == null ||
            trafficPct == null) {
          continue;
        }
        if (!drivingMixPercentsValid(routePct, cityPct, trafficPct)) {
          continue;
        }
        routeKm += modeKmFromSession(
          usageAmountTenths: amount,
          percent: routePct,
        );
        cityKm += modeKmFromSession(
          usageAmountTenths: amount,
          percent: cityPct,
        );
        trafficKm += modeKmFromSession(
          usageAmountTenths: amount,
          percent: trafficPct,
        );
      }

      intervals.add(
        FullTankConsumptionInterval(
          startAt: start.purchasedAt,
          endAt: end.purchasedAt,
          distanceTenths: endMeter - startMeter,
          fuelLiters: vol,
          routeKm: routeKm,
          cityKm: cityKm,
          trafficKm: trafficKm,
        ),
      );
    }
    return intervals;
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

String _newConsumptionHistoryId() {
  final bytes = List<int>.generate(12, (_) => Random.secure().nextInt(256));
  return 'consumption_hist:${base64Url.encode(bytes).replaceAll('=', '')}';
}
