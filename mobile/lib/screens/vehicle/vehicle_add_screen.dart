import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_units.dart';
import '../../util/vehicle_meter_display.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/vehicle_narrow_unit_field.dart';
import 'vehicle_add_gallery_section.dart';

class VehicleAddScreen extends StatefulWidget {
  const VehicleAddScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  final _label = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  final _year = TextEditingController();
  final _meter = TextEditingController();
  final _tankCapacity = TextEditingController();
  final _licensePlate = TextEditingController();
  final _vin = TextEditingController();
  VehicleKind _kind = VehicleKind.car;
  String? _meterPhotoPath;
  final _galleries = <VehicleGalleryDraft>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _label,
      _make,
      _model,
      _color,
      _year,
      _meter,
      _tankCapacity,
      _licensePlate,
      _vin,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _label,
      _make,
      _model,
      _color,
      _year,
      _meter,
      _tankCapacity,
      _licensePlate,
      _vin,
    ]) {
      c
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  int? get _parsedMeter => parseMeterInputToStoredTenths(
        _meter.text,
        usesHorometer: _kind.usesHorometer,
        distanceUnit: resolveDistanceUnit(widget.prefs),
      );

  bool get _canSave {
    if (_saving) return false;
    if (_label.text.trim().isEmpty) return false;
    if (_make.text.trim().isEmpty) return false;
    if (_model.text.trim().isEmpty) return false;
    if (_color.text.trim().isEmpty) return false;
    final yearText = _year.text.trim();
    if (yearText.length != 4) return false;
    final year = int.tryParse(yearText);
    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
      return false;
    }
    if (_parsedMeter == null) return false;
    if (_meterPhotoPath == null || _meterPhotoPath!.isEmpty) return false;
    return true;
  }

  String? _validationError(AppLocalizations l10n) {
    if (_canSave) return null;
    if (_label.text.trim().isEmpty) {
      return l10n.vehicleAddValidationLabelRequired;
    }
    if (_make.text.trim().isEmpty) {
      return l10n.vehicleAddValidationMakeRequired;
    }
    if (_model.text.trim().isEmpty) {
      return l10n.vehicleAddValidationModelRequired;
    }
    if (_color.text.trim().isEmpty) {
      return l10n.vehicleAddValidationColorRequired;
    }
    if (_year.text.trim().length != 4 ||
        int.tryParse(_year.text.trim()) == null) {
      return l10n.vehicleAddValidationYearInvalid;
    }
    if (_parsedMeter == null) {
      return l10n.vehicleAddValidationMeterRequired;
    }
    if (_meterPhotoPath == null || _meterPhotoPath!.isEmpty) {
      return l10n.vehicleMeterPhotoRequired;
    }
    return l10n.vehicleAddValidationRequiredFields;
  }

  Future<void> _pickMeterPhoto() async {
    final path = await pickVehicleMeterPhotoSource(context);
    if (path != null && mounted) setState(() => _meterPhotoPath = path);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final error = _validationError(l10n);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    setState(() => _saving = true);
    final tankText = _tankCapacity.text.trim();
    double? tankLiters;
    if (tankText.isNotEmpty) {
      final parsed = double.tryParse(tankText.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) {
        tankLiters = displayVolumeToLiters(
          parsed,
          resolveLiquidVolumeUnit(widget.prefs),
        );
      }
    }
    final repo = VehiclesRepository(AppDatabase.processScope);
    await repo.createVehicle(
      kind: _kind,
      displayLabel: _label.text.trim(),
      make: _make.text.trim(),
      model: _model.text.trim(),
      color: _color.text.trim(),
      modelYear: int.parse(_year.text.trim()),
      licensePlate: _licensePlate.text.trim(),
      vin: _vin.text.trim(),
      fuelTankCapacityLiters: tankLiters,
      initialMeterValue: _parsedMeter!,
      initialMeterPhotoPath: _meterPhotoPath!,
      galleries: _galleries.where((g) => g.photos.isNotEmpty).toList(),
    );
    if (!mounted) return;
    context.pop(true);
  }

  String _initialMeterLabel(AppLocalizations l10n) =>
      _kind.usesHorometer
          ? l10n.vehicleFieldInitialHorometer
          : l10n.vehicleFieldInitialOdometer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceUnit =
        distanceUnitAbbrev(resolveDistanceUnit(widget.prefs));
    final volumeUnit =
        liquidVolumeUnitAbbrev(resolveLiquidVolumeUnit(widget.prefs));
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
          const SizedBox(height: 12),
          AppTextField(
            controller: _color,
            decoration: InputDecoration(labelText: l10n.vehicleFieldColor),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(labelText: l10n.vehicleFieldYear),
          ),
          const SizedBox(height: 12),
          VehicleNarrowUnitField(
            controller: _meter,
            label: _initialMeterLabel(l10n),
            unitSuffix: _kind.usesHorometer ? 'h' : distanceUnit,
            decimal: true,
            onChanged: (_) => _refresh(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickMeterPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _meterPhotoPath == null
                  ? l10n.vehicleOdometerPhotoLabel
                  : l10n.vehicleMeterPhotoAttached,
            ),
          ),
          const SizedBox(height: 12),
          VehicleNarrowUnitField(
            controller: _tankCapacity,
            label: l10n.vehicleFieldFuelTankCapacity,
            unitSuffix: volumeUnit,
            decimal: true,
            onChanged: (_) => _refresh(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _licensePlate,
            decoration: InputDecoration(
              labelText: l10n.vehicleFieldLicensePlate,
              helperText: l10n.vehicleFieldOptional,
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _vin,
            decoration: InputDecoration(
              labelText: l10n.vehicleFieldVin,
              helperText: l10n.vehicleFieldOptional,
            ),
          ),
          const SizedBox(height: 24),
          VehicleAddGallerySection(
            galleries: _galleries,
            onChanged: _refresh,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSave ? _save : null,
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
