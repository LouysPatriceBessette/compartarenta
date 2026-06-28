import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_module_access.dart';
import '../../widgets/screen_body_padding.dart';

class VehicleSharingOfferScreen extends StatefulWidget {
  const VehicleSharingOfferScreen({
    super.key,
    required this.vehicleId,
  });

  final String vehicleId;

  @override
  State<VehicleSharingOfferScreen> createState() =>
      _VehicleSharingOfferScreenState();
}

class _VehicleSharingOfferScreenState extends State<VehicleSharingOfferScreen> {
  List<Contact> _contacts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await ContactsRepository(AppDatabase.processScope).list();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _offer(String contactId) async {
    final access = const VehicleModuleAccess();
    final l10n = AppLocalizations.of(context);
    if (!access.canOfferSharing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleSharingOfferBlocked)),
      );
      return;
    }
    await VehiclesRepository(AppDatabase.processScope).createSharingOffer(
      vehicleId: widget.vehicleId,
      borrowerContactId: contactId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.vehicleSharingOfferSent)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleSharingOffer)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: screenBodyScrollPadding(context),
              children: [
                Text(l10n.vehicleSharingOfferPickContact),
                const SizedBox(height: 8),
                if (_contacts.isEmpty)
                  Text(l10n.vehicleSharingNoContacts)
                else
                  ..._contacts.map(
                    (c) => ListTile(
                      title: Text(c.displayName),
                      onTap: () => _offer(c.id),
                    ),
                  ),
              ],
            ),
    );
  }
}
