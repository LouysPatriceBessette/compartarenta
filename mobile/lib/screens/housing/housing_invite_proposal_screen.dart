import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/proposals/housing_proposal_revision_state.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import 'housing_agreement_rules_read_only.dart';
import 'housing_invite_sunburst.dart';
import 'housing_proposal_expenses_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../notifications/push_notification_service.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import 'housing_invitation_status_dialog.dart';

/// Per-participant response to a housing proposal (local UI state until relay exists).
enum HousingInviteParticipantUiStatus {
  accepted,
  pending,
  negotiating,
  rejected,
}

class _ProposalUiState {
  const _ProposalUiState({
    required this.revisionId,
    required this.proposerParticipantId,
    required this.responsesByParticipantId,
    required this.payload,
  });

  final String? revisionId;
  final String proposerParticipantId;
  final Map<String, ProposalResponse> responsesByParticipantId;
  final Map<String, dynamic> payload;
}

/// Full-scroll proposal preview for the plan author, or read-only + response UI for an invitee.
class HousingInviteProposalScreen extends StatefulWidget {
  const HousingInviteProposalScreen({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    this.revisionId,
    this.onSendProposal,

    /// When non-null, this screen simulates that participant’s view (chips locked, response buttons).
    this.viewerParticipantIndex,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final String? revisionId;
  final Future<bool> Function(BuildContext context)? onSendProposal;

  /// Roster index (0 = plan author on device). Null = author preview / invitation prep.
  final int? viewerParticipantIndex;

  @override
  State<HousingInviteProposalScreen> createState() =>
      _HousingInviteProposalScreenState();
}

class _HousingInviteProposalScreenState
    extends State<HousingInviteProposalScreen> {
  late Future<List<dynamic>> _proposalFuture;

  int _focusedParticipantIndex = 0;

  final Map<int, HousingInviteParticipantUiStatus> _statusByRosterIndex = {};

  bool _negotiateExpanded = false;
  bool _sendingProposal = false;
  String? _displayRevisionId;
  Timer? _refreshTimer;
  final TextEditingController _negotiateController = TextEditingController();

  bool get _isAuthorPreview => widget.viewerParticipantIndex == null;

  bool get _isDraftSendPreview => widget.onSendProposal != null;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  void initState() {
    super.initState();
    _proposalFuture = _loadProposalScreenData();
    if (!_isAuthorPreview) {
      _focusedParticipantIndex = widget.viewerParticipantIndex!.clamp(0, 100);
    }
    if (!_isDraftSendPreview) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || _negotiateExpanded) return;
        setState(() {
          _proposalFuture = _loadProposalScreenData();
        });
      });
    }
  }

  Future<List<dynamic>> _loadProposalScreenData() {
    return Future.wait([
      widget.db.listParticipants(),
      widget.db.listPlanLines(widget.planId),
      widget.db.getAgreementForPlan(widget.planId),
      widget.db.listPlanRatios(widget.planId),
      widget.db.listPlanGroups(widget.planId),
      _loadProposalUiState(),
    ]);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _negotiateController.dispose();
    super.dispose();
  }

  int _rosterOrder(String id) {
    if (id.endsWith(':self')) return -1;
    final tail = id.split(':p').last;
    return int.tryParse(tail) ?? 999;
  }

  List<Participant> _sortedRoster(List<Participant> all) {
    final roster =
        all
            .where(
              (p) =>
                  p.id == '${widget.planId}:self' ||
                  p.id.startsWith('${widget.planId}:p'),
            )
            .toList()
          ..sort((a, b) => _rosterOrder(a.id).compareTo(_rosterOrder(b.id)));
    return roster;
  }

  HousingInviteParticipantUiStatus _statusFor(int rosterIndex) {
    return _statusByRosterIndex[rosterIndex] ??
        HousingInviteParticipantUiStatus.pending;
  }

  HousingInviteParticipantUiStatus _statusForParticipant(
    Participant participant,
    _ProposalUiState proposal,
  ) {
    final status = proposal.responsesByParticipantId[participant.id]?.status;
    return switch (status) {
      'accepted' => HousingInviteParticipantUiStatus.accepted,
      'negotiate' => HousingInviteParticipantUiStatus.negotiating,
      'rejected' => HousingInviteParticipantUiStatus.rejected,
      _ => HousingInviteParticipantUiStatus.pending,
    };
  }

  Future<_ProposalUiState> _loadProposalUiState() async {
    final pkg = await (widget.db.select(
      widget.db.proposalPackages,
    )..where((t) => t.planId.equals(widget.planId))).getSingleOrNull();
    final revisionId =
        widget.revisionId ??
        _displayRevisionId ??
        pkg?.pendingRevisionId ??
        pkg?.activeRevisionId;
    if (revisionId == null) {
      return const _ProposalUiState(
        revisionId: null,
        proposerParticipantId: '',
        responsesByParticipantId: <String, ProposalResponse>{},
        payload: <String, dynamic>{},
      );
    }
    await HousingProposalTransportService(widget.db).expireRevisionIfNeeded(
      planId: widget.planId,
      revisionId: revisionId,
    );
    final revision = await (widget.db.select(
      widget.db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingle();
    _displayRevisionId = revisionId;
    final responses = await (widget.db.select(
      widget.db.proposalResponses,
    )..where((t) => t.revisionId.equals(revisionId))).get();
    return _ProposalUiState(
      revisionId: revisionId,
      proposerParticipantId: revision.proposerParticipantId,
      responsesByParticipantId: {
        for (final response in responses) response.participantId: response,
      },
      payload: jsonDecode(revision.payloadJson) as Map<String, dynamic>,
    );
  }

  Future<void> _submitResponse(
    ProposalResponseStatus status, {
    String message = '',
    String? revisionId,
  }) async {
    final l10n = AppLocalizations.of(context);
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
      if (status == ProposalResponseStatus.negotiate &&
          result.failedParticipantIds.isNotEmpty) {
        await PushNotificationService.showLocalHousingResponseFailureNotification(
          errorCode: 'send_failed',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.housingInviteResponseSent)));
      setState(() {
        _proposalFuture = _loadProposalScreenData();
        _negotiateExpanded = false;
        _negotiateController.clear();
      });
      if (status == ProposalResponseStatus.negotiate) {
        if (mounted) context.go('/');
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
      if (status == ProposalResponseStatus.negotiate) {
        await PushNotificationService.showLocalHousingResponseFailureNotification(
          errorCode: 'local_error',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
      );
    }
  }

  Future<void> _sendFromPreview() async {
    final send = widget.onSendProposal;
    if (send == null || _sendingProposal) return;
    debugPrint('housing_proposal preview send tapped for ${widget.planId}');
    setState(() => _sendingProposal = true);
    final sent = await send(context);
    if (!mounted) return;
    setState(() => _sendingProposal = false);
    if (sent) _goBack();
  }

  void _cancelNegotiation() {
    setState(() {
      _negotiateExpanded = false;
      _negotiateController.clear();
    });
  }

  (Color bg, Color fg) _statusColors(
    ThemeData theme,
    HousingInviteParticipantUiStatus s,
  ) {
    switch (s) {
      case HousingInviteParticipantUiStatus.accepted:
        return (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        );
      case HousingInviteParticipantUiStatus.pending:
        return (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        );
      case HousingInviteParticipantUiStatus.negotiating:
        return (const Color(0xFFFFF9C4), const Color(0xFFF57F17));
      case HousingInviteParticipantUiStatus.rejected:
        return (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        );
    }
  }

  Widget _participantChip(
    AppLocalizations l10n,
    ThemeData theme,
    int index,
    String label,
    bool enabled,
    bool showParticipantStatus,
  ) {
    final isAuthorRoster = index == 0;
    final selected = _focusedParticipantIndex == index;
    final status = _statusFor(index);
    final (chipBg, chipFg) = isAuthorRoster
        ? (theme.colorScheme.surface, theme.colorScheme.onSurface)
        : (!showParticipantStatus
              ? (
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.onSurface,
                )
              : _statusColors(theme, status));
    final statusLabel = switch (status) {
      HousingInviteParticipantUiStatus.accepted =>
        l10n.housingInviteStatusAccepted,
      HousingInviteParticipantUiStatus.pending =>
        l10n.housingInviteStatusPending,
      HousingInviteParticipantUiStatus.negotiating =>
        l10n.housingInviteStatusNegotiating,
      HousingInviteParticipantUiStatus.rejected =>
        l10n.housingInviteStatusRejected,
    };

    return ChoiceChip(
      selected: selected,
      onSelected: enabled
          ? (v) {
              if (!v) return;
              setState(() => _focusedParticipantIndex = index);
            }
          : null,
      selectedColor: isAuthorRoster
          ? Colors.white
          : theme.colorScheme.primaryContainer,
      backgroundColor: chipBg,
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: chipFg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (showParticipantStatus && !isAuthorRoster)
              Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: chipFg.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingInviteProposalAppBarTitle)),
      body: FutureBuilder<List<dynamic>>(
        future: _proposalFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final roster = _sortedRoster(snap.data![0] as List<Participant>);
          final lines = snap.data![1] as List<PlanLine>;
          final agr = snap.data![2] as Agreement?;
          final ratios = snap.data![3] as List<PlanRatio>;
          final groups = snap.data![4] as List<PlanGroup>;
          final proposal = snap.data![5] as _ProposalUiState;
          if (agr == null || roster.isEmpty) {
            return Center(child: Text(l10n.housingPlanSummaryMissingAgreement));
          }
          final proposalAgreement = proposal.payload['agreement'] is Map
              ? (proposal.payload['agreement'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
          final proposalRulesJson = proposalAgreement['agreementRulesJson']
              ?.toString();
          final proposalClauses = proposalAgreement['clauses']?.toString();
          final rules = AgreementRulesDraft.parseStored(
            agreementRulesJson: proposalRulesJson ?? agr.agreementRulesJson,
            clausesFallback: proposalClauses ?? agr.clauses,
          );
          final pids = roster.map((p) => p.id).toList();
          final idx = pids.isEmpty
              ? 0
              : _focusedParticipantIndex.clamp(0, pids.length - 1);
          final selfParticipantId = '${widget.planId}:self';
          final isAuthor =
              _isDraftSendPreview ||
              proposal.proposerParticipantId == selfParticipantId;
          final selfStatus =
              proposal.responsesByParticipantId[selfParticipantId]?.status ??
              ProposalResponseStatus.pending.name;
          final revisionState = HousingProposalRevisionState.fromPayload(
            proposal.payload,
          );
          final canRespond = housingParticipantMayRespond(
            revision: revisionState,
            participantResponseStatus: selfStatus,
            proposerParticipantId: proposal.proposerParticipantId,
            participantId: selfParticipantId,
          );
          final expiresUtc = revisionState.responseExpiresAtUtc;
          final forkFromId = revisionState.forkedFromRevisionId;
          final showParticipantStatus = proposal.revisionId != null;
          final hasActivePlan =
              proposal.revisionId != null &&
              proposal.responsesByParticipantId.values.isNotEmpty &&
              proposal.responsesByParticipantId.values.every(
                (r) => r.status == ProposalResponseStatus.accepted.name,
              );
          if (hasActivePlan) {
            return const Center(child: Text('Plan actif'));
          }
          _statusByRosterIndex
            ..clear()
            ..addEntries(
              roster.indexed.map(
                (entry) => MapEntry(
                  entry.$1,
                  _statusForParticipant(entry.$2, proposal),
                ),
              ),
            );
          final dateFmt = effectiveDateFormat(widget.prefs);
          final dateRangeLine =
              '${formatPreferenceDate(agr.periodStart, dateFmt)}${l10n.housingInviteDateRangeSeparator}${formatPreferenceDate(agr.periodEnd, dateFmt)}';
          final sunSlices = buildInviteSunburstSlices(
            lines: lines,
            groups: groups,
            ratios: ratios,
            participantIdsOrdered: pids,
            participantId: pids[idx],
            l10n: l10n,
            displayCurrency: displayCurrencyCodeForPlan(widget.prefs, lines),
          );

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isAuthor) ...[
                      Text(
                        _isDraftSendPreview
                            ? l10n.housingInviteProposalIntroTitle
                            : l10n.housingInviteProposalSentIntroTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(height: 32),
                    ],
                    Center(
                      child: Text(
                        l10n.housingInviteHousingAgreementTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        dateRangeLine,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        formatContractCalendarDuration(
                          agr.periodStart,
                          agr.periodEnd,
                          l10n,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (expiresUtc != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          l10n.housingInviteResponseDeadlineLabel(
                            formatPreferenceDateTime(expiresUtc, dateFmt),
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Center(
                        child: Text(
                          l10n.housingInviteResponseDeadlineTimezone,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (forkFromId != null && forkFromId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          l10n.housingInviteForkedFromLabel(forkFromId),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (!isAuthor &&
                        !canRespond &&
                        selfStatus ==
                            ProposalResponseStatus.pending.name) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.housingInviteOfferClosedHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.housingInviteParticipantsSectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < roster.length; i++)
                          _participantChip(
                            l10n,
                            theme,
                            i,
                            roster[i].displayName,
                            true,
                            showParticipantStatus,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    HousingInviteSunburstChart(
                      l10n: l10n,
                      slices: sunSlices,
                      participantName: roster[idx].displayName,
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.tonal(
                          onPressed: () {
                            final dateFmt = effectiveDateFormat(widget.prefs);
                            final currency = displayCurrencyCodeForPlan(
                              widget.prefs,
                              lines,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    HousingProposalExpensesDetailScreen(
                                  db: widget.db,
                                  planId: widget.planId,
                                  participantIds: pids,
                                  participantNames: [
                                    for (final p in roster) p.displayName,
                                  ],
                                  defaultCurrency: currency,
                                  dateFormat: dateFmt,
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.housingInviteViewExpensesDetail),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    HousingAgreementRulesReadOnlyCard(
                      agr: agr,
                      rules: rules,
                      roster: roster,
                      displayCurrency: displayCurrencyCodeForPlan(
                        widget.prefs,
                        lines,
                      ),
                      firstDayOfWeekIndex: widget.prefs.resolvedFirstDayOfWeekIndex(
                        Localizations.localeOf(context),
                      ),
                    ),
                    if (!isAuthor && canRespond && !hasActivePlan) ...[
                      const SizedBox(height: 24),
                      if (!_negotiateExpanded) ...[
                        FilledButton(
                          onPressed: canRespond
                              ? () => _submitResponse(
                                  ProposalResponseStatus.accepted,
                                  revisionId: proposal.revisionId,
                                )
                              : null,
                          child: Text(l10n.housingInviteAcceptFull),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: canRespond
                              ? () => setState(() => _negotiateExpanded = true)
                              : null,
                          child: Text(l10n.housingInviteNegotiate),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: canRespond
                              ? () => _submitResponse(
                                  ProposalResponseStatus.rejected,
                                  revisionId: proposal.revisionId,
                                )
                              : null,
                          child: Text(l10n.housingInviteRejectBlock),
                        ),
                      ] else if (canRespond) ...[
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
                              revisionId: proposal.revisionId,
                            );
                          },
                          child: Text(l10n.commonSend),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _cancelNegotiation,
                          child: Text(l10n.commonCancel),
                        ),
                      ],
                    ],
                    SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isAuthor) ...[
                        OutlinedButton(
                          onPressed: _goBack,
                          child: Text(l10n.housingPlanBack),
                        ),
                        const SizedBox(height: 8),
                        if (_isDraftSendPreview)
                          FilledButton(
                            onPressed: _sendingProposal
                                ? null
                                : _sendFromPreview,
                            child: Text(l10n.housingPlanSummaryInvite),
                          )
                        else
                          FilledButton(
                            onPressed: () => showHousingInvitationStatusDialog(
                              context,
                              db: widget.db,
                              planId: widget.planId,
                              prefs: widget.prefs,
                              revisionId: proposal.revisionId,
                            ),
                            child: Text(
                              l10n.housingInviteInvitationStatusAction,
                            ),
                          ),
                      ] else ...[
                        if (!_negotiateExpanded) ...[
                          OutlinedButton(
                            onPressed: _goBack,
                            child: Text(l10n.housingPlanBack),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => showHousingInvitationStatusDialog(
                              context,
                              db: widget.db,
                              planId: widget.planId,
                              prefs: widget.prefs,
                              revisionId: proposal.revisionId,
                            ),
                            child: Text(
                              l10n.housingInviteInvitationStatusAction,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
