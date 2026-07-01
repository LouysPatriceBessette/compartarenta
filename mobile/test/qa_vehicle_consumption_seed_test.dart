import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/qa_vehicle_consumption_seed.dart';
import 'package:compartarenta/debug/qa_vehicle_seed_helpers.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_metrics.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_reliability.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed matches user entries (#0–#16)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final vehicle = await qaSeedVehicleConsumptionScenario(db);
    expect(vehicle.displayLabel, kQaVehicleE2eDisplayLabel);

    final purchases = await db.select(db.fuelPurchases).get();
    purchases.sort((a, b) => a.purchasedAt.compareTo(b.purchasedAt));
    expect(purchases, hasLength(4));
    expect(
      purchases.map((p) => p.volumeLiters).toList(),
      [60.0, 43.0, 18.0, 35.4],
    );
    expect(
      purchases.map((p) => p.costMinor).toList(),
      [
        kQaVehicleConsumptionFuelPurchase0CostMinor,
        kQaVehicleConsumptionFuelPurchase6CostMinor,
        kQaVehicleConsumptionFuelPurchase11CostMinor,
        kQaVehicleConsumptionFuelPurchase16CostMinor,
      ],
    );

    final uses = await db.select(db.vehicleUses).get();
    expect(uses, hasLength(13));
  });

  test('hub shows reliable consumption over three plein→plein intervals', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.bindProcessScope(db);
    addTearDown(() {
      AppDatabase.clearProcessScopeIfReferencing(db);
      db.close();
    });

    final vehicle = await qaSeedVehicleConsumptionScenario(db);
    final snapshot =
        await VehicleConsumptionMetrics(db).forVehicle(vehicle.id);

    expect(snapshot.hasSufficientData, isTrue);
    expect(snapshot.reliability, VehicleConsumptionReliability.reliable);
    expect(snapshot.periodsInWindow, 3);
    expect(snapshot.distanceInWindow, 13970);
    expect(snapshot.volumeInWindow, closeTo(96.4, 0.001));
    expect(snapshot.litersPer100Km, closeTo(6.9, 0.1));
    expect(snapshot.hasModeBreakdown, isTrue);
    expect(snapshot.litersPer100KmRoute, closeTo(6.7, 0.1));
    expect(snapshot.litersPer100KmCity, closeTo(6.9, 0.1));
    expect(snapshot.litersPer100KmTraffic, closeTo(8.6, 0.1));
  });
}
