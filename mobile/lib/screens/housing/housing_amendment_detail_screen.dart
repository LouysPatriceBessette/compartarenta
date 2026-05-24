import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_summary.dart';
import '../../housing/housing_response_deadline_display.dart';
import '../../housing/proposals/housing_proposal_revision_state.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../notifications/push_notification_service.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import 'housing_invitation_status_dialog.dart';

/// Focused view of a single in-force plan change awaiting unanimous response.
class HousingAmendmentDetailScreen extends StatefulWidget {
  const HousingAmendmentDetailScreen({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    this.revisionId,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final String? revisionId;

  @override
  State<HousingAmendmentDetailScreen> createState() =>
      _HousingAmendmentDetailScreenState();
}

class _HousingAmendmentDetailScreenState extends State<HousingAmendmentDetailScreen> {
  _AmendmentDetailPayload? _payload;
  bool _loading = true;
  bool _loadFailed = false;
  bool _negotiateExpanded = false;
  final _negotiateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
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
        setState(() {
          _loading = false;
          _loadFailed = _payload == null;
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

      if (!mounted) return;
      setState(() {
        _payload = _AmendmentDetailPayload(
          summary: summary,
          selfParticipantId: selfId,
          selfStatus: selfStatus,
        );
        _loading = false;
        _loadFailed = false;
      });
    } catch (e, st) {
      debugPrint('housing amendment detail load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = _payload == null;
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
      setState(() {
        _negotiateExpanded = false;
        _negotiateController.clear();
      });
      if (status == ProposalResponseStatus.negotiate) {
        context.go('/');
        return;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue(e.code))),
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
        final canRespond = housingParticipantMayRespond(
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
                padding: const EdgeInsets.all(16),
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
                  _ValueCard(
                    label: l10n.housingAmendmentDetailCurrent,
                    value: summary.currentText,
                  ),
                  const SizedBox(height: 12),
                  _ValueCard(
                    label: l10n.housingAmendmentDetailProposed,
                    value: summary.proposedText,
                    emphasized: true,
                  ),
                  if (!isProposer && canRespond && !_negotiateExpanded) ...[
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => _submitResponse(
                        ProposalResponseStatus.accepted,
                      ),
                      child: Text(l10n.housingInviteAcceptFull),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _negotiateExpanded = true),
                      child: Text(l10n.housingInviteNegotiate),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => _submitResponse(
                        ProposalResponseStatus.rejected,
                      ),
                      child: Text(l10n.housingInviteRejectBlock),
                    ),
                  ] else if (!isProposer &&
                      canRespond &&
                      _negotiateExpanded) ...[
                    const SizedBox(height: 32),
                    TextField(
                      controller: _negotiateController,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.housingInviteNegotiateMessageLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        final t = _negotiateController.text.trim();
                        if (t.isEmpty) return;
                        _submitResponse(
                          ProposalResponseStatus.negotiate,
                          message: t,
                        );
                      },
                      child: Text(l10n.commonSend),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _negotiateExpanded = false;
                        _negotiateController.clear();
                      }),
                      child: Text(l10n.commonCancel),
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
                    if (isProposer) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => showHousingInvitationStatusDialog(
                          context,
                          db: widget.db,
                          planId: widget.planId,
                          prefs: widget.prefs,
                          revisionId: summary.revisionId,
                        ),
                        child: Text(l10n.housingInviteInvitationStatusAction),
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
}

class _AmendmentDetailPayload {
  const _AmendmentDetailPayload({
    required this.summary,
    required this.selfParticipantId,
    required this.selfStatus,
  });

  final HousingAmendmentSummary summary;
  final String selfParticipantId;
  final String selfStatus;
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: emphasized
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
