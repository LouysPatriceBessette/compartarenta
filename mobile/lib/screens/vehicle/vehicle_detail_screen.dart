import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_consumption_metrics.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_module_access.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;

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
    final kind = VehicleKind.fromWire(v.vehicleKind);
    final access = const VehicleModuleAccess();
    return Scaffold(
      appBar: AppBar(title: Text(v.displayLabel)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          ListTile(
            title: Text(l10n.vehicleFieldKind),
            subtitle: Text(_kindLabel(l10n, kind)),
          ),
          if (access.canOfferSharing)
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: Text(l10n.vehicleSharingOffer),
              onTap: () => context.push(
                '/vehicle-sharing/offer?vehicleId=${Uri.encodeComponent(v.id)}',
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(l10n.vehicleQuickActionOdometer),
            onTap: () => context.push('/vehicle/${v.id}/use'),
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station_outlined),
            title: Text(l10n.vehicleQuickActionFuel),
            onTap: () => context.push('/vehicle/${v.id}/fuel'),
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
          FutureBuilder<VehicleConsumptionSnapshot>(
            future: VehicleConsumptionMetrics(AppDatabase.processScope)
                .forVehicle(v.id),
            builder: (context, snap) {
              final c = snap.data;
              if (c == null) return const SizedBox.shrink();
              return ListTile(
                title: Text(l10n.vehicleConsumptionTitle),
                subtitle: Text(
                  c.hasSufficientData
                      ? (kind?.usesHorometer ?? false
                          ? l10n.vehicleConsumptionPerHour(
                              c.litersPerHour!.toStringAsFixed(2),
                            )
                          : l10n.vehicleConsumptionPer100Km(
                              c.litersPer100Km!.toStringAsFixed(1),
                            ))
                      : l10n.vehicleConsumptionInsufficient,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _kindLabel(AppLocalizations l10n, VehicleKind? k) => switch (k) {
        VehicleKind.car => l10n.vehicleKindCar,
        VehicleKind.truck => l10n.vehicleKindTruck,
        VehicleKind.motorcycle => l10n.vehicleKindMotorcycle,
        VehicleKind.boat => l10n.vehicleKindBoat,
        null => '',
      };
}
