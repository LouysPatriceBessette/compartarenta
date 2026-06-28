import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_gap_flow.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_meter_photo_picker.dart';
import '../../vehicle/vehicle_owner_contact.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';

/// Owner or borrower vehicle use session (start/end meter readings).
class VehicleUseSessionScreen extends StatefulWidget {
  const VehicleUseSessionScreen({
    super.key,
    required this.vehicleId,
    this.actingContactId = kVehicleOwnerSelfContactId,
    this.forwardToOwner = false,
  });

  final String vehicleId;
  final String actingContactId;
  final bool forwardToOwner;

  @override
  State<VehicleUseSessionScreen> createState() =>
      _VehicleUseSessionScreenState();
}

class _VehicleUseSessionScreenState extends State<VehicleUseSessionScreen> {
  final _reading = TextEditingController();
  String? _photoPath;
  Vehicle? _vehicle;
  VehicleUse? _openUse;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reading.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final v = await repo.getVehicle(widget.vehicleId);
    final open = await repo.openUseForVehicle(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _vehicle = v;
      _openUse = open;
      _loading = false;
    });
  }

  Future<void> _pickPhoto() async {
    final path = await pickAndStoreVehicleMeterPhoto(context);
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final v = _vehicle;
    if (v == null) return;
    final parsed = int.tryParse(_reading.text.trim());
    if (parsed == null) return;
    if (_photoPath == null || _photoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleMeterPhotoRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = VehiclesRepository(AppDatabase.processScope);
    final unit = repo.meterUnitForVehicle(v);
    final kind = VehicleKind.fromWire(v.vehicleKind);
    final unitLabel = kind?.usesHorometer ?? false ? 'h' : 'km';
    final latest = await repo.latestMeterValue(v.id);

    if (latest != null && parsed < latest) {
      if (vehicleContactIsOwnerSelf(widget.actingContactId)) {
        if (!mounted) return;
        final choice = await showNegativeGapDialog(
          context,
          gapAmount: parsed - latest,
          unitLabel: unitLabel,
        );
        if (!mounted) return;
        if (choice != NegativeGapChoice.maintain) {
          setState(() => _saving = false);
          return;
        }
      }
    }

    if (latest != null && parsed > latest && _openUse == null) {
      final ownerLinks = await repo.listActiveLinksAsOwner();
      final borrowerIds = ownerLinks
          .where((VehicleSharingLink l) => l.vehicleId == v.id)
          .map((VehicleSharingLink l) => l.borrowerContactId)
          .toList();
      final contacts = await ContactsRepository(AppDatabase.processScope).list();
      final labels = {
        for (final c in contacts) c.id: c.displayName,
      };
      if (!mounted) return;
      final attributed = await showPositiveGapAttributionDialog(
        context,
        gapAmount: parsed - latest,
        unitLabel: unitLabel,
        participants: gapAttributionParticipants(
          l10n: l10n,
          actingContactId: widget.actingContactId,
          ownerContactId: v.ownerContactId,
          activeBorrowerContactIds: borrowerIds,
          contactLabels: labels,
        ),
      );
      if (!mounted || attributed == null) {
        setState(() => _saving = false);
        return;
      }
      await repo.recordPositiveGap(
        vehicleId: v.id,
        latestBefore: latest,
        startAfter: parsed,
        attributedContactId: attributed,
        recordedByContactId: widget.actingContactId,
      );
      if (gapRequiresOwnerNotification(
        attributedContactId: attributed,
        recordedByContactId: widget.actingContactId,
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
      recordedByContactId: widget.actingContactId,
      role: _openUse == null
          ? MeterReadingRole.sessionStart
          : MeterReadingRole.sessionEnd,
      negativeGapAcknowledged:
          latest != null && parsed < latest,
    );

    if (_openUse == null) {
      await repo.openUseSession(
        vehicleId: v.id,
        attributedContactId: widget.actingContactId,
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
      useId: _openUse!.id,
      endReadingId: reading.id,
    );
    if (!mounted) return;
    if (widget.forwardToOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleSharingForwarded)),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = _vehicle;
    final kind = VehicleKind.fromWire(v?.vehicleKind);
    final meterLabel = kind?.usesHorometer ?? false
        ? l10n.vehicleHorometerLabel
        : l10n.vehicleOdometerLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _openUse == null
              ? l10n.vehicleUseSessionStart
              : l10n.vehicleUseSessionEnd,
        ),
      ),
      body: _loading || v == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: screenBodyScrollPadding(context),
              children: [
                Text(v.displayLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _reading,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: meterLabel),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _photoPath == null
                        ? l10n.vehicleMeterPhotoAdd
                        : l10n.vehicleMeterPhotoAttached,
                  ),
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
}
