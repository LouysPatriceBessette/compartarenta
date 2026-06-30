import '../../l10n/app_localizations.dart';
import 'vehicle_consumption_reliability.dart';

extension VehicleConsumptionReliabilityL10n on VehicleConsumptionReliability {
  String message(AppLocalizations l10n) {
    return switch (this) {
      VehicleConsumptionReliability.none =>
        l10n.vehicleConsumptionReliabilityNone,
      VehicleConsumptionReliability.preliminary =>
        l10n.vehicleConsumptionReliabilityPreliminary,
      VehicleConsumptionReliability.reliable =>
        l10n.vehicleConsumptionReliabilityReliable,
      VehicleConsumptionReliability.veryReliable =>
        l10n.vehicleConsumptionReliabilityVeryReliable,
    };
  }
}
