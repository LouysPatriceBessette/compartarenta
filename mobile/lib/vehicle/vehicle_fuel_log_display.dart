import '../db/app_database.dart';
import '../vehicle/vehicle_tank_fill_levels.dart';

/// User-facing tank fill state for a fuel purchase or meter reading.
String formatTankFillStateLabel({
  required bool? isFullTank,
  required int? tankFillFraction,
}) {
  if (isFullTank == null) return '';
  if (isFullTank) return '100%';
  final level = VehicleTankFillLevel.fromPercent(tankFillFraction);
  if (level != null) return level.label();
  return '—';
}

String formatFuelTankStateLabel(FuelPurchase purchase) =>
    formatTankFillStateLabel(
      isFullTank: purchase.isFullTank,
      tankFillFraction: purchase.tankFillFraction,
    );

String formatMeterReadingTankStateLabel(VehicleMeterReading reading) =>
    formatTankFillStateLabel(
      isFullTank: reading.isFullTank,
      tankFillFraction: reading.tankFillFraction,
    );
