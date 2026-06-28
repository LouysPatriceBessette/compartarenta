import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../vehicle/vehicle_usage_context.dart';
import '../../vehicle/vehicle_usage_denial_ui.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleFuelPurchaseScreen extends StatefulWidget {
  const VehicleFuelPurchaseScreen({
    super.key,
    required this.vehicleId,
    required this.prefs,
    this.usageContext = const VehicleUsageContext.owner(),
  });

  final String vehicleId;
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
    _volume.dispose();
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
    final l10n = AppLocalizations.of(context);
    final costMajor = double.tryParse(_cost.text.replaceAll(',', '.'));
    if (costMajor == null) return;
    final repo = VehiclesRepository(AppDatabase.processScope);
    final v = await repo.getVehicle(widget.vehicleId);
    if (v == null) return;

    await repo.saveFuelPurchase(
      vehicleId: v.id,
      purchasedAt: DateTime.now().toUtc(),
      costMinor: (costMajor * 100).round(),
      currency: widget.prefs.currency,
      isFullTank: _fullTank,
      recordedByContactId: widget.usageContext.actingContactId,
      volumeLiters: double.tryParse(_volume.text.replaceAll(',', '.')),
      meterReadingValue: int.tryParse(_meter.text.trim()),
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleQuickActionFuel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denial != null
              ? vehicleUsageDenialBody(context, _denial!)
              : ListView(
                  padding: screenBodyScrollPadding(context),
                  children: [
                    AppTextField(
                      controller: _cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.vehicleFuelCost),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _volume,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: l10n.vehicleFuelVolume),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _meter,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.vehicleFuelMeter),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(l10n.vehicleFuelFullTank),
                      value: _fullTank,
                      onChanged: (v) => setState(() => _fullTank = v),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await pickAndStoreVehicleMeterPhoto(
                          context,
                          vehicleId: widget.vehicleId,
                        );
                        if (path != null && mounted) {
                          setState(() => _photoPath = path);
                        }
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(l10n.vehicleOdometerPhotoLabel),
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
  final _category = TextEditingController(text: 'oil');
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
    _category.dispose();
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
      category: _category.text.trim(),
      costMinor: (costMajor * 100).round(),
      currency: widget.prefs.currency,
      recordedByContactId: widget.usageContext.actingContactId,
      notes: _notes.text.trim(),
      meterAtService: int.tryParse(_meter.text.trim()),
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
                    AppTextField(
                      controller: _category,
                      decoration:
                          InputDecoration(labelText: l10n.vehicleMaintenanceCategory),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: l10n.vehicleMaintenanceCost),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _meter,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.vehicleFuelMeter),
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
