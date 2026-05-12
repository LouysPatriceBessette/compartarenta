import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/contact_invitations_repository.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Outstanding-invitations list with status and revoke action.
class OutstandingInvitationsScreen extends StatefulWidget {
  const OutstandingInvitationsScreen({super.key});

  @override
  State<OutstandingInvitationsScreen> createState() =>
      _OutstandingInvitationsScreenState();
}

class _OutstandingInvitationsScreenState
    extends State<OutstandingInvitationsScreen> {
  late final AppDatabase _db = AppDatabase();
  late final ContactInvitationsRepository _repo =
      ContactInvitationsRepository(_db);

  Future<List<ContactInvitation>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _repo.listWithFreshStatus();
    });
  }

  Future<void> _revoke(String id) async {
    await _repo.revoke(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsInvitationsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.contactsInviteGenerateAction),
        onPressed: () =>
            context.push('/contacts/invite/new').then((_) => _reload()),
      ),
      body: FutureBuilder<List<ContactInvitation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const <ContactInvitation>[];
          if (all.isEmpty) {
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
          return ListView.separated(
            itemCount: all.length,
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final row = all[index];
              return ListTile(
                title: Text(
                  l10n.contactsInvitationsItemTitle(
                    row.createdAt.toLocal().toString(),
                  ),
                ),
                subtitle: Text(
                  '${_statusLabel(l10n, row.status)}'
                  ' · '
                  '${l10n.contactsInviteExpiresAt(row.expiresAt.toLocal().toString())}',
                ),
                trailing: row.status == 'pending'
                    ? IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: l10n.contactsInviteRevokeAction,
                        onPressed: () => _revoke(row.id),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.contactsInvitationsStatusPending;
      case 'used':
        return l10n.contactsInvitationsStatusUsed;
      case 'expired':
        return l10n.contactsInvitationsStatusExpired;
      case 'revoked':
        return l10n.contactsInvitationsStatusRevoked;
      default:
        return status;
    }
  }
}
