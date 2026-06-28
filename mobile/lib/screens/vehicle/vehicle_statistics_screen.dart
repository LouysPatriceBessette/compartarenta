import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../vehicle/vehicle_consumption_metrics.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleStatisticsScreen extends StatefulWidget {
  const VehicleStatisticsScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<VehicleStatisticsScreen> createState() =>
      _VehicleStatisticsScreenState();
}

class _VehicleStatisticsScreenState extends State<VehicleStatisticsScreen> {
  List<Vehicle> _vehicles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles =
        await VehiclesRepository(AppDatabase.processScope).listOwnedVehicles();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = VehicleConsumptionMetrics(AppDatabase.processScope);
    final repo = VehiclesRepository(AppDatabase.processScope);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleStatisticsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: screenBodyScrollPadding(context),
              children: [
                Text(
                  l10n.vehicleStatisticsMileageTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_vehicles.isEmpty)
                  Text(l10n.vehicleMyVehiclesEmpty)
                else
                  ..._vehicles.map((v) {
                    return FutureBuilder<int>(
                      future: metrics.totalLifetimeUsage(v.id),
                      builder: (context, snap) {
                        final kind = VehicleKind.fromWire(v.vehicleKind);
                        final total = snap.data;
                        final display = total == null
                            ? '…'
                            : kind?.usesHorometer ?? false
                                ? '${(total / 10).toStringAsFixed(1)} h'
                                : '$total km';
                        return ListTile(
                          title: Text(v.displayLabel),
                          subtitle: Text(display),
                        );
                      },
                    );
                  }),
                const Divider(height: 32),
                Text(
                  l10n.vehicleStatisticsExpensesTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._vehicles.map((v) {
                  return FutureBuilder<_ExpenseTotals>(
                    future: _expenseTotals(repo, v.id),
                    builder: (context, snap) {
                      final t = snap.data;
                      if (t == null) {
                        return ListTile(title: Text(v.displayLabel));
                      }
                      return ListTile(
                        title: Text(v.displayLabel),
                        subtitle: Text(
                          '${l10n.vehicleExpenseFuel}: ${t.fuel}\n'
                          '${l10n.vehicleExpenseMaintenance}: ${t.maintenance}\n'
                          '${l10n.vehicleExpenseViolations}: ${t.violations}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                }),
              ],
            ),
    );
  }

  Future<_ExpenseTotals> _expenseTotals(
    VehiclesRepository repo,
    String vehicleId,
  ) async {
    final fuel = await repo.listFuelPurchases(vehicleId);
    final maint = await repo.listMaintenanceEvents(vehicleId);
    final viol = await repo.listViolations(vehicleId);
    var sumFuel = 0;
    for (final f in fuel) {
      sumFuel += f.costMinor;
    }
    var sumMaint = 0;
    for (final m in maint) {
      sumMaint += m.costMinor;
    }
    var sumViol = 0;
    for (final v in viol) {
      sumViol += v.amountMinor;
    }
    return _ExpenseTotals(
      fuel: (sumFuel / 100).toStringAsFixed(2),
      maintenance: (sumMaint / 100).toStringAsFixed(2),
      violations: (sumViol / 100).toStringAsFixed(2),
    );
  }
}

class _ExpenseTotals {
  const _ExpenseTotals({
    required this.fuel,
    required this.maintenance,
    required this.violations,
  });

  final String fuel;
  final String maintenance;
  final String violations;
}
