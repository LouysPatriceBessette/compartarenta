import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/screen_body_padding.dart';
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
  final _color = TextEditingController();
  final _licensePlate = TextEditingController();
  final _newGalleries = <VehicleGalleryDraft>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _color.dispose();
    _licensePlate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final vehicle = await repo.getVehicle(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _color.text = vehicle?.color ?? '';
      _licensePlate.text = vehicle?.licensePlate ?? '';
      _loading = false;
    });
  }

  bool get _canSave {
    if (_saving || _loading) return false;
    return _color.text.trim().isNotEmpty;
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
      color: _color.text.trim(),
      licensePlate: _licensePlate.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleEditDetailsTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          AppTextField(
            controller: _color,
            decoration: InputDecoration(labelText: l10n.vehicleFieldColor),
            onChanged: (_) => setState(() {}),
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
