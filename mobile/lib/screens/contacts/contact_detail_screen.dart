import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../contacts/avatar_palette.dart';

/// Detail view for a Contact. Exposes edit, delete, and block actions.
///
/// Disconnect is intentionally NOT wired here yet: it requires the relay
/// to be live to send the disconnect envelope and is part of Wave B.
class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late final AppDatabase _db = AppDatabase();
  late final ContactsRepository _repo = ContactsRepository(_db);

  Future<Contact?>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _repo.get(widget.contactId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsDetailTitle)),
      body: FutureBuilder<Contact?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final contact = snapshot.data;
          if (contact == null) {
            return Center(child: Text(l10n.contactsDetailMissing));
          }
          return _ContactDetail(
            contact: contact,
            onEdit: () => context
                .push('/contacts/${contact.id}/edit')
                .then((_) => _reload()),
            onDelete: () => _confirmAndDelete(contact),
            onToggleBlock: () => _confirmAndToggleBlock(contact),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.contactsDeleteTitle),
        content: Text(l10n.contactsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteLocally(contact.id);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _confirmAndToggleBlock(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    final next = !contact.isBlocked;
    final title = next ? l10n.contactsBlockTitle : l10n.contactsUnblockTitle;
    final body = next ? l10n.contactsBlockBody : l10n.contactsUnblockBody;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(next ? l10n.commonBlock : l10n.commonUnblock),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.setBlocked(id: contact.id, blocked: next);
    _reload();
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleBlock,
  });

  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = contact.kind == 'connected';
    final blocked = contact.isBlocked;
    final deleted = contact.deletedAt != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                AvatarPalette.iconFor(contact.avatarId),
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          connected
                              ? l10n.contactsKindConnected
                              : l10n.contactsKindLocalOnly,
                        ),
                      ),
                      if (blocked)
                        Chip(
                          label: Text(l10n.contactsKindBlocked),
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                        ),
                      if (deleted)
                        Chip(
                          label: Text(l10n.contactsKindDeleted),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (contact.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.contactsFieldNotesLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(contact.notes),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: Text(l10n.commonEdit),
          onPressed: deleted ? null : onEdit,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(blocked ? Icons.lock_open : Icons.block),
          label: Text(
            blocked ? l10n.commonUnblock : l10n.commonBlock,
          ),
          onPressed: deleted ? null : onToggleBlock,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          label: Text(l10n.commonDelete),
          onPressed: deleted ? null : onDelete,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.contactsDeletePreservesHistory,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
