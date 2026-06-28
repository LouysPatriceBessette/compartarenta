import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../vehicle/vehicle_module_access.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleSharingHubScreen extends StatefulWidget {
  const VehicleSharingHubScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<VehicleSharingHubScreen> createState() =>
      _VehicleSharingHubScreenState();
}

class _VehicleSharingHubScreenState extends State<VehicleSharingHubScreen> {
  final _access = const VehicleModuleAccess();
  List<_AccessibleVehicleRow> _rows = const [];
  List<VehicleSharingLink> _pendingOffers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final contacts = await ContactsRepository(AppDatabase.processScope).list();
    final labels = {for (final c in contacts) c.id: c.displayName};

    final ownerLinks = await repo.listActiveLinksAsOwner();
    final ownerRows = <_AccessibleVehicleRow>[];
    for (final link in ownerLinks) {
      final v = await repo.getVehicle(link.vehicleId);
      if (v == null) continue;
      ownerRows.add(
        _AccessibleVehicleRow(
          vehicle: v,
          subtitle: labels[link.borrowerContactId] ?? link.borrowerContactId,
          isOwnerContext: true,
          borrowerContactId: link.borrowerContactId,
        ),
      );
    }

  // Borrower view: for dev, use first connected contact as borrower persona
    // when testing on one device — real PE uses installation-bound contact id.
    final borrowerContactId = contacts.isNotEmpty ? contacts.first.id : '';
    final borrowerVehicles = borrowerContactId.isEmpty
        ? <Vehicle>[]
        : await repo.listAccessibleVehiclesAsBorrower(borrowerContactId);
    final borrowerRows = <_AccessibleVehicleRow>[];
    for (final v in borrowerVehicles) {
      borrowerRows.add(
        _AccessibleVehicleRow(
          vehicle: v,
          subtitle: labels[v.ownerContactId] ?? v.ownerContactId,
          isOwnerContext: false,
          borrowerContactId: borrowerContactId,
        ),
      );
    }

    final pending = borrowerContactId.isEmpty
        ? <VehicleSharingLink>[]
        : await repo.listPendingOffersForBorrower(borrowerContactId);

    if (!mounted) return;
    setState(() {
      _rows = [...borrowerRows, ...ownerRows];
      _pendingOffers = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_access.hasVehicleSharingEntitlement) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeModuleVehicleSharing)),
        body: Center(child: Text(l10n.vehicleSharingLicensingRequired)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeModuleVehicleSharing)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: screenBodyScrollPadding(context),
                children: [
                  if (_pendingOffers.isNotEmpty) ...[
                    Text(
                      l10n.vehicleSharingPendingOffers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ..._pendingOffers.map(
                      (link) => ListTile(
                        title: Text(link.vehicleId),
                        trailing: FilledButton(
                          onPressed: () async {
                            await VehiclesRepository(AppDatabase.processScope)
                                .acceptSharingLink(link.id);
                            _reload();
                          },
                          child: Text(l10n.vehicleSharingAccept),
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  Text(
                    l10n.vehicleSharingAccessibleTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_rows.isEmpty)
                    Text(l10n.vehicleSharingAccessibleEmpty)
                  else
                    ..._rows.map((row) => _AccessibleCard(row: row, prefs: widget.prefs)),
                ],
              ),
            ),
    );
  }
}

class _AccessibleVehicleRow {
  const _AccessibleVehicleRow({
    required this.vehicle,
    required this.subtitle,
    required this.isOwnerContext,
    required this.borrowerContactId,
  });

  final Vehicle vehicle;
  final String subtitle;
  final bool isOwnerContext;
  final String borrowerContactId;
}

class _AccessibleCard extends StatelessWidget {
  const _AccessibleCard({required this.row, required this.prefs});

  final _AccessibleVehicleRow row;
  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = row.vehicle;
    final forward = !row.isOwnerContext;
    final actingId =
        forward ? row.borrowerContactId : v.ownerContactId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.displayLabel, style: Theme.of(context).textTheme.titleMedium),
            Text(
              row.isOwnerContext
                  ? l10n.vehicleSharingBorrowerLabel(row.subtitle)
                  : l10n.vehicleSharingOwnerLabel(row.subtitle),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text(l10n.vehicleQuickActionOdometer),
                  onPressed: () => context.push(
                    '/vehicle-sharing/${v.id}/use?acting=${Uri.encodeComponent(actingId)}&forward=$forward',
                  ),
                ),
                ActionChip(
                  label: Text(l10n.vehicleQuickActionFuel),
                  onPressed: () => context.push(
                    '/vehicle-sharing/${v.id}/fuel?acting=${Uri.encodeComponent(actingId)}&forward=$forward',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
