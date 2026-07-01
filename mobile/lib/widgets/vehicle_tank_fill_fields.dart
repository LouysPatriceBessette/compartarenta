import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../debug/qa_vehicle_semantics.dart';
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
    this.showFullTankSwitch = true,
    this.sectionTitle,
    this.fullTankSemanticsId,
    this.tankLevelSemanticsId,
  });

  final bool fullTank;
  final ValueChanged<bool> onFullTankChanged;
  final VehicleTankFillLevel tankFillLevel;
  final ValueChanged<VehicleTankFillLevel> onTankFillLevelChanged;
  final bool showFullTankSwitch;
  final String? sectionTitle;
  final String? fullTankSemanticsId;
  final String? tankLevelSemanticsId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showLevelSelector = !showFullTankSwitch || !fullTank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFullTankSwitch)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: VehicleNarrowUnitField.fieldMaxWidth,
              ),
              child: Row(
                children: [
                  fullTankSemanticsId == null
                      ? Switch(
                          value: fullTank,
                          onChanged: onFullTankChanged,
                        )
                      : qaVehicleSemantics(
                          identifier: fullTankSemanticsId!,
                          child: Switch(
                            value: fullTank,
                            onChanged: onFullTankChanged,
                          ),
                        ),
                  Expanded(child: Text(l10n.vehicleFuelFullTank)),
                ],
              ),
            ),
          ),
        if (showLevelSelector) ...[
          if (showFullTankSwitch) const SizedBox(height: 12),
          if (sectionTitle != null) ...[
            Text(
              sectionTitle!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: VehicleNarrowUnitField.fieldMaxWidth,
              ),
              child: tankLevelSemanticsId == null
                  ? DropdownButtonFormField<VehicleTankFillLevel>(
                      key: ValueKey(tankFillLevel.percent),
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
                    )
                  : qaVehicleSemantics(
                      identifier: tankLevelSemanticsId!,
                      child: DropdownButtonFormField<VehicleTankFillLevel>(
                        key: ValueKey(tankFillLevel.percent),
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
          ),
        ],
      ],
    );
  }
}
