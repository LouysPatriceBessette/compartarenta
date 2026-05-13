import 'package:flutter/material.dart';

import '../../contacts/avatar_palette.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'contact_editor_screen.dart';
import 'generate_invitation_screen.dart';

/// Bottom sheet used by modules to select an existing Contact as a participant.
class ContactPickerSheet extends StatefulWidget {
  const ContactPickerSheet({
    super.key,
    required this.db,
    this.excludeContactIds = const <String>{},
  });

  final AppDatabase db;
  final Set<String> excludeContactIds;

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  late Future<List<Contact>> _future = _loadContacts();

  Future<List<Contact>> _loadContacts() async {
    final contacts = await widget.db.listContacts();
    return contacts
        .where((c) => !widget.excludeContactIds.contains(c.id))
        .toList();
  }

  void _reload() {
    setState(() => _future = _loadContacts());
  }

  Future<void> _addContact() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ContactEditorScreen()),
    );
    if (mounted) _reload();
  }

  Future<void> _inviteContact() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const GenerateInvitationScreen()),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.contactsPickerTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<Contact>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contacts = snapshot.data ?? const <Contact>[];
                  if (contacts.isEmpty) {
                    return _ContactPickerEmptyState(
                      onAddContact: _addContact,
                      onInviteContact: _inviteContact,
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(AvatarPalette.iconFor(contact.avatarId)),
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(_kindLabel(l10n, contact)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(contact),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.contactsAddLocalOnlyAction),
                  onPressed: _addContact,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(l10n.contactsInviteAction),
                  onPressed: _inviteContact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(AppLocalizations l10n, Contact contact) {
    if (contact.isBlocked) return l10n.contactsKindBlocked;
    return switch (contact.kind) {
      'connected' => l10n.contactsKindConnected,
      'archived' => l10n.contactsKindDeleted,
      _ => l10n.contactsKindLocalOnly,
    };
  }
}

class _ContactPickerEmptyState extends StatelessWidget {
  const _ContactPickerEmptyState({
    required this.onAddContact,
    required this.onInviteContact,
  });

  final VoidCallback onAddContact;
  final VoidCallback onInviteContact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.contactsPickerEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.contactsPickerEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            label: Text(l10n.contactsAddLocalOnlyAction),
            onPressed: onAddContact,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(l10n.contactsInviteAction),
            onPressed: onInviteContact,
          ),
        ],
      ),
    );
  }
}

Future<Contact?> showContactPickerSheet({
  required BuildContext context,
  required AppDatabase db,
  Set<String> excludeContactIds = const <String>{},
}) {
  return showModalBottomSheet<Contact>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        ContactPickerSheet(db: db, excludeContactIds: excludeContactIds),
  );
}
