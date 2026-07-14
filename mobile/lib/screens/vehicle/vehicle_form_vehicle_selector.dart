import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';

/// Dropdown of owned vehicles by [Vehicle.displayLabel].
class VehicleFormVehicleSelector extends StatelessWidget {
  const VehicleFormVehicleSelector({
    super.key,
    required this.vehicles,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Vehicle> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (vehicles.isEmpty) {
      return Text(l10n.vehicleMyVehiclesEmpty);
    }
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedId),
      isExpanded: true,
      initialValue: selectedId,
      decoration: InputDecoration(labelText: l10n.vehicleFormVehicleLabel),
      items: [
        for (final v in vehicles)
          DropdownMenuItem(value: v.id, child: Text(v.displayLabel)),
      ],
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
    );
  }
}

Future<List<Vehicle>> loadOwnedVehiclesForForms() =>
    VehiclesRepository(AppDatabase.processScope).listActiveOwnedVehicles();
