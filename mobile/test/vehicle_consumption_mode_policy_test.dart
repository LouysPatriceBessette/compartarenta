import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_mode_policy.dart';
import 'package:compartarenta/vehicle/vehicle_consumption_estimation_mode.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:compartarenta/vehicle/vehicle_usage_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldCollectDetailedDrivingMix', () {
    late Vehicle detailedOwnerVehicle;
    late Vehicle simpleOwnerVehicle;

    setUp(() {
      detailedOwnerVehicle = Vehicle(
        id: 'vehicle:detailed',
        ownerContactId: kVehicleOwnerSelfContactId,
        vehicleKind: VehicleKind.car.wire,
        displayLabel: 'Car',
        make: '',
        model: '',
        color: '',
        modelYear: null,
        licensePlate: '',
        vin: '',
        fuelTankCapacityLiters: 60,
        consumptionEstimationMode:
            VehicleConsumptionEstimationMode.detailed.wire,
        requireDetailedDrivingMixForBorrowers: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      simpleOwnerVehicle = Vehicle(
        id: detailedOwnerVehicle.id,
        ownerContactId: detailedOwnerVehicle.ownerContactId,
        vehicleKind: detailedOwnerVehicle.vehicleKind,
        displayLabel: detailedOwnerVehicle.displayLabel,
        make: '',
        model: '',
        color: '',
        modelYear: null,
        licensePlate: '',
        vin: '',
        fuelTankCapacityLiters: 60,
        consumptionEstimationMode:
            VehicleConsumptionEstimationMode.simple.wire,
        requireDetailedDrivingMixForBorrowers: false,
        createdAt: detailedOwnerVehicle.createdAt,
        updatedAt: detailedOwnerVehicle.updatedAt,
      );
    });

    test('owner in detailed mode always collects mix', () {
      expect(
        shouldCollectDetailedDrivingMix(
          vehicle: detailedOwnerVehicle,
          usageContext: const VehicleUsageContext.owner(),
        ),
        isTrue,
      );
    });

    test('owner in simple mode does not collect mix', () {
      expect(
        shouldCollectDetailedDrivingMix(
          vehicle: simpleOwnerVehicle,
          usageContext: const VehicleUsageContext.owner(),
        ),
        isFalse,
      );
    });

    test('borrower follows owner impose flag in detailed mode', () {
      final imposed = Vehicle(
        id: detailedOwnerVehicle.id,
        ownerContactId: detailedOwnerVehicle.ownerContactId,
        vehicleKind: detailedOwnerVehicle.vehicleKind,
        displayLabel: detailedOwnerVehicle.displayLabel,
        make: '',
        model: '',
        color: '',
        modelYear: null,
        licensePlate: '',
        vin: '',
        fuelTankCapacityLiters: 60,
        consumptionEstimationMode:
            VehicleConsumptionEstimationMode.detailed.wire,
        requireDetailedDrivingMixForBorrowers: true,
        createdAt: detailedOwnerVehicle.createdAt,
        updatedAt: detailedOwnerVehicle.updatedAt,
      );
      const borrower = VehicleUsageContext.borrower(
        actingContactId: 'contact:borrower',
      );
      expect(
        shouldCollectDetailedDrivingMix(vehicle: imposed, usageContext: borrower),
        isTrue,
      );
      expect(
        shouldCollectDetailedDrivingMix(
          vehicle: detailedOwnerVehicle,
          usageContext: borrower,
        ),
        isFalse,
      );
    });

    test('borrower never collects mix when owner uses simple mode', () {
      const borrower = VehicleUsageContext.borrower(
        actingContactId: 'contact:borrower',
      );
      final simpleImposed = Vehicle(
        id: simpleOwnerVehicle.id,
        ownerContactId: simpleOwnerVehicle.ownerContactId,
        vehicleKind: simpleOwnerVehicle.vehicleKind,
        displayLabel: simpleOwnerVehicle.displayLabel,
        make: '',
        model: '',
        color: '',
        modelYear: null,
        licensePlate: '',
        vin: '',
        fuelTankCapacityLiters: 60,
        consumptionEstimationMode:
            VehicleConsumptionEstimationMode.simple.wire,
        requireDetailedDrivingMixForBorrowers: true,
        createdAt: simpleOwnerVehicle.createdAt,
        updatedAt: simpleOwnerVehicle.updatedAt,
      );
      expect(
        shouldCollectDetailedDrivingMix(
          vehicle: simpleImposed,
          usageContext: borrower,
        ),
        isFalse,
      );
    });
  });
}
