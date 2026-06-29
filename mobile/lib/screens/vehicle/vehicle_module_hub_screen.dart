import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../vehicle/vehicle_consumption_metrics.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_maintenance_categories.dart';
import '../../vehicle/vehicle_maintenance_alerts.dart';
import '../../vehicle/vehicle_module_access.dart';
import '../../vehicle/vehicle_module_exit.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleModuleHubScreen extends StatefulWidget {
  const VehicleModuleHubScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<VehicleModuleHubScreen> createState() =>
      _VehicleModuleHubScreenState();
}

class _VehicleModuleHubScreenState extends State<VehicleModuleHubScreen> {
  final _access = const VehicleModuleAccess();
  late final VehiclesRepository _repo =
      VehiclesRepository(AppDatabase.processScope);
  List<Vehicle> _vehicles = const [];
  VehicleUse? _openUse;
  bool _loading = true;
  int _cardReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final vehicles = await _repo.listOwnedVehicles();
    final openUse = await _repo.findAnyOpenUse();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _openUse = openUse;
      _loading = false;
      _cardReloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_access.hasVehicleEntitlement) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeModuleVehicle)),
        body: Center(child: Text(l10n.vehicleLicensingRequired)),
      );
    }
    final dateFmt = effectiveDateFormat(widget.prefs);
    final sessionStartedLine = _openUse == null
        ? null
        : l10n.vehicleUseSessionStartedOn(
            formatPreferenceDateTime(_openUse!.startedAt, dateFmt),
          );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => exitVehicleModule(context)),
        title: Text(l10n.homeModuleVehicle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.vehicleStatisticsTitle,
            onPressed: () => context.push('/vehicle/statistics'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/vehicle/add');
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.vehicleAddVehicle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: screenBodyScrollPadding(context),
                children: [
                  Text(
                    l10n.vehicleQuickActionsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _QuickActionsRow(
                    sessionPrimaryLabel: _openUse == null
                        ? l10n.vehicleUseSessionStartAction
                        : l10n.vehicleUseSessionEndAction,
                    sessionSecondaryLine: sessionStartedLine,
                    onSession: () => _launchQuickAction('odometer'),
                    onFuel: () => _launchQuickAction('fuel'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.vehicleMyVehiclesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_vehicles.isEmpty)
                    Text(
                      l10n.vehicleMyVehiclesEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ..._vehicles.map(
                      (v) => _VehicleCard(
                        key: ValueKey('${v.id}-$_cardReloadToken'),
                        vehicle: v,
                        repo: _repo,
                        onTap: () async {
                          await context.push('/vehicle/${v.id}');
                          _reload();
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _launchQuickAction(String kind) async {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).vehicleAddFirst)),
      );
      return;
    }
    final path = switch (kind) {
      'odometer' => _openUse == null
          ? '/vehicle/use-session'
          : '/vehicle/use-session?vehicleId=${Uri.encodeComponent(_openUse!.vehicleId)}',
      'fuel' => '/vehicle/fuel-purchase',
      _ => '/vehicle',
    };
    await context.push(path);
    _reload();
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.sessionPrimaryLabel,
    required this.sessionSecondaryLine,
    required this.onSession,
    required this.onFuel,
  });

  final String sessionPrimaryLabel;
  final String? sessionSecondaryLine;
  final VoidCallback onSession;
  final VoidCallback onFuel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.speed_outlined, size: 18),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sessionPrimaryLabel),
              if (sessionSecondaryLine != null)
                Text(
                  sessionSecondaryLine!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          onPressed: onSession,
        ),
        ActionChip(
          avatar: const Icon(Icons.local_gas_station_outlined, size: 18),
          label: Text(l10n.vehicleQuickActionFuel),
          onPressed: onFuel,
        ),
      ],
    );
  }
}

class _VehicleCard extends StatefulWidget {
  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.repo,
    required this.onTap,
  });

  final Vehicle vehicle;
  final VehiclesRepository repo;
  final VoidCallback onTap;

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  late Future<_VehicleCardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  void didUpdateWidget(covariant _VehicleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id != widget.vehicle.id ||
        oldWidget.repo != widget.repo) {
      _dataFuture = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VehicleCardData>(
      future: _dataFuture,
      builder: (context, snap) {
        final data = snap.data;
        final l10n = AppLocalizations.of(context);
        final kind = VehicleKind.fromWire(widget.vehicle.vehicleKind);
        final meterLabel = kind?.usesHorometer ?? false
            ? l10n.vehicleHorometerLabel
            : l10n.vehicleOdometerLabel;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (snap.hasError)
                    const SizedBox.shrink()
                  else if (data != null) ...[
                    Text(
                      '$meterLabel: ${data.meterDisplay}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (data.consumptionLabel(l10n).isNotEmpty)
                      Text(
                        data.consumptionLabel(l10n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (data.alerts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: data.alerts
                            .map(
                              (a) => Chip(
                                backgroundColor: a.isDueNow
                                    ? Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                    : Colors.orange.shade100,
                                label: Text(
                                  l10n.vehicleMaintenanceAlertTile(
                                    vehicleMaintenanceCategoryLabel(
                                      l10n,
                                      a.category,
                                    ),
                                    a.remainingAmount,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ] else
                    const SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_VehicleCardData> _load() async {
    final kind = VehicleKind.fromWire(widget.vehicle.vehicleKind);
    final meter =
        await widget.repo.latestMeterValue(widget.vehicle.id) ?? 0;
    final meterDisplay = kind?.usesHorometer ?? false
        ? '${(meter / 10).toStringAsFixed(1)} h'
        : '$meter km';
    try {
      final metrics = VehicleConsumptionMetrics(AppDatabase.processScope);
      final consumption = await metrics.forVehicle(widget.vehicle.id);
      final alerts = await VehicleMaintenanceAlerts(AppDatabase.processScope)
          .alertsForVehicle(widget.vehicle.id, currentMeter: meter);
      return _VehicleCardData(
        meterDisplay: meterDisplay,
        consumption: consumption,
        alerts: alerts,
        kind: kind,
      );
    } catch (_) {
      return _VehicleCardData(
        meterDisplay: meterDisplay,
        consumption: const VehicleConsumptionSnapshot(hasSufficientData: false),
        alerts: const [],
        kind: kind,
      );
    }
  }
}

class _VehicleCardData {
  const _VehicleCardData({
    required this.meterDisplay,
    required this.consumption,
    required this.alerts,
    required this.kind,
  });

  final String meterDisplay;
  final VehicleConsumptionSnapshot consumption;
  final List<VehicleMaintenanceAlert> alerts;
  final VehicleKind? kind;

  String consumptionLabel(AppLocalizations l10n) {
    if (!consumption.hasSufficientData) {
      return '';
    }
    if (kind?.usesHorometer ?? false) {
      final v = consumption.litersPerHour;
      if (v == null) return '';
      return l10n.vehicleConsumptionPerHour(v.toStringAsFixed(2));
    }
    final v = consumption.litersPer100Km;
    if (v == null) return '';
    return l10n.vehicleConsumptionPer100Km(v.toStringAsFixed(1));
  }
}
