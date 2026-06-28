import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../vehicle/vehicle_consumption_metrics.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_maintenance_alerts.dart';
import '../../vehicle/vehicle_module_access.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final vehicles = await _repo.listOwnedVehicles();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _loading = false;
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
    return Scaffold(
      appBar: AppBar(
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
                    onOdometer: () => _launchQuickAction('odometer'),
                    onFuel: () => _launchQuickAction('fuel'),
                    onMaintenance: () => _launchQuickAction('maintenance'),
                    onViolation: () => _launchQuickAction('violation'),
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
    String? vehicleId = _vehicles.length == 1 ? _vehicles.first.id : null;
    vehicleId ??= await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in _vehicles)
              ListTile(
                title: Text(v.displayLabel),
                onTap: () => Navigator.pop(ctx, v.id),
              ),
          ],
        ),
      ),
    );
    if (vehicleId == null || !mounted) return;
    final path = switch (kind) {
      'odometer' => '/vehicle/$vehicleId/use',
      'fuel' => '/vehicle/$vehicleId/fuel',
      'maintenance' => '/vehicle/$vehicleId/maintenance',
      _ => '/vehicle/$vehicleId/violation',
    };
    await context.push(path);
    _reload();
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onOdometer,
    required this.onFuel,
    required this.onMaintenance,
    required this.onViolation,
  });

  final VoidCallback onOdometer;
  final VoidCallback onFuel;
  final VoidCallback onMaintenance;
  final VoidCallback onViolation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.speed_outlined, size: 18),
          label: Text(l10n.vehicleQuickActionOdometer),
          onPressed: onOdometer,
        ),
        ActionChip(
          avatar: const Icon(Icons.local_gas_station_outlined, size: 18),
          label: Text(l10n.vehicleQuickActionFuel),
          onPressed: onFuel,
        ),
        ActionChip(
          avatar: const Icon(Icons.build_outlined, size: 18),
          label: Text(l10n.vehicleQuickActionMaintenance),
          onPressed: onMaintenance,
        ),
        ActionChip(
          avatar: const Icon(Icons.report_outlined, size: 18),
          label: Text(l10n.vehicleQuickActionViolation),
          onPressed: onViolation,
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.repo,
    required this.onTap,
  });

  final Vehicle vehicle;
  final VehiclesRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VehicleCardData>(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        final l10n = AppLocalizations.of(context);
        final kind = VehicleKind.fromWire(vehicle.vehicleKind);
        final meterLabel = kind?.usesHorometer ?? false
            ? l10n.vehicleHorometerLabel
            : l10n.vehicleOdometerLabel;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (data != null) ...[
                    Text(
                      '$meterLabel: ${data.meterDisplay}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                                    a.category,
                                    a.remainingAmount,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ] else
                    const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_VehicleCardData> _load() async {
    final metrics = VehicleConsumptionMetrics(AppDatabase.processScope);
    final consumption = await metrics.forVehicle(vehicle.id);
    final meter = await repo.latestMeterValue(vehicle.id) ?? 0;
    final alerts = await VehicleMaintenanceAlerts(AppDatabase.processScope)
        .alertsForVehicle(vehicle.id, currentMeter: meter);
    final kind = VehicleKind.fromWire(vehicle.vehicleKind);
    final meterDisplay = kind?.usesHorometer ?? false
        ? '${(meter / 10).toStringAsFixed(1)} h'
        : '$meter km';
    return _VehicleCardData(
      meterDisplay: meterDisplay,
      consumption: consumption,
      alerts: alerts,
      kind: kind,
    );
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
      return l10n.vehicleConsumptionInsufficient;
    }
    if (kind?.usesHorometer ?? false) {
      final v = consumption.litersPerHour;
      if (v == null) return l10n.vehicleConsumptionInsufficient;
      return l10n.vehicleConsumptionPerHour(v.toStringAsFixed(2));
    }
    final v = consumption.litersPer100Km;
    if (v == null) return l10n.vehicleConsumptionInsufficient;
    return l10n.vehicleConsumptionPer100Km(v.toStringAsFixed(1));
  }
}
