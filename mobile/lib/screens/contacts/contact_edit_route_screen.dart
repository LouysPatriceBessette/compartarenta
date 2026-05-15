import 'package:flutter/material.dart';

import '../../contacts/contact_display.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import 'contact_editor_screen.dart';
import 'contact_label_editor_screen.dart';

/// Routes `/contacts/:id/edit` to the label editor for connected / disconnected
/// peers, or the legacy full editor for other local-only rows.
class ContactEditRouteScreen extends StatefulWidget {
  const ContactEditRouteScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactEditRouteScreen> createState() => _ContactEditRouteScreenState();
}

class _ContactEditRouteScreenState extends State<ContactEditRouteScreen> {
  AppDatabase get _db => AppDatabase.processScope;
  late final ContactsRepository _repo = ContactsRepository(_db);
  Future<Contact?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.get(widget.contactId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Contact?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final c = snapshot.data;
        if (c == null) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.contactsEditTitle)),
            body: Center(child: Text(l10n.contactsDetailMissing)),
          );
        }
        final useLabelEditor =
            c.kind == 'connected' || c.showsDisconnectedStatus;
        if (useLabelEditor) {
          return ContactLabelEditorScreen(contactId: widget.contactId);
        }
        return ContactEditorScreen(contactId: widget.contactId);
      },
    );
  }
}
