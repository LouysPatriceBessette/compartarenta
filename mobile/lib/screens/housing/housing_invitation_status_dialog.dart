import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';

String _formatUtcDateTime(DateTime utc, AppPreferences prefs) {
  final local = utc.toLocal();
  final fmt = prefs.dateFormat.trim().isEmpty ? 'YYYY-MM-DD' : prefs.dateFormat;
  final date = formatPreferenceDate(utc, fmt);
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$date $h:$m';
}

String _responseStatusLabel(AppLocalizations l10n, String? statusName) {
  switch (statusName) {
    case 'accepted':
      return l10n.housingInviteStatusAccepted;
    case 'rejected':
      return l10n.housingInviteStatusRejected;
    case 'negotiate':
      return l10n.housingInviteStatusNegotiating;
    case 'pending':
    default:
      return l10n.housingInviteStatusPending;
  }
}

/// Shows invitation dispatch time, response deadline, and per-invitee DB status.
Future<void> showHousingInvitationStatusDialog(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required AppPreferences prefs,
  String? revisionId,
}) async {
  final l10n = AppLocalizations.of(context);
  await HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes();
  if (!context.mounted) return;
  final pkg = await (db.select(
    db.proposalPackages,
  )..where((t) => t.planId.equals(planId))).getSingleOrNull();
  final pendingId = revisionId ?? pkg?.pendingRevisionId;
  if (!context.mounted) return;
  if (pendingId == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.housingInviteStatusNoPending)));
    return;
  }

  final rev = await (db.select(
    db.proposalRevisions,
  )..where((t) => t.id.equals(pendingId))).getSingleOrNull();
  if (!context.mounted) return;
  if (rev == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.housingInviteStatusNoPending)));
    return;
  }

  final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  final responseMessages = Map<String, dynamic>.from(
    (payload['responseMessages'] as Map?) ?? const <String, dynamic>{},
  );
  final expiresStr = payload['responseExpiresAt'] as String?;
  DateTime? expiresUtc;
  if (expiresStr != null) {
    try {
      expiresUtc = DateTime.parse(expiresStr);
    } catch (_) {
      expiresUtc = null;
    }
  }

  final responses = await (db.select(
    db.proposalResponses,
  )..where((t) => t.revisionId.equals(pendingId))).get();
  final byParticipant = {for (final r in responses) r.participantId: r.status};

  final all = await db.listParticipants();
  int rosterOrder(String id) {
    if (id.endsWith(':self')) return -1;
    final tail = id.split(':p').last;
    return int.tryParse(tail) ?? 999;
  }

  final roster =
      all
          .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
          .toList()
        ..sort((a, b) => rosterOrder(a.id).compareTo(rosterOrder(b.id)));

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final sent = _formatUtcDateTime(rev.createdAt.toUtc(), prefs);
      final deadline = expiresUtc != null
          ? _formatUtcDateTime(expiresUtc.toUtc(), prefs)
          : l10n.housingInviteStatusDeadlineNotSet;

      return AlertDialog(
        title: Text(l10n.housingInviteStatusDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.housingInviteStatusSentAtLabel(sent),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.housingInviteStatusDeadlineLabel(deadline),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.housingInviteStatusTableSectionTitle,
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text(l10n.housingInviteStatusTableInvitee),
                    ),
                    DataColumn(
                      label: Text(l10n.housingInviteStatusTableStatus),
                    ),
                  ],
                  rows: [
                    for (final p in roster)
                      DataRow(
                        cells: [
                          DataCell(Text(p.displayName)),
                          DataCell(
                            Text(
                              _responseStatusLabel(l10n, byParticipant[p.id]),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (responseMessages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.housingInviteStatusMessagesSectionTitle,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final entry in responseMessages.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_displayNameForParticipantId(entry.key, roster)}: ${entry.value}',
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.onboardingOk),
          ),
        ],
      );
    },
  );
}

String _displayNameForParticipantId(String id, List<Participant> roster) {
  for (final participant in roster) {
    if (participant.id == id) return participant.displayName;
  }
  return id;
}
