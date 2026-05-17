import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/quiet_hours_week_grid.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import 'housing_invite_sunburst.dart';
import '../../l10n/app_localizations.dart';
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
  });

  final String? revisionId;
  final String proposerParticipantId;
  final Map<String, ProposalResponse> responsesByParticipantId;
}

/// Full-scroll proposal preview for the plan author, or read-only + response UI for an invitee.
class HousingInviteProposalScreen extends StatefulWidget {
  const HousingInviteProposalScreen({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,

    /// When non-null, this screen simulates that participant’s view (chips locked, response buttons).
    this.viewerParticipantIndex,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;

  /// Roster index (0 = plan author on device). Null = author preview / invitation prep.
  final int? viewerParticipantIndex;

  @override
  State<HousingInviteProposalScreen> createState() =>
      _HousingInviteProposalScreenState();
}

class _HousingInviteProposalScreenState
    extends State<HousingInviteProposalScreen> {
  int _focusedParticipantIndex = 0;
  int _previewQuietDayIndex = 0;

  final Map<int, HousingInviteParticipantUiStatus> _statusByRosterIndex = {};

  bool _negotiateExpanded = false;
  final TextEditingController _negotiateController = TextEditingController();

  bool get _isAuthorPreview => widget.viewerParticipantIndex == null;

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
    if (!_isAuthorPreview) {
      _focusedParticipantIndex = widget.viewerParticipantIndex!.clamp(0, 100);
    }
  }

  @override
  void dispose() {
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
    final revisionId = pkg?.pendingRevisionId ?? pkg?.activeRevisionId;
    if (revisionId == null) {
      return const _ProposalUiState(
        revisionId: null,
        proposerParticipantId: '',
        responsesByParticipantId: <String, ProposalResponse>{},
      );
    }
    final revision = await (widget.db.select(
      widget.db.proposalRevisions,
    )..where((t) => t.id.equals(revisionId))).getSingle();
    final responses = await (widget.db.select(
      widget.db.proposalResponses,
    )..where((t) => t.revisionId.equals(revisionId))).get();
    return _ProposalUiState(
      revisionId: revisionId,
      proposerParticipantId: revision.proposerParticipantId,
      responsesByParticipantId: {
        for (final response in responses) response.participantId: response,
      },
    );
  }

  Future<void> _submitResponse(
    ProposalResponseStatus status, {
    String message = '',
  }) async {
    final l10n = AppLocalizations.of(context);
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('relay'))),
      );
      return;
    }
    try {
      await orchestrator.sendHousingProposalResponse(
        planId: widget.planId,
        status: status,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.housingInviteResponseSent)));
      setState(() {
        _negotiateExpanded = false;
        _negotiateController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
      );
    }
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

  String _displayNameForParticipantId(String id, List<Participant> roster) {
    for (final p in roster) {
      if (p.id == id) return p.displayName;
    }
    return id;
  }

  Widget _readOnlyRules(
    BuildContext context,
    AppLocalizations l10n,
    Agreement agr,
    AgreementRulesDraft rules,
    List<Participant> roster,
    String displayCurrency,
  ) {
    final theme = Theme.of(context);
    final perMap = () {
      try {
        final m =
            jsonDecode(agr.withdrawalPerParticipantJson)
                as Map<String, dynamic>?;
        return m ?? {};
      } catch (_) {
        return <String, dynamic>{};
      }
    }();

    final tiles = <Widget>[
      ExpansionTile(
        title: Text(l10n.housingAgreementRuleCurfewTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          QuietHoursWeekDayEditor(
            grid: rules.quietHalfHours,
            uiSelectedDayIndex: _previewQuietDayIndex,
            onSelectDay: (i) => setState(() => _previewQuietDayIndex = i),
            editing: false,
            onToggleCell: (_, _) {},
            labelAbsolute: l10n.housingQuietHoursAbsolute,
            labelModerate: l10n.housingQuietHoursModerate,
            emptyDayLabel: l10n.housingQuietHoursNoneThisDay,
          ),
          if (!rules.curfewEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.housingInviteRuleOffHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
      ExpansionTile(
        title: Text(l10n.housingAgreementRuleEarlyWithdrawalTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (!rules.earlyWithdrawalEnabled)
            Text(
              l10n.housingInviteRuleOffHint,
              style: theme.textTheme.bodySmall,
            )
          else ...[
            if (agr.withdrawalSameForAll == 'true') ...[
              Text(
                '${l10n.housingPlanMinimumNoticeDays}: ${agr.minNoticeDays}',
              ),
              Text(
                '${l10n.housingPlanPenaltyAmount}: ${formatMinorAsMoney(context, agr.penaltyMinor, displayCurrency)}',
              ),
            ] else ...[
              Text(
                l10n.housingInviteWithdrawalPerParticipantIntro,
                style: theme.textTheme.bodySmall,
              ),
              if (perMap.isNotEmpty)
                ...perMap.entries.map((e) {
                  final v = e.value;
                  if (v is! Map) return const SizedBox.shrink();
                  final notice = (v['minNoticeDays'] as num?)?.toInt() ?? 0;
                  final pen = (v['penaltyMinor'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_displayNameForParticipantId(e.key.toString(), roster)}: '
                      '${l10n.housingPlanMinimumNoticeDays} $notice; '
                      '${l10n.housingPlanPenaltyAmount} ${formatMinorAsMoney(context, pen, displayCurrency)}',
                    ),
                  );
                }),
            ],
          ],
        ],
      ),
      ExpansionTile(
        title: Text(l10n.housingAgreementRuleBuildingTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (!rules.buildingRulesEnabled)
            Text(
              l10n.housingInviteRuleOffHint,
              style: theme.textTheme.bodySmall,
            )
          else
            Text(
              rules.buildingRulesText.trim().isEmpty
                  ? agr.clauses
                  : rules.buildingRulesText,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    ];

    for (final r in rules.customRules) {
      if (!r.enabled) continue;
      tiles.add(
        ExpansionTile(
          title: Text(
            r.title.isEmpty
                ? l10n.housingAgreementRuleCustomTitleLabel
                : r.title,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [Text(r.body, style: theme.textTheme.bodyMedium)],
        ),
      );
    }

    if (!rules.dismissedSuggestionIds.contains(
      kAgreementSuggestionCommonCleanliness,
    )) {
      tiles.add(
        ExpansionTile(
          title: Text(
            '${l10n.housingAgreementSuggestionLabel}: ${l10n.housingAgreementSuggestionCleanlinessTitle}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(
              l10n.housingAgreementSuggestionCleanlinessBody,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    if (!rules.dismissedSuggestionIds.contains(
      kAgreementSuggestionFridgeManagement,
    )) {
      tiles.add(
        ExpansionTile(
          title: Text(
            '${l10n.housingAgreementSuggestionLabel}: ${l10n.housingAgreementSuggestionFridgeTitle}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(
              l10n.housingAgreementSuggestionFridgeBody,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.housingInviteRulesSectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...tiles,
        ],
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
        future: Future.wait([
          widget.db.listParticipants(),
          widget.db.listPlanLines(widget.planId),
          widget.db.getAgreementForPlan(widget.planId),
          widget.db.listPlanRatios(widget.planId),
          widget.db.listPlanGroups(widget.planId),
          _loadProposalUiState(),
        ]),
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
          final rules = AgreementRulesDraft.parseStored(
            agreementRulesJson: agr.agreementRulesJson,
            clausesFallback: agr.clauses,
          );
          final pids = roster.map((p) => p.id).toList();
          _focusedParticipantIndex = _focusedParticipantIndex.clamp(
            0,
            pids.length - 1,
          );
          if (!_isAuthorPreview) {
            _focusedParticipantIndex = widget.viewerParticipantIndex!.clamp(
              0,
              pids.length - 1,
            );
          }

          final idx = _focusedParticipantIndex;
          final selfParticipantId = '${widget.planId}:self';
          final isAuthor = proposal.proposerParticipantId == selfParticipantId;
          final selfStatus =
              proposal.responsesByParticipantId[selfParticipantId]?.status ??
              ProposalResponseStatus.pending.name;
          final canRespond =
              !isAuthor && selfStatus == ProposalResponseStatus.pending.name;
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
          const dateIso = 'YYYY-MM-DD';
          final dateRangeLine =
              '${formatPreferenceDate(agr.periodStart, dateIso)}${l10n.housingInviteDateRangeSeparator}${formatPreferenceDate(agr.periodEnd, dateIso)}';
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
                    Text(
                      l10n.housingInviteProposalIntroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 32),
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
                            false,
                            showParticipantStatus,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    HousingInviteSunburstChart(l10n: l10n, slices: sunSlices),
                    const SizedBox(height: 20),
                    _readOnlyRules(
                      context,
                      l10n,
                      agr,
                      rules,
                      roster,
                      displayCurrencyCodeForPlan(widget.prefs, lines),
                    ),
                    if (!isAuthor && !hasActivePlan) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: canRespond
                            ? () => _submitResponse(
                                ProposalResponseStatus.accepted,
                              )
                            : null,
                        child: Text(l10n.housingInviteAcceptFull),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: canRespond
                            ? () => setState(
                                () => _negotiateExpanded = !_negotiateExpanded,
                              )
                            : null,
                        child: Text(l10n.housingInviteNegotiate),
                      ),
                      if (_negotiateExpanded && canRespond) ...[
                        const SizedBox(height: 8),
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
                          child: Text(l10n.housingPlanSave),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: canRespond
                            ? () => _submitResponse(
                                ProposalResponseStatus.rejected,
                              )
                            : null,
                        child: Text(l10n.housingInviteRejectBlock),
                      ),
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
                        FilledButton(
                          onPressed: () => showHousingInvitationStatusDialog(
                            context,
                            db: widget.db,
                            planId: widget.planId,
                            prefs: widget.prefs,
                          ),
                          child: Text(l10n.housingInviteInvitationStatusAction),
                        ),
                      ] else ...[
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
        },
      ),
    );
  }
}
