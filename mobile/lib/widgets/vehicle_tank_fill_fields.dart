import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../vehicle/vehicle_tank_fill_levels.dart';
import 'vehicle_narrow_unit_field.dart';

/// Full-tank switch and approximate fill selector (fuel purchase, use session).
class VehicleTankFillFields extends StatelessWidget {
  const VehicleTankFillFields({
    super.key,
    required this.fullTank,
    required this.onFullTankChanged,
    required this.tankFillLevel,
    required this.onTankFillLevelChanged,
  });

  final bool fullTank;
  final ValueChanged<bool> onFullTankChanged;
  final VehicleTankFillLevel tankFillLevel;
  final ValueChanged<VehicleTankFillLevel> onTankFillLevelChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: VehicleNarrowUnitField.fieldMaxWidth,
            ),
            child: Row(
              children: [
                Switch(
                  value: fullTank,
                  onChanged: onFullTankChanged,
                ),
                Expanded(child: Text(l10n.vehicleFuelFullTank)),
              ],
            ),
          ),
        ),
        if (!fullTank) ...[
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: VehicleNarrowUnitField.fieldMaxWidth,
              ),
              child: DropdownButtonFormField<VehicleTankFillLevel>(
                isExpanded: true,
                initialValue: tankFillLevel,
                decoration: InputDecoration(
                  labelText: l10n.vehicleFuelApproximateLevel,
                ),
                items: [
                  for (final level in VehicleTankFillLevel.choices)
                    DropdownMenuItem(
                      value: level,
                      child: Text(level.label()),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onTankFillLevelChanged(value);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
