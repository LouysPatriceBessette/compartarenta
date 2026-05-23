import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/avatar_palette.dart';
import '../../contacts/contact_display.dart';
import '../../contacts/contact_invitations_repository.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';

/// Outstanding invitation row for [contact], if this list row is an inviter stub.
ContactInvitation? invitationForContactStub(
  Contact contact,
  Map<String, ContactInvitation> byStub,
) {
  final direct = byStub[contact.id];
  if (direct != null) return direct;
  const prefix = 'contact:handshake:';
  if (!contact.id.startsWith(prefix)) return null;
  final invitationId = contact.id.substring(prefix.length);
  for (final row in byStub.values) {
    if (row.id == invitationId) return row;
  }
  return null;
}

/// Invitations first (newest creation first), then connected (A–Z), then others (A–Z).
List<Contact> sortContactsForMainList(
  List<Contact> contacts,
  Map<String, ContactInvitation> invitations,
) {
  int tier(Contact contact) {
    if (contact.kind == 'connected') return 1;
    if (invitationForContactStub(contact, invitations) != null) return 0;
    return 2;
  }

  final sorted = List<Contact>.of(contacts);
  sorted.sort((a, b) {
    final tierA = tier(a);
    final tierB = tier(b);
    if (tierA != tierB) return tierA.compareTo(tierB);
    switch (tierA) {
      case 0:
        final invA = invitationForContactStub(a, invitations)!;
        final invB = invitationForContactStub(b, invitations)!;
        return invB.createdAt.compareTo(invA.createdAt);
      case 1:
      case 2:
        return _compareDisplayNames(a, b);
      default:
        return 0;
    }
  });
  return sorted;
}

int _compareDisplayNames(Contact a, Contact b) {
  final nameA = a.effectiveDisplayName.toLowerCase();
  final nameB = b.effectiveDisplayName.toLowerCase();
  final byName = nameA.compareTo(nameB);
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

/// Main entry point for the Contacts area.
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  AppDatabase get _db => AppDatabase.processScope;
  late final ContactsRepository _repo = ContactsRepository(_db);
  late final ContactInvitationsRepository _invitationsRepo =
      ContactInvitationsRepository(_db);
  HandshakeOrchestrator? get _orchestrator =>
      HandshakeOrchestrator.maybeInstance;

  Future<({List<Contact> contacts, Map<String, ContactInvitation> invitations})>?
      _future;
  bool _refreshingIncoming = false;

  /// Last seen length of [HandshakeOrchestrator.incomingHandshakes]. When it
  /// changes (e.g. inviter accepts the last request), we reload contacts so
  /// the list reflects [ContactsRepository.promoteToConnected] without leaving
  /// the screen.
  int _lastIncomingHandshakesCount = -1;

  @override
  void initState() {
    super.initState();
    _reload();
    final orch = _orchestrator;
    if (orch != null) {
      _lastIncomingHandshakesCount = orch.incomingHandshakes.value.length;
      orch.incomingHandshakes.addListener(_onIncomingChanged);
      orch.steadyStateInboxTick.addListener(_onSteadyInboxTick);
      unawaited(() async {
        await orch.processAllPendingHandshakes();
        await orch.refreshIncomingHandshakes();
      }());
    }
  }

  @override
  void dispose() {
    _orchestrator?.incomingHandshakes.removeListener(_onIncomingChanged);
    _orchestrator?.steadyStateInboxTick.removeListener(_onSteadyInboxTick);
    super.dispose();
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    _reload();
  }

  void _onIncomingChanged() {
    if (!mounted) return;
    final orch = _orchestrator;
    final n = orch?.incomingHandshakes.value.length ?? 0;
    if (n != _lastIncomingHandshakesCount) {
      _lastIncomingHandshakesCount = n;
      _reload();
      // Brief follow-up read after the frame in case the last handshake row
      // is cleared asynchronously right as the count hits zero.
      if (n == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future<void>.delayed(const Duration(milliseconds: 48), () {
            if (mounted) _reload();
          });
        });
      }
    }
    setState(() {});
  }

  void _reload() {
    setState(() {
      _future = _loadContacts();
    });
  }

  Future<({List<Contact> contacts, Map<String, ContactInvitation> invitations})>
      _loadContacts() async {
    final contacts = await _repo.list();
    final invitations = await _invitationsRepo.mapOutstandingByContactStub();
    return (
      contacts: sortContactsForMainList(contacts, invitations),
      invitations: invitations,
    );
  }

  Future<void> _openInvitationCode(ContactInvitation invitation) async {
    await context.push('/contacts/invite/code/${invitation.id}');
    if (!mounted) return;
    _reload();
  }

  Future<void> _deleteExpiredInvitationStub({
    required Contact contact,
    required ContactInvitation invitation,
  }) async {
    await _repo.deleteLocally(contact.id);
    if (!mounted) return;
    _reload();
  }

  Future<void> _openIncoming() async {
    await context.push('/contacts/incoming');
    if (!mounted) return;
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _openInviteContact() async {
    await context.push('/contacts/invite/new');
    if (!mounted) return;
    _reload();
  }

  Future<void> _refreshIncomingNow() async {
    final orch = _orchestrator;
    if (orch == null || _refreshingIncoming) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _refreshingIncoming = true);
    try {
      final activeBefore = await orch.activePendingHandshakeRows();
      final allBefore = await orch.allPendingHandshakeRowsForDiagnostics();
      await orch.processAllPendingHandshakes();
      await orch.pollSteadyStateInboxes();
      await orch.refreshIncomingHandshakes();
      if (!mounted) return;
      _lastIncomingHandshakesCount = orch.incomingHandshakes.value.length;
      _reload();
      final count = orch.incomingHandshakes.value.length;
      final activeCount = activeBefore.length;
      final latestError = allBefore.isEmpty ? '' : allBefore.last.lastErrorCode;
      final latest = allBefore.isEmpty
          ? 'none'
          : latestError.isEmpty
          ? allBefore.last.state
          : '${allBefore.last.state}/$latestError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? l10n.contactsRefreshIncomingDiagnostics(
                    activeCount,
                    allBefore.length,
                    latest,
                  )
                : l10n.contactsRefreshIncomingFound(count),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshingIncoming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
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
          IconButton(
            tooltip: l10n.contactsRefreshIncomingTooltip,
            icon: _refreshingIncoming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _refreshingIncoming ? null : _refreshIncomingNow,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.contactsAddContactAction),
        onPressed: _openInviteContact,
      ),
      body: Column(
        children: [
          _IncomingBanner(orchestrator: _orchestrator, onTap: _openIncoming),
          Expanded(
            child: FutureBuilder<
                ({
                  List<Contact> contacts,
                  Map<String, ContactInvitation> invitations,
                })>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                final items = data?.contacts ?? const <Contact>[];
                final invitations = data?.invitations ?? const {};
                if (items.isEmpty) {
                  return const _ContactsEmptyState();
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
                        final contact = items[index];
                        final invitation = invitationForContactStub(
                          contact,
                          invitations,
                        );
                        if (invitation != null && contact.kind != 'connected') {
                          return _InvitationStubTile(
                            contact: contact,
                            invitation: invitation,
                            dateFormat: dateFormat,
                            onOpenCode: () => _openInvitationCode(invitation),
                            onDelete: () => _deleteExpiredInvitationStub(
                              contact: contact,
                              invitation: invitation,
                            ),
                          );
                        }
                        return _ContactTile(
                          contact: contact,
                          onTap: () => context
                              .push('/contacts/${contact.id}')
                              .then((_) => _reload()),
                        );
                      },
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

class _InvitationStubTile extends StatelessWidget {
  const _InvitationStubTile({
    required this.contact,
    required this.invitation,
    required this.dateFormat,
    required this.onOpenCode,
    required this.onDelete,
  });

  final Contact contact;
  final ContactInvitation invitation;
  final String dateFormat;
  final VoidCallback onOpenCode;
  final VoidCallback onDelete;

  bool get _isExpired =>
      invitation.status == InvitationStatus.expired ||
      invitation.expiresAt.isBefore(DateTime.now().toUtc());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtitle = _isExpired
        ? l10n.deadlineRemainingExpired
        : formatPreferenceDateTime(invitation.createdAt, dateFormat);

    return ListTile(
      onTap: _isExpired ? null : onOpenCode,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.outgoing_mail,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(l10n.contactsInvitationStubTitle),
      subtitle: Text(
        subtitle,
        style: _isExpired
            ? TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      trailing: _isExpired
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
              onPressed: onDelete,
            )
          : const Icon(Icons.chevron_right),
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
    final disconnected = contact.showsDisconnectedStatus;
    final statusLine = blocked
        ? l10n.contactsKindBlocked
        : connected
        ? l10n.contactsKindConnected
        : disconnected
        ? l10n.contactsKindDisconnected
        : l10n.contactsKindLocalOnly;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: blocked
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(AvatarPalette.iconFor(contact.avatarId)),
      ),
      title: Text(contact.effectiveDisplayName),
      subtitle: Text(statusLine),
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
