import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_units.dart';
import '../../util/vehicle_meter_display.dart';
import '../../vehicle/vehicle_gap_flow.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../vehicle/vehicle_usage_context.dart';
import '../../vehicle/vehicle_usage_denial_ui.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/vehicle_narrow_unit_field.dart';
import '../../widgets/vehicle_tank_fill_fields.dart';
import '../../vehicle/vehicle_tank_fill_levels.dart';
import 'vehicle_form_vehicle_selector.dart';

/// Owner or borrower vehicle use session (start/end meter readings).
class VehicleUseSessionScreen extends StatefulWidget {
  const VehicleUseSessionScreen({
    super.key,
    this.initialVehicleId,
    this.prefs,
    this.usageContext = const VehicleUsageContext.owner(),
  });

  final String? initialVehicleId;
  final AppPreferences? prefs;
  final VehicleUsageContext usageContext;

  @override
  State<VehicleUseSessionScreen> createState() =>
      _VehicleUseSessionScreenState();
}

class _VehicleUseSessionScreenState extends State<VehicleUseSessionScreen> {
  final _reading = TextEditingController();
  bool _fullTank = true;
  VehicleTankFillLevel _tankFillLevel = VehicleTankFillLevel.defaultChoice;
  String? _photoPath;
  List<Vehicle> _vehicles = const [];
  String? _selectedVehicleId;
  Vehicle? _vehicle;
  VehicleUse? _openUse;
  VehicleUsageAccessDenial? _denial;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reading.addListener(_onReadingChanged);
    _load();
  }

  @override
  void dispose() {
    _reading.removeListener(_onReadingChanged);
    _reading.dispose();
    super.dispose();
  }

  void _onReadingChanged() => setState(() {});

  bool get _formComplete {
    final v = _vehicle;
    if (v == null) return false;
    final parsed = parseMeterInputToStoredTenths(
      _reading.text,
      usesHorometer:
          VehicleKind.fromWire(v.vehicleKind)?.usesHorometer ?? false,
      distanceUnit: widget.prefs == null
          ? DistanceUnit.km
          : resolveDistanceUnit(widget.prefs!),
    );
    if (parsed == null) return false;
    final photo = _photoPath;
    if (photo == null || photo.isEmpty) return false;
    return true;
  }

  Future<void> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final vehicles = await loadOwnedVehiclesForForms();
    final globalOpen = await repo.findAnyOpenUse();
    final selectedId = widget.initialVehicleId?.isNotEmpty == true
        ? widget.initialVehicleId
        : globalOpen?.vehicleId ?? vehicles.firstOrNull?.id;
    await _loadVehicleState(selectedId, vehicles: vehicles);
  }

  Future<void> _loadVehicleState(
    String? vehicleId, {
    List<Vehicle>? vehicles,
  }) async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final owned = vehicles ?? _vehicles;
    final v = vehicleId == null ? null : await repo.getVehicle(vehicleId);
    final denial = denyVehicleUsageAccess(
      vehicle: v,
      context: widget.usageContext,
    );
    VehicleUse? open;
    if (denial == null && v != null) {
      open = await repo.openUseForVehicle(v.id);
    }
    if (!mounted) return;
    setState(() {
      _vehicles = owned;
      _selectedVehicleId = vehicleId;
      _vehicle = v;
      _denial = denial;
      _openUse = open;
      _photoPath = null;
      _reading.clear();
      _fullTank = true;
      _tankFillLevel = VehicleTankFillLevel.defaultChoice;
      _loading = false;
    });
  }

  Future<void> _onVehicleSelected(String vehicleId) async {
    setState(() => _loading = true);
    await _loadVehicleState(vehicleId);
  }

  Future<void> _pickPhoto() async {
    final vehicleId = _selectedVehicleId;
    if (vehicleId == null) return;
    final path = await pickAndStoreVehicleMeterPhoto(
      context,
      vehicleId: vehicleId,
    );
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final v = _vehicle;
    if (v == null || _denial != null) return;
    final parsed = parseMeterInputToStoredTenths(
      _reading.text,
      usesHorometer: VehicleKind.fromWire(v.vehicleKind)?.usesHorometer ?? false,
      distanceUnit: widget.prefs == null
          ? DistanceUnit.km
          : resolveDistanceUnit(widget.prefs!),
    );
    if (parsed == null) return;
    if (_photoPath == null || _photoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleMeterPhotoRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = VehiclesRepository(AppDatabase.processScope);
    try {
      final openUse = await repo.openUseForVehicle(v.id);
      final unit = repo.meterUnitForVehicle(v);
      final kind = VehicleKind.fromWire(v.vehicleKind);
      final usesHorometer = kind?.usesHorometer ?? false;
      final distanceUnit = widget.prefs == null
          ? DistanceUnit.km
          : resolveDistanceUnit(widget.prefs!);
      final latest = await repo.latestMeterValue(v.id);
      final actingId = widget.usageContext.actingContactId;

      if (latest != null && parsed < latest) {
        if (widget.usageContext.isOwner) {
          if (!mounted) return;
          final choice = await showNegativeGapDialog(
            context,
            gapDisplay: formatStoredMeterDeltaForDisplay(
              context,
              parsed - latest,
              usesHorometer: usesHorometer,
              distanceUnit: distanceUnit,
            ),
          );
          if (!mounted) return;
          if (choice != NegativeGapChoice.maintain) {
            return;
          }
        }
      }

      if (latest != null && parsed > latest && openUse == null) {
        final ownerLinks = await repo.listActiveLinksAsOwner();
        final borrowerIds = ownerLinks
            .where((VehicleSharingLink l) => l.vehicleId == v.id)
            .map((VehicleSharingLink l) => l.borrowerContactId)
            .toList();
        final contacts =
            await ContactsRepository(AppDatabase.processScope).list();
        final labels = {
          for (final c in contacts) c.id: c.displayName,
        };
        if (!mounted) return;
        final attributed = await showPositiveGapAttributionDialog(
          context,
          gapDisplay: formatStoredMeterDeltaForDisplay(
            context,
            parsed - latest,
            usesHorometer: usesHorometer,
            distanceUnit: distanceUnit,
          ),
          participants: gapAttributionParticipants(
            l10n: l10n,
            actingContactId: actingId,
            ownerContactId: v.ownerContactId,
            activeBorrowerContactIds: borrowerIds,
            contactLabels: labels,
          ),
        );
        if (!mounted || attributed == null) {
          return;
        }
        await repo.recordPositiveGap(
          vehicleId: v.id,
          latestBefore: latest,
          startAfter: parsed,
          attributedContactId: attributed,
          recordedByContactId: actingId,
        );
        if (gapRequiresOwnerNotification(
          attributedContactId: attributed,
          recordedByContactId: actingId,
        )) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.vehicleGapOwnerNotified)),
          );
        }
      }

      final reading = await repo.saveMeterReading(
        vehicleId: v.id,
        value: parsed,
        unit: unit,
        photoPath: _photoPath!,
        recordedByContactId: actingId,
        role: openUse == null
            ? MeterReadingRole.sessionStart
            : MeterReadingRole.sessionEnd,
        vehicleUseId: openUse?.id,
        negativeGapAcknowledged: latest != null && parsed < latest,
        isFullTank: _fullTank,
        tankFillFraction: _fullTank ? null : _tankFillLevel.percent,
      );

      if (openUse == null) {
        await repo.openUseSession(
          vehicleId: v.id,
          attributedContactId: actingId,
          startReadingId: reading.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleUseSessionStarted)),
        );
        context.pop();
        return;
      }

      await repo.closeUseSession(
        useId: openUse.id,
        endReadingId: reading.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleUseSessionEnded)),
      );
      if (widget.usageContext.forwardsToOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehicleSharingForwarded)),
        );
      }
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSomethingWentWrongBody)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = _vehicle;
    final kind = VehicleKind.fromWire(v?.vehicleKind);
    final meterLabel = kind?.usesHorometer ?? false
        ? l10n.vehicleHorometerLabel
        : l10n.vehicleOdometerLabel;
    final distanceUnit = widget.prefs == null
        ? 'Km'
        : distanceUnitAbbrev(resolveDistanceUnit(widget.prefs!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _openUse == null
              ? l10n.vehicleUseSessionStart
              : l10n.vehicleUseSessionEnd,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denial != null
              ? vehicleUsageDenialBody(context, _denial!)
              : v == null
                  ? vehicleUsageDenialBody(
                      context,
                      VehicleUsageAccessDenial.vehicleNotFound,
                    )
                  : ListView(
                      padding: screenBodyScrollPadding(context),
                      children: [
                        VehicleFormVehicleSelector(
                          vehicles: _vehicles,
                          selectedId: _selectedVehicleId,
                          onSelected: _onVehicleSelected,
                        ),
                        const SizedBox(height: 16),
                        VehicleTankFillFields(
                          fullTank: _fullTank,
                          onFullTankChanged: (v) => setState(() => _fullTank = v),
                          tankFillLevel: _tankFillLevel,
                          onTankFillLevelChanged: (v) =>
                              setState(() => _tankFillLevel = v),
                        ),
                        const SizedBox(height: 12),
                        VehicleNarrowUnitField(
                          controller: _reading,
                          label: meterLabel,
                          unitSuffix: kind?.usesHorometer ?? false
                              ? 'h'
                              : distanceUnit,
                          decimal: true,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pickPhoto,
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
                          onPressed: _saving || !_formComplete ? null : _save,
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
    );
  }
}
