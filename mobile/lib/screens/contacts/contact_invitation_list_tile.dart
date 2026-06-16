import 'package:flutter/material.dart';

import '../../contacts/contact_invitations_repository.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';

/// Row for a sent invitation (pending or expired) on [OutstandingInvitationsScreen].
class ContactInvitationListTile extends StatelessWidget {
  const ContactInvitationListTile({
    super.key,
    required this.invitation,
    required this.dateFormat,
    required this.onOpenCode,
    required this.onDeleteExpired,
  });

  final ContactInvitation invitation;
  final String dateFormat;
  final VoidCallback onOpenCode;
  final VoidCallback onDeleteExpired;

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
              onPressed: onDeleteExpired,
            )
          : const Icon(Icons.chevron_right),
    );
  }
}

/// Pending and expired invitations for the inviter, newest first.
List<ContactInvitation> sortSentInvitationsForList(
  List<ContactInvitation> rows,
) {
  final visible = rows
      .where(
        (row) =>
            row.status == InvitationStatus.pending ||
            row.status == InvitationStatus.expired,
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return visible;
}
