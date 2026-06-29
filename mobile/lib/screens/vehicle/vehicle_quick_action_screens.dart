import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_units.dart';
import '../../util/format_money.dart';
import '../../vehicle/vehicle_maintenance_categories.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../vehicle/vehicle_usage_context.dart';
import '../../vehicle/vehicle_usage_denial_ui.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/vehicle_narrow_unit_field.dart';
import 'vehicle_form_vehicle_selector.dart';

class VehicleFuelPurchaseScreen extends StatefulWidget {
  const VehicleFuelPurchaseScreen({
    super.key,
    this.initialVehicleId,
    required this.prefs,
    this.usageContext = const VehicleUsageContext.owner(),
  });

  final String? initialVehicleId;
  final AppPreferences prefs;
  final VehicleUsageContext usageContext;

  @override
  State<VehicleFuelPurchaseScreen> createState() =>
      _VehicleFuelPurchaseScreenState();
}

class _VehicleFuelPurchaseScreenState extends State<VehicleFuelPurchaseScreen> {
  final _cost = TextEditingController();
  final _volume = TextEditingController();
  final _meter = TextEditingController();
  bool _fullTank = false;
  String? _photoPath;
  List<Vehicle> _vehicles = const [];
  String? _selectedVehicleId;
  VehicleUsageAccessDenial? _denial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_cost, _volume, _meter]) {
      c.addListener(_refresh);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [_cost, _volume, _meter]) {
      c
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    final vehicles = await loadOwnedVehiclesForForms();
    final selectedId = widget.initialVehicleId?.isNotEmpty == true
        ? widget.initialVehicleId
        : vehicles.firstOrNull?.id;
    VehicleUsageAccessDenial? denial;
    if (selectedId != null) {
      final v = await VehiclesRepository(AppDatabase.processScope)
          .getVehicle(selectedId);
      denial = denyVehicleUsageAccess(
        vehicle: v,
        context: widget.usageContext,
      );
    }
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _selectedVehicleId = selectedId;
      _denial = denial;
      _loading = false;
    });
  }

  Future<void> _onVehicleSelected(String vehicleId) async {
    final v = await VehiclesRepository(AppDatabase.processScope)
        .getVehicle(vehicleId);
    if (!mounted) return;
    setState(() {
      _selectedVehicleId = vehicleId;
      _denial = denyVehicleUsageAccess(
        vehicle: v,
        context: widget.usageContext,
      );
      _photoPath = null;
    });
  }

  bool get _canSave {
    if (_denial != null || _selectedVehicleId == null) return false;
    if (double.tryParse(_cost.text.replaceAll(',', '.')) == null) return false;
    if (double.tryParse(_volume.text.replaceAll(',', '.')) == null) return false;
    if (int.tryParse(_meter.text.trim()) == null) return false;
    if (_photoPath == null || _photoPath!.isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context);
    final costMajor = double.parse(_cost.text.replaceAll(',', '.'));
    final volume = double.parse(_volume.text.replaceAll(',', '.'));
    final meter = int.parse(_meter.text.trim());
    final vehicleId = _selectedVehicleId!;
    final repo = VehiclesRepository(AppDatabase.processScope);

    await repo.saveFuelPurchase(
      vehicleId: vehicleId,
      purchasedAt: DateTime.now().toUtc(),
      costMinor: (costMajor * 100).round(),
      currency: widget.prefs.currency,
      isFullTank: _fullTank,
      recordedByContactId: widget.usageContext.actingContactId,
      volumeLiters: volume,
      meterReadingValue: meter,
      meterPhotoPath: _photoPath,
    );

    if (!mounted) return;
    if (widget.usageContext.forwardsToOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleSharingForwarded)),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final volumeUnit =
        liquidVolumeUnitAbbrev(resolveLiquidVolumeUnit(widget.prefs));
    final distanceUnit =
        distanceUnitAbbrev(resolveDistanceUnit(widget.prefs));
    final currencySymbol =
        currencyDisplaySymbol(context, widget.prefs.currency);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleQuickActionFuel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denial != null
              ? vehicleUsageDenialBody(context, _denial!)
              : ListView(
                  padding: screenBodyScrollPadding(context),
                  children: [
                    VehicleFormVehicleSelector(
                      vehicles: _vehicles,
                      selectedId: _selectedVehicleId,
                      onSelected: _onVehicleSelected,
                    ),
                    const SizedBox(height: 16),
                    VehicleNarrowUnitField(
                      controller: _cost,
                      label: l10n.vehicleFuelCost,
                      unitSuffix: currencySymbol,
                      decimal: true,
                      onChanged: (_) => _refresh(),
                    ),
                    const SizedBox(height: 12),
                    VehicleNarrowUnitField(
                      controller: _volume,
                      label: l10n.vehicleFuelVolume,
                      unitSuffix: volumeUnit,
                      decimal: true,
                      onChanged: (_) => _refresh(),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: VehicleNarrowUnitField.fieldMaxWidth,
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: _fullTank,
                              onChanged: (v) => setState(() => _fullTank = v),
                            ),
                            Expanded(
                              child: Text(l10n.vehicleFuelFullTank),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    VehicleNarrowUnitField(
                      controller: _meter,
                      label: l10n.vehicleFuelMeter,
                      unitSuffix: distanceUnit,
                      onChanged: (_) => _refresh(),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _selectedVehicleId == null
                            ? null
                            : () async {
                                final path = await pickAndStoreVehicleMeterPhoto(
                                  context,
                                  vehicleId: _selectedVehicleId!,
                                );
                                if (path != null && mounted) {
                                  setState(() => _photoPath = path);
                                }
                              },
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          _photoPath == null
                              ? l10n.vehicleOdometerPhotoLabel
                              : l10n.vehicleMeterPhotoAttached,
                        ),
                      ),
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
}

class VehicleMaintenanceFormScreen extends StatefulWidget {
  const VehicleMaintenanceFormScreen({
    super.key,
    required this.vehicleId,
    required this.prefs,
    this.usageContext = const VehicleUsageContext.owner(),
  });

  final String vehicleId;
  final AppPreferences prefs;
  final VehicleUsageContext usageContext;

  @override
  State<VehicleMaintenanceFormScreen> createState() =>
      _VehicleMaintenanceFormScreenState();
}

class _VehicleMaintenanceFormScreenState
    extends State<VehicleMaintenanceFormScreen> {
  VehicleMaintenanceCategoryWire _category =
      VehicleMaintenanceCategoryWire.oil;
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  final _meter = TextEditingController();
  VehicleUsageAccessDenial? _denial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cost.dispose();
    _notes.dispose();
    _meter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await VehiclesRepository(AppDatabase.processScope)
        .getVehicle(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _denial = denyVehicleUsageAccess(
        vehicle: v,
        context: widget.usageContext,
      );
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_denial != null) return;
    final costMajor = double.tryParse(_cost.text.replaceAll(',', '.'));
    if (costMajor == null) return;
    final repo = VehiclesRepository(AppDatabase.processScope);
    await repo.saveMaintenanceEvent(
      vehicleId: widget.vehicleId,
      servicedAt: DateTime.now().toUtc(),
      category: _category.wire,
      costMinor: (costMajor * 100).round(),
      currency: widget.prefs.currency,
      recordedByContactId: widget.usageContext.actingContactId,
      notes: _notes.text.trim(),
      meterAtService: _category.requiresOdometer
          ? int.tryParse(_meter.text.trim())
          : null,
    );
    if (!mounted) return;
    if (widget.usageContext.forwardsToOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).vehicleSharingForwarded),
        ),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleQuickActionMaintenance)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denial != null
              ? vehicleUsageDenialBody(context, _denial!)
              : ListView(
                  padding: screenBodyScrollPadding(context),
                  children: [
                    DropdownButtonFormField<VehicleMaintenanceCategoryWire>(
                      key: ValueKey(_category),
                      isExpanded: true,
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.vehicleMaintenanceCategory,
                      ),
                      items: [
                        for (final c in VehicleMaintenanceCategoryWire.values)
                          DropdownMenuItem(
                            value: c,
                            child: Text(vehicleMaintenanceCategoryLabel(l10n, c.wire)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _category = value;
                          if (!value.requiresOdometer) {
                            _meter.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: l10n.vehicleMaintenanceCost),
                    ),
                    if (_category.requiresOdometer) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _meter,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: l10n.vehicleFuelMeter),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: l10n.vehicleMaintenanceNotes),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      child: Text(l10n.commonSave),
                    ),
                  ],
                ),
    );
  }
}

class VehicleViolationFormScreen extends StatefulWidget {
  const VehicleViolationFormScreen({
    super.key,
    required this.vehicleId,
    required this.prefs,
    this.usageContext = const VehicleUsageContext.owner(),
  });

  final String vehicleId;
  final AppPreferences prefs;
  final VehicleUsageContext usageContext;

  @override
  State<VehicleViolationFormScreen> createState() =>
      _VehicleViolationFormScreenState();
}

class _VehicleViolationFormScreenState extends State<VehicleViolationFormScreen> {
  final _type = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  VehicleUsageAccessDenial? _denial;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _type.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await VehiclesRepository(AppDatabase.processScope)
        .getVehicle(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _denial = denyVehicleUsageAccess(
        vehicle: v,
        context: widget.usageContext,
      );
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_denial != null) return;
    final amountMajor = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amountMajor == null || _type.text.trim().isEmpty) return;
    final repo = VehiclesRepository(AppDatabase.processScope);
    await repo.saveTrafficViolation(
      vehicleId: widget.vehicleId,
      violatedAt: DateTime.now().toUtc(),
      violationType: _type.text.trim(),
      amountMinor: (amountMajor * 100).round(),
      currency: widget.prefs.currency,
      recordedByContactId: widget.usageContext.actingContactId,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    if (widget.usageContext.forwardsToOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).vehicleSharingForwarded),
        ),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleQuickActionViolation)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denial != null
              ? vehicleUsageDenialBody(context, _denial!)
              : ListView(
                  padding: screenBodyScrollPadding(context),
                  children: [
                    AppTextField(
                      controller: _type,
                      decoration: InputDecoration(labelText: l10n.vehicleViolationType),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: l10n.vehicleViolationAmount),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: l10n.vehicleMaintenanceNotes),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      child: Text(l10n.commonSave),
                    ),
                  ],
                ),
    );
  }
}
