import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/housing_response_deadline_dialog.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';

/// Shows invitation dispatch time, response deadline, and per-invitee DB status.
Future<void> showHousingInvitationStatusDialog(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required AppPreferences prefs,
  String? revisionId,
  VoidCallback? onAfterResend,
}) async {
  final l10n = AppLocalizations.of(context);
  await HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes();
  if (!context.mounted) return;
  final pkg = await (db.select(
    db.proposalPackages,
  )..where((t) => t.planId.equals(planId))).getSingleOrNull();
  var pendingId = revisionId ?? pkg?.pendingRevisionId;
  if (pendingId == null && pkg != null) {
    final revisions = await (db.select(
      db.proposalRevisions,
    )..where((t) => t.packageId.equals(pkg.id))).get();
    revisions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final candidate in revisions) {
      final payload = jsonDecode(candidate.payloadJson) as Map<String, dynamic>;
      if (payload['lifecycleState'] == 'draft') continue;
      pendingId = candidate.id;
      break;
    }
  }
  if (!context.mounted) return;
  if (pendingId == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.housingInviteStatusNoPending)));
    return;
  }
  final selectedRevisionId = pendingId;

  final rev = await (db.select(
    db.proposalRevisions,
  )..where((t) => t.id.equals(selectedRevisionId))).getSingleOrNull();
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
  final relayStatus = Map<String, dynamic>.from(
    (payload['relaySendStatusByParticipantId'] as Map?) ??
        const <String, dynamic>{},
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
  )..where((t) => t.revisionId.equals(selectedRevisionId))).get();
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

  final canResend = await PlanAgreementProposalService(
    db,
  ).canResendPendingProposal(planId);

  if (!context.mounted) return;
  final dateFmt = effectiveDateFormat(prefs);
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final sent = formatPreferenceDateTime(rev.createdAt.toUtc(), dateFmt);
      final deadline = expiresUtc != null
          ? formatPreferenceDateTime(expiresUtc.toUtc(), dateFmt)
          : l10n.housingInviteStatusDeadlineNotSet;

      String relayLabel(String participantId) {
        final raw = relayStatus[participantId]?.toString();
        return switch (raw) {
          'queued' => l10n.housingInviteStatusRelayQueued,
          'failed' => l10n.housingInviteStatusRelayFailed,
          _ => l10n.housingInviteStatusRelayUnknown,
        };
      }

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
                    DataColumn(
                      label: Text(l10n.housingInviteStatusTableRelay),
                    ),
                  ],
                  rows: [
                    for (final p in roster)
                      if (!p.id.endsWith(':self'))
                        DataRow(
                          cells: [
                            DataCell(Text(p.displayName)),
                            DataCell(
                              Text(
                                _responseStatusLabel(l10n, byParticipant[p.id]),
                              ),
                            ),
                            DataCell(Text(relayLabel(p.id))),
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
          if (canResend)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (!context.mounted) return;
                await _resendPendingProposalDelivery(
                  context,
                  db: db,
                  planId: planId,
                  revisionId: selectedRevisionId,
                  prefs: prefs,
                );
                onAfterResend?.call();
              },
              child: Text(l10n.housingInviteResendProposalAction),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.onboardingOk),
          ),
        ],
      );
    },
  );
}

Future<void> _resendPendingProposalDelivery(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required String revisionId,
  required AppPreferences prefs,
}) async {
  final l10n = AppLocalizations.of(context);
  final duration = await showHousingResponseDeadlineDialog(context);
  if (duration == null || !context.mounted) return;

  final expiresAt = DateTime.now().toUtc().add(duration);
  await HousingProposalTransportService(db).updateRevisionPayload(
    revisionId: revisionId,
    mutate: (payload) {
      payload['responseExpiresAt'] = expiresAt.toIso8601String();
      payload['lifecycleState'] = 'open';
    },
  );

  try {
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      throw HandshakeOrchestratorError('relay_unavailable');
    }
    final send = await orchestrator.sendHousingProposalToPlanParticipants(
      planId: planId,
      revisionId: revisionId,
    );
    if (send.relayStatusByParticipantId.isNotEmpty) {
      await HousingProposalTransportService(db).updateRevisionPayload(
        revisionId: revisionId,
        mutate: (payload) {
          payload['relaySendStatusByParticipantId'] =
              send.relayStatusByParticipantId;
        },
      );
    }
    if (!context.mounted) return;
    if (send.sentCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingInviteTransportFailed)),
      );
      return;
    }
    final message = send.failedParticipantIds.isEmpty
        ? l10n.housingInviteTransportSent(send.sentCount)
        : l10n.housingInviteTransportPartial(
            send.sentCount,
            send.failedParticipantIds.length,
          );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
    );
  }
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

String _displayNameForParticipantId(String id, List<Participant> roster) {
  for (final participant in roster) {
    if (participant.id == id) return participant.displayName;
  }
  return id;
}
