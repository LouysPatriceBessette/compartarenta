import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../debug/qa_vehicle_semantics.dart';
import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../widgets/screen_body_padding.dart';
import 'vehicle_detail_gallery.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.prefs,
  });

  final String vehicleId;
  final AppPreferences prefs;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;
  int _galleryReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await VehiclesRepository(AppDatabase.processScope)
        .getVehicle(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _vehicle = v;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final updated = await context.push<bool>(
      '/vehicle/${widget.vehicleId}/edit',
    );
    if (updated == true) {
      await _load();
      setState(() => _galleryReloadToken++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = _vehicle;
    if (_loading || v == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final summary = vehicleModelColorSummary(l10n, v);
    final dateFmt = effectiveDateFormat(widget.prefs);
    return Scaffold(
      appBar: AppBar(title: Text(v.displayLabel)),
      body: qaVehicleSemantics(
        identifier: kQaVehicleDetail,
        child: ListView(
          padding: screenBodyScrollPadding(context),
          children: [
          if (summary.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _openEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.vehicleEditDetailsTitle,
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.vehicleEditDetailsTitle,
              ),
            ),
          qaVehicleSemantics(
            identifier: kQaVehicleDetailOdometerReading,
            child: ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(l10n.vehicleQuickActionOdometer),
              onTap: () => context.push('/vehicle/${v.id}/meter-reading'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(l10n.vehicleQuickActionMaintenance),
            onTap: () => context.push('/vehicle/${v.id}/maintenance'),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: Text(l10n.vehicleQuickActionViolation),
            onTap: () => context.push('/vehicle/${v.id}/violation'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.vehicleJournalsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/vehicle/${v.id}/journals'),
          ),
          const Divider(),
          VehicleDetailGalleryView(
            key: ValueKey('gallery-$_galleryReloadToken'),
            vehicleId: v.id,
            dateFormat: dateFmt,
          ),
        ],
        ),
      ),
    );
  }
}
