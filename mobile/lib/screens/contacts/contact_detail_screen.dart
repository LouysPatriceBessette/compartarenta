import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../contacts/avatar_palette.dart';
import '../../contacts/contact_display.dart';
import '../../relay/handshake_orchestrator.dart';

/// Detail view for a Contact. Exposes edit, delete, block, and (when
/// connected) disconnect actions.
class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  AppDatabase get _db => AppDatabase.processScope;
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
            onReconnect: contact.showsDisconnectedStatus
                ? () async {
                    await context.push('/contacts/invite/new');
                    if (mounted) _reload();
                  }
                : null,
            onDelete: () => _confirmAndDelete(contact),
            onToggleBlock: () => _confirmAndToggleBlock(contact),
            onDisconnect: contact.kind == 'connected'
                ? () => _confirmAndDisconnect(contact)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(Contact contact) async {
    final l10n = AppLocalizations.of(context);

    // Per `contact-privacy-and-deletion`: a Contact still referenced as a
    // module-plan participant must be removed from those plans first, so the
    // user has an explicit chance to reassign or close them. We surface the
    // current set of plan titles in the blocked-deletion dialog.
    final blockingPlans = await _repo.plansReferencing(contact.id);
    if (!mounted) return;
    if (blockingPlans.isNotEmpty) {
      final titles = blockingPlans
          .map((p) => p.title.isEmpty ? p.id : p.title)
          .toList(growable: false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.contactsDeleteBlockedByPlansTitle),
          content: Text(
            l10n.contactsDeleteBlockedByPlansBody(
              titles.length,
              titles.join(', '),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonDone),
            ),
          ],
        ),
      );
      return;
    }

    // Per the same spec, a connected Contact must go through the explicit
    // Disconnect path before it can be deleted, otherwise the peer would be
    // left believing the relationship is still active. We point the user at
    // the Disconnect action and let them trigger it from the dialog.
    if (contact.kind == 'connected') {
      final goDisconnect = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.contactsDeleteBlockedConnectedTitle),
          content: Text(l10n.contactsDeleteBlockedConnectedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.contactsDeleteBlockedConnectedAction),
            ),
          ],
        ),
      );
      if (!mounted || goDisconnect != true) return;
      await _confirmAndDisconnect(contact);
      return;
    }

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

  Future<void> _confirmAndDisconnect(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsHandshakeNotAvailableYet)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.contactsDisconnectTitle),
        content: Text(l10n.contactsDisconnectBody),
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
            child: Text(l10n.contactsDisconnectAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await orchestrator.sendDisconnect(contact.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsDisconnectSent)),
      );
    } on HandshakeOrchestratorError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsHandshakeErrorRelayUnavailable)),
      );
    }
    _reload();
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({
    required this.contact,
    required this.onEdit,
    this.onReconnect,
    required this.onDelete,
    required this.onToggleBlock,
    this.onDisconnect,
  });

  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback? onReconnect;
  final VoidCallback onDelete;
  final VoidCallback onToggleBlock;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = contact.kind == 'connected';
    final blocked = contact.isBlocked;
    final deleted = contact.deletedAt != null;
    final disconnected = contact.showsDisconnectedStatus;
    final statusLabel = connected
        ? l10n.contactsKindConnected
        : disconnected
        ? l10n.contactsKindDisconnected
        : l10n.contactsKindLocalOnly;
    final editLabel = (connected || disconnected)
        ? l10n.contactsLabelEditorTitle
        : l10n.commonEdit;
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
                    contact.effectiveDisplayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (contact.showsDistinctPeerCanonicalForDisplay) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.contactsFieldTheirNameLabel}: ${contact.displayName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(statusLabel),
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
        if (onReconnect != null && !deleted) ...[
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: Text(l10n.contactsReconnectAction),
            onPressed: onReconnect,
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: Text(editLabel),
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
        if (onDisconnect != null && !deleted) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.link_off),
            label: Text(l10n.contactsDisconnectAction),
            onPressed: onDisconnect,
          ),
        ],
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
