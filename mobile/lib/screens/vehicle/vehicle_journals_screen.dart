import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_body_padding.dart';

enum _VehicleJournalKind { meter, fuel, maintenance, violation }

class VehicleJournalsScreen extends StatefulWidget {
  const VehicleJournalsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleJournalsScreen> createState() => _VehicleJournalsScreenState();
}

class _VehicleJournalsScreenState extends State<VehicleJournalsScreen> {
  _VehicleJournalKind _kind = _VehicleJournalKind.meter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleJournalsTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<_VehicleJournalKind>(
              key: ValueKey(_kind),
              isExpanded: true,
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: l10n.vehicleJournalSelectorLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: _VehicleJournalKind.meter,
                  child: Text(l10n.vehicleLogMeterTitle),
                ),
                DropdownMenuItem(
                  value: _VehicleJournalKind.fuel,
                  child: Text(l10n.vehicleLogFuelTitle),
                ),
                DropdownMenuItem(
                  value: _VehicleJournalKind.maintenance,
                  child: Text(l10n.vehicleLogMaintenanceTitle),
                ),
                DropdownMenuItem(
                  value: _VehicleJournalKind.violation,
                  child: Text(l10n.vehicleLogViolationTitle),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _kind = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_kind) {
              _VehicleJournalKind.meter => _MeterJournalList(
                  vehicleId: widget.vehicleId,
                ),
              _VehicleJournalKind.fuel => _FuelJournalList(
                  vehicleId: widget.vehicleId,
                ),
              _VehicleJournalKind.maintenance => _MaintenanceJournalList(
                  vehicleId: widget.vehicleId,
                ),
              _VehicleJournalKind.violation => _ViolationJournalList(
                  vehicleId: widget.vehicleId,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _MeterJournalList extends StatelessWidget {
  const _MeterJournalList({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<VehicleMeterReading>>(
      future: VehiclesRepository(AppDatabase.processScope)
          .listMeterReadings(vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l10n.vehicleJournalEmpty));
        }
        return ListView.separated(
          padding: screenBodyScrollPadding(context),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            final date = DateFormat.yMMMd().add_Hm().format(
                  row.recordedAt.toLocal(),
                );
            return ListTile(
              title: Text('${row.value}'),
              subtitle: Text(date),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/vehicle/$vehicleId/meter-log/${row.id}',
              ),
            );
          },
        );
      },
    );
  }
}

class _FuelJournalList extends StatelessWidget {
  const _FuelJournalList({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<FuelPurchase>>(
      future: VehiclesRepository(AppDatabase.processScope)
          .listFuelPurchases(vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l10n.vehicleJournalEmpty));
        }
        return ListView.separated(
          padding: screenBodyScrollPadding(context),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            final date = DateFormat.yMMMd().add_Hm().format(
                  row.purchasedAt.toLocal(),
                );
            return ListTile(
              title: Text('${row.costMinor / 100} ${row.currency}'),
              subtitle: Text(date),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/vehicle/$vehicleId/fuel-log/${row.id}',
              ),
            );
          },
        );
      },
    );
  }
}

class _MaintenanceJournalList extends StatelessWidget {
  const _MaintenanceJournalList({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<MaintenanceEvent>>(
      future: VehiclesRepository(AppDatabase.processScope)
          .listMaintenanceEvents(vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l10n.vehicleJournalEmpty));
        }
        return ListView.separated(
          padding: screenBodyScrollPadding(context),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            final date = DateFormat.yMMMd().add_Hm().format(
                  row.servicedAt.toLocal(),
                );
            return ListTile(
              title: Text(row.category),
              subtitle: Text(date),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/vehicle/$vehicleId/maintenance-log/${row.id}',
              ),
            );
          },
        );
      },
    );
  }
}

class _ViolationJournalList extends StatelessWidget {
  const _ViolationJournalList({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<TrafficViolation>>(
      future: VehiclesRepository(AppDatabase.processScope)
          .listViolations(vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(child: Text(l10n.vehicleJournalEmpty));
        }
        return ListView.separated(
          padding: screenBodyScrollPadding(context),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            final date = DateFormat.yMMMd().add_Hm().format(
                  row.violatedAt.toLocal(),
                );
            return ListTile(
              title: Text(row.violationType),
              subtitle: Text(date),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/vehicle/$vehicleId/violation-log/${row.id}',
              ),
            );
          },
        );
      },
    );
  }
}
