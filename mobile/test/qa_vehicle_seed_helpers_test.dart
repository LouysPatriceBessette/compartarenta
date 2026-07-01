import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/qa_vehicle_seed_helpers.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('qaSeedE2eVehicle creates QA Civic at 50 000 km', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final vehicle = await qaSeedE2eVehicle(db);
    expect(vehicle.displayLabel, kQaVehicleE2eDisplayLabel);
  });
}
