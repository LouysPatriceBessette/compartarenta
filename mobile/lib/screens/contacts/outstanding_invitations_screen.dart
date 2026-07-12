import 'package:flutter/material.dart';

import '../../contacts/contact_invitations_repository.dart';
import '../../debug/qa_contact_semantics.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'contact_invitation_list_tile.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Sent invitations (pending / expired) with access to the shareable code.
class OutstandingInvitationsScreen extends StatefulWidget {
  const OutstandingInvitationsScreen({super.key});

  @override
  State<OutstandingInvitationsScreen> createState() =>
      _OutstandingInvitationsScreenState();
}

class _OutstandingInvitationsScreenState
    extends State<OutstandingInvitationsScreen> {
  AppDatabase get _db => AppDatabase.processScope;
  late final ContactInvitationsRepository _invitationsRepo =
      ContactInvitationsRepository(_db);
  late final ContactsRepository _contactsRepo = ContactsRepository(_db);

  Future<List<ContactInvitation>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _invitationsRepo.listWithFreshStatus();
    });
  }

  Future<void> _openInvitationCode(ContactInvitation invitation) async {
    navigateTo(context, '/contacts/invitations/code/${invitation.id}');
    if (!mounted) return;
    _reload();
  }

  Future<void> _deleteExpiredInvitation(ContactInvitation invitation) async {
    final stubId = invitation.contactStubId;
    if (stubId != null && stubId.isNotEmpty) {
      await _contactsRepo.deleteLocally(stubId);
    }
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: qaContactSemantics(
          identifier: kQaContactsInvitationsHub,
          label: l10n.contactsInvitationsTitle,
          header: true,
          child: Text(l10n.contactsInvitationsTitle),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.contactsAddContactAction),
        onPressed: () => navigateTo(context, '/contacts/invitations/new'),
      ),
      body: FutureBuilder<List<ContactInvitation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = sortSentInvitationsForList(snapshot.data ?? const []);
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.contactsInvitationsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return FutureBuilder<AppPreferences>(
            future: AppPreferences.load(),
            builder: (context, prefsSnap) {
              final dateFormat = prefsSnap.hasData
                  ? effectiveDateFormat(prefsSnap.data!)
                  : 'YYYY-MM-DD';
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final row = items[index];
                  return ContactInvitationListTile(
                    invitation: row,
                    dateFormat: dateFormat,
                    onOpenCode: () => _openInvitationCode(row),
                    onDeleteExpired: () => _deleteExpiredInvitation(row),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
