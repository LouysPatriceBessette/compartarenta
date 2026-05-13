import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/avatar_palette.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';

/// Main entry point for the Contacts area.
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  late final AppDatabase _db = AppDatabase();
  late final ContactsRepository _repo = ContactsRepository(_db);
  HandshakeOrchestrator? get _orchestrator =>
      HandshakeOrchestrator.maybeInstance;

  Future<List<Contact>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
    final orch = _orchestrator;
    if (orch != null) {
      orch.incomingHandshakes.addListener(_onIncomingChanged);
      unawaited(orch.processAllPendingHandshakes());
    }
  }

  @override
  void dispose() {
    _orchestrator?.incomingHandshakes.removeListener(_onIncomingChanged);
    super.dispose();
  }

  void _onIncomingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _reload() {
    setState(() {
      _future = _repo.list();
    });
  }

  Future<void> _openIncoming() async {
    await context.push('/contacts/incoming');
    if (!mounted) return;
    _reload();
  }

  Future<void> _openAddSheet() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_AddContactChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(l10n.contactsAddLocalOnlyAction),
              subtitle: Text(l10n.contactsKindLocalOnly),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AddContactChoice.localOnly),
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: Text(l10n.contactsInviteAction),
              subtitle: Text(l10n.contactsKindConnected),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AddContactChoice.invite),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _AddContactChoice.localOnly:
        await context.push('/contacts/new');
      case _AddContactChoice.invite:
        await context.push('/contacts/invite/new');
    }
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsTitle),
        actions: [
          IconButton(
            tooltip: l10n.contactsInvitationsTitle,
            icon: const Icon(Icons.outgoing_mail),
            onPressed: () =>
                context.push('/contacts/invitations').then((_) => _reload()),
          ),
          IconButton(
            tooltip: l10n.contactsEnterInviteCodeTitle,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () =>
                context.push('/contacts/redeem').then((_) => _reload()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.contactsAddContactAction),
        onPressed: _openAddSheet,
      ),
      body: Column(
        children: [
          _IncomingBanner(orchestrator: _orchestrator, onTap: _openIncoming),
          Expanded(
            child: FutureBuilder<List<Contact>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? const <Contact>[];
                if (items.isEmpty) {
                  return const _ContactsEmptyState();
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final contact = items[index];
                    return _ContactTile(
                      contact: contact,
                      onTap: () => context
                          .push('/contacts/${contact.id}')
                          .then((_) => _reload()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _AddContactChoice { localOnly, invite }

class _IncomingBanner extends StatelessWidget {
  const _IncomingBanner({required this.orchestrator, required this.onTap});

  final HandshakeOrchestrator? orchestrator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orch = orchestrator;
    if (orch == null) return const SizedBox.shrink();
    return ValueListenableBuilder<List<IncomingHandshakeView>>(
      valueListenable: orch.incomingHandshakes,
      builder: (context, value, _) {
        if (value.isEmpty) return const SizedBox.shrink();
        final count = value.length;
        return Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      count == 1
                          ? l10n.contactsIncomingBannerOne
                          : l10n.contactsIncomingBannerMany(count),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactsEmptyState extends StatelessWidget {
  const _ContactsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(MdiIcons.accountMultipleOutline, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.contactsEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.contactsEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onTap});

  final Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocked = contact.isBlocked;
    final connected = contact.kind == 'connected';
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: blocked
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(AvatarPalette.iconFor(contact.avatarId)),
      ),
      title: Text(contact.displayName),
      subtitle: Text(
        blocked
            ? l10n.contactsKindBlocked
            : connected
            ? l10n.contactsKindConnected
            : l10n.contactsKindLocalOnly,
      ),
      trailing: connected
          ? Icon(
              Icons.link,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_right),
    );
  }
}
