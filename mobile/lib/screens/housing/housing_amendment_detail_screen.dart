import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_expense_preview.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../housing/amendment/housing_amendment_settlement.dart';
import '../../housing/amendment/housing_amendment_summary.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/housing_response_deadline_display.dart';
import '../../housing/housing_plan_peer_contacts.dart';
import '../../housing/proposals/housing_proposal_revision_state.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../notifications/push_notification_service.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import 'housing_invitation_status_dialog.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_plan_missing_contacts_screen.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Focused view of a single in-force plan change awaiting unanimous response.
class HousingAmendmentDetailScreen extends StatefulWidget {
  const HousingAmendmentDetailScreen({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    this.revisionId,
    this.readOnlySettled = false,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final String? revisionId;
  final bool readOnlySettled;

  @override
  State<HousingAmendmentDetailScreen> createState() =>
      _HousingAmendmentDetailScreenState();
}

class _HousingAmendmentDetailScreenState extends State<HousingAmendmentDetailScreen> {
  _AmendmentDetailPayload? _payload;
  bool _loading = true;
  bool _loadFailed = false;
  @override
  void initState() {
    super.initState();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reload());
    });
  }

  void _openMissingContactsHub() {
    navigateToRoute<void>(context, 
          MaterialPageRoute<void>(
            builder: (_) => HousingPlanMissingContactsScreen(
              db: widget.db,
              planId: widget.planId,
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          unawaited(_reload());
        });
  }

  /// When the pending revision closed (e.g. unanimous activation), leave this
  /// screen instead of showing a dead-end error.
  Future<bool> _routeAwayIfPendingClosed() async {
    final transport = HousingProposalTransportService(widget.db);
    await transport.reconcileStalePackagePending(widget.planId);
    if (!mounted) return true;

    if (await openHousingActivePlanHubIfActive(
      context,
      db: widget.db,
      planId: widget.planId,
      prefs: widget.prefs,
    )) {
      return true;
    }

    final pendingId = await transport.pendingRevisionIdForPlan(widget.planId);
    if (pendingId != null &&
        !await pendingRevisionIsAmendment(
          widget.db,
          widget.planId,
          revisionId: pendingId,
        )) {
      if (!mounted) return true;
      await navigateToRoute<void>(context, 
        MaterialPageRoute<void>(
          builder: (_) => HousingInviteProposalScreen(
            db: widget.db,
            planId: widget.planId,
            prefs: widget.prefs,
            revisionId: pendingId,
          ),
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final showSpinner = _payload == null;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final l10n = AppLocalizations.of(context);
      final dateFmt = effectiveDateFormat(widget.prefs);
      final summary = await loadHousingAmendmentSummary(
        db: widget.db,
        planId: widget.planId,
        revisionId: widget.revisionId,
        l10n: l10n,
        dateFormat: dateFmt,
      );
      if (!mounted) return;

      if (summary == null) {
        if (await _routeAwayIfPendingClosed()) return;
        setState(() {
          _loading = false;
          _loadFailed = true;
          _payload = null;
        });
        return;
      }

      final responses = await (widget.db.select(widget.db.proposalResponses)
            ..where((t) => t.revisionId.equals(summary.revisionId)))
          .get();
      final selfId = '${widget.planId}:self';
      final selfStatus = responses
              .where((r) => r.participantId == selfId)
              .map((r) => r.status)
              .firstOrNull ??
          ProposalResponseStatus.pending.name;

      bool? settledAccepted;
      String? settledActorName;
      DateTime? settledAt;
      String? settledRefusalMessage;
      if (widget.readOnlySettled) {
        final rev = await (widget.db.select(widget.db.proposalRevisions)
              ..where((t) => t.id.equals(summary.revisionId)))
            .getSingleOrNull();
        if (rev != null) {
          final payload =
              jsonDecode(rev.payloadJson) as Map<String, dynamic>;
          settledAccepted = archivedAmendmentWasAccepted(payload);
          final roster =
              await participantsForPlan(widget.db, widget.planId);
          final actorId = await settledAmendmentActorParticipantId(
            db: widget.db,
            revisionId: rev.id,
            proposerParticipantId: summary.proposerParticipantId,
            archivedPayload: payload,
          );
          settledActorName = actorId == null || actorId.isEmpty
              ? summary.proposerDisplayName
              : displayNameForParticipant(actorId, roster);
          var settledWhen = rev.createdAt;
          if (settledAccepted) {
            final responses = await (widget.db.select(
              widget.db.proposalResponses,
            )..where((t) => t.revisionId.equals(rev.id))).get();
            for (final r in responses) {
              if (r.status != ProposalResponseStatus.accepted.name) {
                continue;
              }
              final at = r.respondedAt;
              if (at != null && at.isAfter(settledWhen)) settledWhen = at;
            }
          } else {
            final response = actorId == null || actorId.isEmpty
                ? null
                : await (widget.db.select(widget.db.proposalResponses)
                      ..where((t) => t.revisionId.equals(rev.id))
                      ..where((t) => t.participantId.equals(actorId)))
                    .getSingleOrNull();
            settledWhen = response?.respondedAt ?? rev.createdAt;
          }
          settledAt = settledWhen;
          if (settledAccepted == false &&
              actorId != null &&
              actorId.isNotEmpty) {
            final messages = Map<String, dynamic>.from(
              (payload['responseMessages'] as Map?) ??
                  const <String, dynamic>{},
            );
            settledRefusalMessage = messages[actorId]?.toString();
          }
        }
      }

      final missingPeerContacts = await listMissingPlanPeerContacts(
        db: widget.db,
        planId: widget.planId,
      );

      if (!mounted) return;
      setState(() {
        _payload = _AmendmentDetailPayload(
          summary: summary,
          selfParticipantId: selfId,
          selfStatus: selfStatus,
          missingPeerContacts: missingPeerContacts,
          settledAccepted: settledAccepted,
          settledActorName: settledActorName,
          settledAt: settledAt,
          settledRefusalMessage: settledRefusalMessage,
        );
        _loading = false;
        _loadFailed = false;
      });
    } catch (e, st) {
      debugPrint('housing amendment detail load failed: $e\n$st');
      if (!mounted) return;
      if (await _routeAwayIfPendingClosed()) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _payload = null;
      });
    }
  }

  Future<void> _submitResponse(
    ProposalResponseStatus status, {
    String message = '',
  }) async {
    final l10n = AppLocalizations.of(context);
    final revisionId = _payload?.summary.revisionId;
    if (revisionId == null) return;

    if (status == ProposalResponseStatus.accepted) {
      final missing = await listMissingPlanPeerContacts(
        db: widget.db,
        planId: widget.planId,
      );
      if (!mounted) return;
      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingInviteMissingContactsBlocked)),
        );
        return;
      }
    }

    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      if (status == ProposalResponseStatus.negotiate) {
        await PushNotificationService.showLocalHousingResponseFailureNotification(
          errorCode: 'relay_unavailable',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('relay'))),
      );
      return;
    }

    if (status == ProposalResponseStatus.negotiate) {
      final notificationResult = await const NotificationFlowPermissionTrigger()
          .ensure(
            context: context,
            prefs: widget.prefs,
            switches: const {
              NotificationFlowSwitch.housingDecisionChange,
              NotificationFlowSwitch.housingOfferExpiration,
            },
          );
      if (notificationResult == NotificationFlowPermissionResult.abortFlow ||
          !mounted) {
        return;
      }
    }

    try {
      final result = await orchestrator.sendHousingProposalResponse(
        planId: widget.planId,
        status: status,
        message: message,
        revisionId: revisionId,
      );
      final relayDelivered = result.sentCount > 0;
      if (!relayDelivered) {
        if (status == ProposalResponseStatus.negotiate) {
          await PushNotificationService.showLocalHousingResponseFailureNotification(
            errorCode: 'send_failed',
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingInviteTransportFailed)),
        );
      } else {
        if (status == ProposalResponseStatus.negotiate &&
            result.failedParticipantIds.isNotEmpty) {
          await PushNotificationService.showLocalHousingResponseFailureNotification(
            errorCode: 'send_failed',
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingInviteResponseSent)),
        );
      }
      await _reload();
      if (!mounted) return;
      if (!relayDelivered) {
        return;
      }
      if (status == ProposalResponseStatus.negotiate) {
        if (mounted) context.go('/');
        return;
      }
      if (await _routeAwayIfPendingClosed()) return;
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on HandshakeOrchestratorError catch (e) {
      if (status == ProposalResponseStatus.negotiate) {
        await PushNotificationService.showLocalHousingResponseFailureNotification(
          errorCode: e.code,
        );
      }
      if (!mounted) return;
      final message = e.code == 'plan_missing_peer_contacts'
          ? l10n.housingInviteMissingContactsBlocked
          : l10n.housingPlanCouldNotContinue(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
      );
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFmt = effectiveDateFormat(widget.prefs);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentDetailTitle)),
      body: () {
        if (_loading && _payload == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.housingAmendmentDetailLoading),
              ],
            ),
          );
        }
        if (_loadFailed || _payload == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.housingRealizedExpenseLoadFailed,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          );
        }

        final data = _payload!;
        final summary = data.summary;
        final revisionState = HousingProposalRevisionState(
          lifecycleState: 'open',
          responseExpiresAtUtc: summary.responseExpiresAtUtc,
        );
        final canRespond = !widget.readOnlySettled &&
            housingParticipantMayRespond(
              revision: revisionState,
              participantResponseStatus: data.selfStatus,
              proposerParticipantId: summary.proposerParticipantId,
              participantId: data.selfParticipantId,
            );
        final isProposer =
            summary.proposerParticipantId == data.selfParticipantId;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: housingAmendmentScreenPadding(context),
                children: [
                  Text(
                    l10n.housingAmendmentDetailIntro(
                      summary.proposerDisplayName,
                      summary.subjectLabel(l10n),
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canRespond && summary.responseExpiresAtUtc != null) ...[
                    const SizedBox(height: 12),
                    HousingResponseDeadlineDisplay(
                      key: ValueKey(
                        'amendment-deadline-${summary.revisionId}-$canRespond',
                      ),
                      expiresUtc: summary.responseExpiresAtUtc!,
                      dateFormat: dateFmt,
                      l10n: l10n,
                    ),
                  ],
                  const SizedBox(height: 24),
                  HousingAmendmentComparisonSection(
                    db: widget.db,
                    planId: widget.planId,
                    prefs: widget.prefs,
                    summary: summary,
                    currentLabel: _beforeValueLabel(l10n, data),
                    proposedLabel: l10n.housingAmendmentDetailProposed,
                  ),
                  if (widget.readOnlySettled &&
                      data.settledAccepted != null &&
                      data.settledActorName != null &&
                      data.settledAt != null) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            data.settledAccepted!
                                ? l10n.housingRealizedExpenseReviewAcceptedWord
                                : l10n.housingRealizedExpenseReviewRejectedWord,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize:
                                  (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                                      1.8,
                              fontWeight: FontWeight.w700,
                              color: data.settledAccepted!
                                  ? Colors.green.shade700
                                  : theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.housingRealizedExpenseReviewByName(
                              data.settledActorName!,
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: data.settledAccepted!
                                  ? Colors.green.shade700
                                  : theme.colorScheme.error,
                            ),
                          ),
                          Text(
                            formatPreferenceDateTime(
                              data.settledAt!,
                              dateFmt,
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: data.settledAccepted!
                                  ? Colors.green.shade700
                                  : theme.colorScheme.error,
                            ),
                          ),
                          if (!data.settledAccepted! &&
                              data.settledRefusalMessage != null &&
                              data.settledRefusalMessage!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              l10n.housingAmendmentRefusalMessageLabel,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.settledRefusalMessage!.trim(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (!isProposer && canRespond) ...[
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        if (data.missingPeerContacts.isNotEmpty) {
                          _openMissingContactsHub();
                          return;
                        }
                        unawaited(
                          _submitResponse(ProposalResponseStatus.accepted),
                        );
                      },
                      child: Text(
                        data.missingPeerContacts.isEmpty
                            ? l10n.housingAmendmentAccept
                            : l10n.housingInviteMissingContactsAction,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _confirmReject,
                      child: Text(l10n.housingAmendmentReject),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: _goBack,
                      child: Text(l10n.housingPlanBack),
                    ),
                    if (isProposer && !widget.readOnlySettled) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => showHousingInvitationStatusDialog(
                          context,
                          db: widget.db,
                          planId: widget.planId,
                          prefs: widget.prefs,
                          revisionId: summary.revisionId,
                          dialogTitle: l10n.housingAmendmentRequestStatusAction,
                        ),
                        child: Text(l10n.housingAmendmentRequestStatusAction),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }(),
    );
  }

  Future<void> _confirmReject() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final message = await showAppDialog<String>(
      context: context,
      guardKey: 'housingAmendmentDetail.negotiateMessage',
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.housingAmendmentRejectTitle),
          content: AppTextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.housingAmendmentRejectMessageLabel,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(l10n.housingAmendmentRejectConfirm),
            ),
          ],
        );
      },
    );
    if (!mounted || message == null) return;
    await _submitResponse(
      ProposalResponseStatus.rejected,
      message: message,
    );
  }

  /// Label for the "before" value on archived decision screens (never "Currently").
  String _beforeValueLabel(AppLocalizations l10n, _AmendmentDetailPayload data) {
    if (widget.readOnlySettled && data.settledAccepted != null) {
      return data.settledAccepted!
          ? l10n.housingAmendmentDetailPrevious
          : l10n.housingAmendmentDetailAtRequestTime;
    }
    return l10n.housingAmendmentDetailCurrent;
  }
}

class _AmendmentDetailPayload {
  const _AmendmentDetailPayload({
    required this.summary,
    required this.selfParticipantId,
    required this.selfStatus,
    required this.missingPeerContacts,
    this.settledAccepted,
    this.settledActorName,
    this.settledAt,
    this.settledRefusalMessage,
  });

  final HousingAmendmentSummary summary;
  final String selfParticipantId;
  final String selfStatus;
  final List<Participant> missingPeerContacts;
  final bool? settledAccepted;
  final String? settledActorName;
  final DateTime? settledAt;
  final String? settledRefusalMessage;
}
