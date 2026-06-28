import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleAddScreen extends StatefulWidget {
  const VehicleAddScreen({super.key});

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  final _label = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  VehicleKind _kind = VehicleKind.car;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _make.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    setState(() => _saving = true);
    final repo = VehiclesRepository(AppDatabase.processScope);
    await repo.createVehicle(
      kind: _kind,
      displayLabel: label,
      make: _make.text.trim(),
      model: _model.text.trim(),
    );
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleAddVehicle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          AppTextField(
            controller: _label,
            decoration: InputDecoration(labelText: l10n.vehicleFieldLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<VehicleKind>(
            initialValue: _kind,
            decoration: InputDecoration(labelText: l10n.vehicleFieldKind),
            items: VehicleKind.values
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(_kindLabel(l10n, k)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _kind = v);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _make,
            decoration: InputDecoration(labelText: l10n.vehicleFieldMake),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _model,
            decoration: InputDecoration(labelText: l10n.vehicleFieldModel),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  String _kindLabel(AppLocalizations l10n, VehicleKind k) => switch (k) {
        VehicleKind.car => l10n.vehicleKindCar,
        VehicleKind.truck => l10n.vehicleKindTruck,
        VehicleKind.motorcycle => l10n.vehicleKindMotorcycle,
        VehicleKind.boat => l10n.vehicleKindBoat,
      };
}
