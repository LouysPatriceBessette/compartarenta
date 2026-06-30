import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import '../util/display_units.dart';
import '../vehicle/vehicle_consumption_estimation_mode.dart';

/// Consumption estimation mode radios (simple vs detailed).
class VehicleConsumptionEstimationModeFields extends StatelessWidget {
  const VehicleConsumptionEstimationModeFields({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.prefs,
  });

  final VehicleConsumptionEstimationMode mode;
  final ValueChanged<VehicleConsumptionEstimationMode> onModeChanged;
  final AppPreferences prefs;

  String _distanceUnitWord(AppLocalizations l10n) {
    return switch (resolveDistanceUnit(prefs)) {
      DistanceUnit.km => l10n.vehicleDistanceUnitKilometres,
      DistanceUnit.miles => l10n.vehicleDistanceUnitMiles,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceUnit = _distanceUnitWord(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.vehicleConsumptionEstimationModeTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        RadioGroup<VehicleConsumptionEstimationMode>(
          groupValue: mode,
          onChanged: (value) {
            if (value != null) onModeChanged(value);
          },
          child: Column(
            children: [
              RadioListTile<VehicleConsumptionEstimationMode>(
                value: VehicleConsumptionEstimationMode.simple,
                title: Text(l10n.vehicleConsumptionEstimationModeSimpleTitle),
                subtitle: Text(
                  l10n.vehicleConsumptionEstimationModeSimpleDescription(
                    distanceUnit,
                  ),
                ),
                isThreeLine: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<VehicleConsumptionEstimationMode>(
                value: VehicleConsumptionEstimationMode.detailed,
                title: Text(l10n.vehicleConsumptionEstimationModeDetailedTitle),
                subtitle: Text(
                  l10n.vehicleConsumptionEstimationModeDetailedDescription(
                    distanceUnit,
                  ),
                ),
                isThreeLine: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
