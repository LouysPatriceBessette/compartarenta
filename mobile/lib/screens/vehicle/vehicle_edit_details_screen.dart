import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/display_units.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_oil_change_interval.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/vehicle_narrow_unit_field.dart';
import 'vehicle_add_gallery_section.dart';

class VehicleEditDetailsScreen extends StatefulWidget {
  const VehicleEditDetailsScreen({
    super.key,
    required this.vehicleId,
    required this.prefs,
  });

  final String vehicleId;
  final AppPreferences prefs;

  @override
  State<VehicleEditDetailsScreen> createState() =>
      _VehicleEditDetailsScreenState();
}

class _VehicleEditDetailsScreenState extends State<VehicleEditDetailsScreen> {
  final _displayLabel = TextEditingController();
  final _color = TextEditingController();
  final _oilChangeInterval = TextEditingController();
  final _oilChangeIntervalFocus = FocusNode();
  final _licensePlate = TextEditingController();
  final _newGalleries = <VehicleGalleryDraft>[];
  bool _loading = true;
  bool _saving = false;
  bool _oilChangeIntervalBlurred = false;
  bool _usesHorometer = false;

  @override
  void initState() {
    super.initState();
    _oilChangeIntervalFocus.addListener(_onOilChangeIntervalFocus);
    _displayLabel.addListener(_refresh);
    _color.addListener(_refresh);
    _oilChangeInterval.addListener(_refresh);
    _load();
  }

  void _onOilChangeIntervalFocus() {
    if (!_oilChangeIntervalFocus.hasFocus && mounted) {
      setState(() => _oilChangeIntervalBlurred = true);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _oilChangeIntervalFocus
      ..removeListener(_onOilChangeIntervalFocus)
      ..dispose();
    _displayLabel.dispose();
    _color.dispose();
    _oilChangeInterval.dispose();
    _licensePlate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final vehicle = await repo.getVehicle(widget.vehicleId);
    final interval = await repo.oilChangeIntervalAmountForVehicle(
      widget.vehicleId,
    );
    if (!mounted) return;
    final kind = VehicleKind.fromWire(vehicle?.vehicleKind);
    final usesHorometer = kind?.usesHorometer ?? false;
    final distanceUnit = resolveDistanceUnit(widget.prefs);
    setState(() {
      _displayLabel.text = vehicle?.displayLabel ?? '';
      _color.text = vehicle?.color ?? '';
      _licensePlate.text = vehicle?.licensePlate ?? '';
      _usesHorometer = usesHorometer;
      if (interval != null) {
        _oilChangeInterval.text = formatOilChangeIntervalForDisplay(
          storedTenths: interval,
          usesHorometer: usesHorometer,
          distanceUnit: distanceUnit,
        );
      }
      _loading = false;
    });
  }

  int? get _parsedOilChangeInterval => parseOilChangeIntervalToStoredTenths(
        text: _oilChangeInterval.text,
        usesHorometer: _usesHorometer,
        distanceUnit: resolveDistanceUnit(widget.prefs),
      );

  String? _oilChangeIntervalError(AppLocalizations l10n) {
    if (!_oilChangeIntervalBlurred) return null;
    final issue = oilChangeIntervalValidationIssue(
      text: _oilChangeInterval.text,
      usesHorometer: _usesHorometer,
    );
    return switch (issue) {
      OilChangeIntervalValidationIssue.empty =>
        l10n.vehicleOilChangeIntervalRequired,
      OilChangeIntervalValidationIssue.invalid =>
        l10n.vehicleOilChangeIntervalInvalid,
      OilChangeIntervalValidationIssue.landBelowMin =>
        l10n.vehicleOilChangeIntervalLandMin,
      OilChangeIntervalValidationIssue.landAboveMax =>
        l10n.vehicleOilChangeIntervalLandMax,
      OilChangeIntervalValidationIssue.boatBelowMin =>
        l10n.vehicleOilChangeIntervalBoatMin,
      OilChangeIntervalValidationIssue.boatAboveMax =>
        l10n.vehicleOilChangeIntervalBoatMax,
      null => null,
    };
  }

  bool get _canSave {
    if (_saving || _loading) return false;
    if (_displayLabel.text.trim().isEmpty) return false;
    if (_color.text.trim().isEmpty) return false;
    if (_parsedOilChangeInterval == null) return false;
    return true;
  }

  String _todayGalleryTitle() => formatPreferenceDate(
        DateTime.now().toUtc(),
        effectiveDateFormat(widget.prefs),
      );

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = VehiclesRepository(AppDatabase.processScope);
    await repo.updateVehicleEditableDetails(
      vehicleId: widget.vehicleId,
      displayLabel: _displayLabel.text.trim(),
      color: _color.text.trim(),
      licensePlate: _licensePlate.text.trim(),
      oilChangeIntervalAmount: _parsedOilChangeInterval!,
    );
    final drafts =
        _newGalleries.where((g) => g.photos.isNotEmpty).toList();
    if (drafts.isNotEmpty) {
      await repo.addGalleryDrafts(widget.vehicleId, drafts);
    }
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.vehicleEditDetailsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final distanceUnit = resolveDistanceUnit(widget.prefs);
    final oilIntervalUnit = oilChangeIntervalUnitSuffix(
      usesHorometer: _usesHorometer,
      distanceUnit: distanceUnit,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleEditDetailsTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          AppTextField(
            controller: _displayLabel,
            decoration: InputDecoration(labelText: l10n.vehicleFieldLabel),
            onChanged: (_) => _refresh(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _color,
            decoration: InputDecoration(labelText: l10n.vehicleFieldColor),
            onChanged: (_) => _refresh(),
          ),
          const SizedBox(height: 12),
          VehicleNarrowUnitField(
            controller: _oilChangeInterval,
            focusNode: _oilChangeIntervalFocus,
            label: l10n.vehicleFieldFluidChangeFrequency,
            unitSuffix: oilIntervalUnit,
            allowDecimalWithoutDecimalKeyboard: !_usesHorometer,
            errorText: _oilChangeIntervalError(l10n),
            onChanged: (_) => _refresh(),
            onEditingComplete: () =>
                setState(() => _oilChangeIntervalBlurred = true),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _licensePlate,
            decoration: InputDecoration(
              labelText: l10n.vehicleFieldLicensePlate,
              helperText: l10n.vehicleFieldOptional,
            ),
          ),
          const SizedBox(height: 24),
          VehicleAddGallerySection(
            galleries: _newGalleries,
            showSectionHeader: false,
            startGalleryButtonLabel: l10n.vehicleAddPhotoGalleryStart,
            allowAddAnotherGallery: false,
            newGalleryTitle: _todayGalleryTitle,
            onChanged: () => setState(() {}),
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
