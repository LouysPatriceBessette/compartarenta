import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_kind.dart';
import '../../vehicle/vehicle_stored_image.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleMeterLogScreen extends StatelessWidget {
  const VehicleMeterLogScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleLogMeterTitle)),
      body: FutureBuilder<List<VehicleMeterReading>>(
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
      ),
    );
  }
}

class VehicleMeterReadingDetailScreen extends StatelessWidget {
  const VehicleMeterReadingDetailScreen({
    super.key,
    required this.vehicleId,
    required this.readingId,
  });

  final String vehicleId;
  final String readingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<(Vehicle?, VehicleMeterReading?)>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogMeterDetailTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final vehicle = snap.data!.$1;
        final reading = snap.data!.$2;
        if (vehicle == null || reading == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogMeterDetailTitle)),
            body: Center(child: Text(l10n.vehicleUsageBlockedVehicleNotFound)),
          );
        }
        final kind = VehicleKind.fromWire(vehicle.vehicleKind);
        final meterLabel = kind?.usesHorometer ?? false
            ? l10n.vehicleHorometerLabel
            : l10n.vehicleOdometerLabel;
        final date = DateFormat.yMMMd().add_Hm().format(
              reading.recordedAt.toLocal(),
            );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.vehicleLogMeterDetailTitle)),
          body: ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              ListTile(
                title: Text(meterLabel),
                subtitle: Text('${reading.value}'),
              ),
              ListTile(
                title: Text(l10n.vehicleLogRecordedAt),
                subtitle: Text(date),
              ),
              ListTile(
                title: Text(l10n.vehicleLogReadingRole),
                subtitle: Text(reading.readingRole),
              ),
              if (reading.photoPath.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.vehicleOdometerPhotoLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: VehicleStoredImage(path: reading.photoPath),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<(Vehicle?, VehicleMeterReading?)> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final vehicle = await repo.getVehicle(vehicleId);
    final reading = await repo.getMeterReading(readingId);
    return (vehicle, reading);
  }
}

class VehicleFuelLogScreen extends StatelessWidget {
  const VehicleFuelLogScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleLogFuelTitle)),
      body: FutureBuilder<List<FuelPurchase>>(
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
      ),
    );
  }
}

class VehicleFuelPurchaseDetailScreen extends StatelessWidget {
  const VehicleFuelPurchaseDetailScreen({
    super.key,
    required this.vehicleId,
    required this.purchaseId,
  });

  final String vehicleId;
  final String purchaseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<FuelPurchase?>(
      future: VehiclesRepository(AppDatabase.processScope)
          .getFuelPurchase(purchaseId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogFuelDetailTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final row = snap.data;
        if (row == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogFuelDetailTitle)),
            body: Center(child: Text(l10n.vehicleUsageBlockedVehicleNotFound)),
          );
        }
        final date = DateFormat.yMMMd().add_Hm().format(row.purchasedAt.toLocal());
        return Scaffold(
          appBar: AppBar(title: Text(l10n.vehicleLogFuelDetailTitle)),
          body: ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              ListTile(
                title: Text(l10n.vehicleFuelCost),
                subtitle: Text('${row.costMinor / 100} ${row.currency}'),
              ),
              ListTile(
                title: Text(l10n.vehicleLogRecordedAt),
                subtitle: Text(date),
              ),
              if (row.volumeLiters != null)
                ListTile(
                  title: Text(l10n.vehicleFuelVolume),
                  subtitle: Text('${row.volumeLiters}'),
                ),
              if (row.meterReadingValue != null)
                ListTile(
                  title: Text(l10n.vehicleFuelMeter),
                  subtitle: Text('${row.meterReadingValue}'),
                ),
              ListTile(
                title: Text(l10n.vehicleFuelFullTank),
                subtitle: Text(row.isFullTank ? l10n.commonYes : l10n.commonNo),
              ),
              if (row.meterPhotoPath != null && row.meterPhotoPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: VehicleStoredImage(path: row.meterPhotoPath!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class VehicleMaintenanceLogScreen extends StatelessWidget {
  const VehicleMaintenanceLogScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleLogMaintenanceTitle)),
      body: FutureBuilder<List<MaintenanceEvent>>(
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
      ),
    );
  }
}

class VehicleMaintenanceDetailScreen extends StatelessWidget {
  const VehicleMaintenanceDetailScreen({
    super.key,
    required this.vehicleId,
    required this.eventId,
  });

  final String vehicleId;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<MaintenanceEvent?>(
      future: VehiclesRepository(AppDatabase.processScope)
          .getMaintenanceEvent(eventId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogMaintenanceDetailTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final row = snap.data;
        if (row == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogMaintenanceDetailTitle)),
            body: Center(child: Text(l10n.vehicleUsageBlockedVehicleNotFound)),
          );
        }
        final date = DateFormat.yMMMd().add_Hm().format(row.servicedAt.toLocal());
        return Scaffold(
          appBar: AppBar(title: Text(l10n.vehicleLogMaintenanceDetailTitle)),
          body: ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              ListTile(
                title: Text(l10n.vehicleMaintenanceCategory),
                subtitle: Text(row.category),
              ),
              ListTile(
                title: Text(l10n.vehicleMaintenanceCost),
                subtitle: Text('${row.costMinor / 100} ${row.currency}'),
              ),
              ListTile(
                title: Text(l10n.vehicleLogRecordedAt),
                subtitle: Text(date),
              ),
              if (row.meterAtService != null)
                ListTile(
                  title: Text(l10n.vehicleFuelMeter),
                  subtitle: Text('${row.meterAtService}'),
                ),
              if (row.notes.isNotEmpty)
                ListTile(
                  title: Text(l10n.vehicleMaintenanceNotes),
                  subtitle: Text(row.notes),
                ),
            ],
          ),
        );
      },
    );
  }
}

class VehicleViolationLogScreen extends StatelessWidget {
  const VehicleViolationLogScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleLogViolationTitle)),
      body: FutureBuilder<List<TrafficViolation>>(
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
      ),
    );
  }
}

class VehicleViolationDetailScreen extends StatelessWidget {
  const VehicleViolationDetailScreen({
    super.key,
    required this.vehicleId,
    required this.violationId,
  });

  final String vehicleId;
  final String violationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<TrafficViolation?>(
      future: VehiclesRepository(AppDatabase.processScope)
          .getTrafficViolation(violationId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogViolationDetailTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final row = snap.data;
        if (row == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.vehicleLogViolationDetailTitle)),
            body: Center(child: Text(l10n.vehicleUsageBlockedVehicleNotFound)),
          );
        }
        final date = DateFormat.yMMMd().add_Hm().format(row.violatedAt.toLocal());
        return Scaffold(
          appBar: AppBar(title: Text(l10n.vehicleLogViolationDetailTitle)),
          body: ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              ListTile(
                title: Text(l10n.vehicleViolationType),
                subtitle: Text(row.violationType),
              ),
              ListTile(
                title: Text(l10n.vehicleViolationAmount),
                subtitle: Text('${row.amountMinor / 100} ${row.currency}'),
              ),
              ListTile(
                title: Text(l10n.vehicleLogRecordedAt),
                subtitle: Text(date),
              ),
              if (row.notes.isNotEmpty)
                ListTile(
                  title: Text(l10n.vehicleMaintenanceNotes),
                  subtitle: Text(row.notes),
                ),
            ],
          ),
        );
      },
    );
  }
}
