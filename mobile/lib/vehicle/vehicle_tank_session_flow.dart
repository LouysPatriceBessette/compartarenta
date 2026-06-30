import 'package:flutter/material.dart';

import '../db/repositories/vehicles_repository.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import '../util/vehicle_meter_display.dart';
import '../widgets/app_dialog.dart';
import 'vehicle_tank_fill_levels.dart';

/// Minimum road distance since the last fuel purchase that triggers a
/// confirmation when the session-end tank level is at the highest choice.
const int kSessionEndHighTankConfirmMinKm = 350;

bool sessionEndTankLevelNeedsConfirmation({
  required int declaredTankPercent,
  required int? distanceTenthsSinceLastFuelPurchase,
  required bool usesHorometer,
}) {
  if (usesHorometer) return false;
  if (declaredTankPercent != VehicleTankFillLevel.highestPercent) {
    return false;
  }
  final tenths = distanceTenthsSinceLastFuelPurchase;
  if (tenths == null) return false;
  return tenths >= kSessionEndHighTankConfirmMinKm * 10;
}

/// Prompts when a high tank level is declared after a long drive since the
/// last fuel purchase. Returns `false` if the user cancels.
Future<bool> confirmSessionEndTankLevelIfNeeded({
  required BuildContext context,
  required AppLocalizations l10n,
  required VehiclesRepository repo,
  required String vehicleId,
  required int parsedMeterTenths,
  required int declaredTankPercent,
  required bool usesHorometer,
  required DistanceUnit distanceUnit,
}) async {
  final distanceTenths = await repo.distanceTenthsSinceLastFuelPurchase(
    vehicleId,
    currentMeterTenths: parsedMeterTenths,
  );
  if (!sessionEndTankLevelNeedsConfirmation(
    declaredTankPercent: declaredTankPercent,
    distanceTenthsSinceLastFuelPurchase: distanceTenths,
    usesHorometer: usesHorometer,
  )) {
    return true;
  }
  if (!context.mounted) return false;

  final distanceDisplay = formatStoredMeterDeltaForDisplay(
    context,
    distanceTenths!,
    usesHorometer: false,
    distanceUnit: distanceUnit,
  );

  final confirmed = await showAppDialog<bool>(
    context: context,
    guardKey: 'vehicleSessionEndTankConfirm',
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.vehicleSessionEndTankConfirmTitle),
        content: Text(
          l10n.vehicleSessionEndTankConfirmBody(
            distanceDisplay,
            declaredTankPercent,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.vehicleSessionEndTankConfirmReview),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.vehicleSessionEndTankConfirmProceed),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
