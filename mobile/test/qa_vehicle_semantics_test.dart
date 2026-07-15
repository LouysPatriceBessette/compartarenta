import 'package:compartarenta/debug/qa_vehicle_seed_helpers.dart';
import 'package:compartarenta/debug/qa_vehicle_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('qaVehicleCardSemanticsId slugifies display labels', () {
    expect(qaVehicleCardSemanticsId('Mon QA'), 'qa-vehicle-card-mon-qa');
    expect(
      qaVehicleCardSemanticsId(kQaVehicleE2eDisplayLabel),
      'qa-vehicle-card-qa-civic',
    );
    expect(
      qaVehicleCardSemanticsId('QA Maserati'),
      kQaVehicleCardQaMaserati,
    );
    expect(
      qaVehicleCardMeterSemanticsId(kQaVehicleE2eDisplayLabel),
      'qa-vehicle-card-qa-civic-meter',
    );
    expect(
      qaVehicleCardFuelTankSemanticsId(kQaVehicleE2eDisplayLabel),
      'qa-vehicle-card-qa-civic-fuel-tank',
    );
    expect(kQaVehicleCardQaCivicConsumption, 'qa-vehicle-card-qa-civic-consumption');
    expect(
      kQaVehicleCardQaCivicConsumptionReliability,
      'qa-vehicle-card-qa-civic-consumption-reliability',
    );
  });
}
