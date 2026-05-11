import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/projection/plan_projection.dart';
import '../../housing/quiet_hours_week_grid.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';

/// Per-participant response to a housing proposal (local UI state until relay exists).
enum HousingInviteParticipantUiStatus {
  accepted,
  pending,
  negotiating,
  rejected,
}

sealed class _InviteSplitEntry {}

final class _InviteSplitGroup extends _InviteSplitEntry {
  _InviteSplitGroup(this.group, this.memberLines);
  final PlanGroup group;
  final List<PlanLine> memberLines;
}

final class _InviteSplitUncategorized extends _InviteSplitEntry {
  _InviteSplitUncategorized(this.lines, {this.showHeading = true});
  final List<PlanLine> lines;
  final bool showHeading;
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
  State<HousingInviteProposalScreen> createState() => _HousingInviteProposalScreenState();
}

class _HousingInviteProposalScreenState extends State<HousingInviteProposalScreen> {
  int _focusedParticipantIndex = 0;
  int _previewQuietDayIndex = 0;

  /// Mock statuses for demo (no relay yet). Index aligns with sorted roster.
  final Map<int, HousingInviteParticipantUiStatus> _statusByRosterIndex = {};
  final Map<int, String> _negotiationMessageByIndex = {};

  bool _negotiateExpanded = false;
  final TextEditingController _negotiateController = TextEditingController();

  bool get _isAuthorPreview => widget.viewerParticipantIndex == null;

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
    final roster = all
        .where((p) => p.id == '${widget.planId}:self' || p.id.startsWith('${widget.planId}:p'))
        .toList()
      ..sort((a, b) => _rosterOrder(a.id).compareTo(_rosterOrder(b.id)));
    return roster;
  }

  List<_InviteSplitEntry> _splitEntries(List<PlanLine> lines, List<PlanGroup> groups) {
    final sorted = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final known = groups.map((g) => g.id).toSet();
    final out = <_InviteSplitEntry>[];
    for (final g in groups) {
      final inGroup = sorted.where((l) => l.groupId == g.id).toList();
      if (inGroup.isEmpty) continue;
      out.add(_InviteSplitGroup(g, inGroup));
    }
    final unc = sorted.where((l) {
      final gid = l.groupId;
      return gid == null || !known.contains(gid);
    }).toList();
    if (unc.isNotEmpty) {
      out.add(_InviteSplitUncategorized(unc, showHeading: groups.isNotEmpty));
    }
    return out;
  }

  int _groupBasisMinor(List<PlanLine> memberLines) =>
      memberLines.fold<int>(0, (a, l) => a + PlanProjection.unitMinor(l));

  int _weightLine(List<PlanRatio> ratios, String lineId, String pid) => ratios
      .where((r) => r.lineId == lineId && r.participantId == pid)
      .fold<int>(0, (a, r) => a + r.weight);

  int _weightGroup(List<PlanRatio> ratios, String groupId, String pid) => ratios
      .where((r) => r.groupId == groupId && r.participantId == pid)
      .fold<int>(0, (a, r) => a + r.weight);

  bool _participantInLine(List<PlanRatio> ratios, PlanLine line, List<String> pids, int idx) {
    final w = _weightLine(ratios, line.id, pids[idx]);
    return w > 0;
  }

  bool _participantInGroup(List<PlanRatio> ratios, PlanGroup group, List<String> pids, int idx) {
    final w = _weightGroup(ratios, group.id, pids[idx]);
    return w > 0;
  }

  HousingInviteParticipantUiStatus _statusFor(int rosterIndex) {
    if (rosterIndex == 0) return HousingInviteParticipantUiStatus.pending;
    return _statusByRosterIndex[rosterIndex] ?? HousingInviteParticipantUiStatus.pending;
  }

  bool _locksInviteeResponses(int rosterLength) {
    if (_isAuthorPreview) return false;
    final vi = widget.viewerParticipantIndex!;
    for (var i = 0; i < rosterLength; i++) {
      if (i == vi) continue;
      final s = _statusFor(i);
      if (s == HousingInviteParticipantUiStatus.negotiating ||
          s == HousingInviteParticipantUiStatus.rejected) {
        return true;
      }
    }
    return false;
  }

  (Color bg, Color fg) _statusColors(ThemeData theme, HousingInviteParticipantUiStatus s) {
    switch (s) {
      case HousingInviteParticipantUiStatus.accepted:
        return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer);
      case HousingInviteParticipantUiStatus.pending:
        return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer);
      case HousingInviteParticipantUiStatus.negotiating:
        return (const Color(0xFFFFF9C4), const Color(0xFFF57F17));
      case HousingInviteParticipantUiStatus.rejected:
        return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer);
    }
  }

  Widget _participantChip(
    AppLocalizations l10n,
    ThemeData theme,
    int index,
    String label,
    bool enabled,
  ) {
    final isAuthorRoster = index == 0;
    final selected = _focusedParticipantIndex == index;
    final status = _statusFor(index);
    final (chipBg, chipFg) = isAuthorRoster
        ? (theme.colorScheme.surface, theme.colorScheme.onSurface)
        : _statusColors(theme, status);
    final statusLabel = switch (status) {
      HousingInviteParticipantUiStatus.accepted => l10n.housingInviteStatusAccepted,
      HousingInviteParticipantUiStatus.pending => l10n.housingInviteStatusPending,
      HousingInviteParticipantUiStatus.negotiating => l10n.housingInviteStatusNegotiating,
      HousingInviteParticipantUiStatus.rejected => l10n.housingInviteStatusRejected,
    };

    return ChoiceChip(
      selected: selected,
      onSelected: enabled
          ? (v) {
              if (!v) return;
              setState(() => _focusedParticipantIndex = index);
            }
          : null,
      selectedColor: isAuthorRoster ? Colors.white : theme.colorScheme.primaryContainer,
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
            if (!isAuthorRoster)
              Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: chipFg.withOpacity(0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyLineCard(
    BuildContext context,
    PlanLine line,
    List<String> pids,
    List<PlanRatio> ratios,
    int idx,
  ) {
    final theme = Theme.of(context);
    final basis = PlanProjection.unitMinor(line);
    final pid = pids[idx];
    final w = _weightLine(ratios, line.id, pid);
    final shareMinor = (basis * w / 10000).round();
    final pct = basis > 0 ? (shareMinor / basis) * 100 : 0.0;
    final frac = (w / 10000.0).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(line.title, style: theme.textTheme.titleSmall)),
                Text(
                  '${(shareMinor / 100).toStringAsFixed(2)} / ${(basis / 100).toStringAsFixed(2)} ${line.currency}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('${pct.toStringAsFixed(1)}%', style: theme.textTheme.bodySmall),
                ),
              ),
            ),
            Slider(value: frac, onChanged: null),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyGroupCard(
    BuildContext context,
    PlanGroup group,
    List<PlanLine> memberLines,
    List<String> pids,
    List<PlanRatio> ratios,
    int idx,
  ) {
    final theme = Theme.of(context);
    final basis = _groupBasisMinor(memberLines);
    final currency = memberLines.isEmpty ? '' : memberLines.first.currency;
    final memberLabel = memberLines.map((l) => l.title).join(' · ');
    final pid = pids[idx];
    final w = _weightGroup(ratios, group.id, pid);
    final shareMinor = (basis * w / 10000).round();
    final pct = basis > 0 ? (shareMinor / basis) * 100 : 0.0;
    final frac = (w / 10000.0).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(shareMinor / 100).toStringAsFixed(2)} / ${(basis / 100).toStringAsFixed(2)} $currency',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            if (memberLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                memberLabel,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('${pct.toStringAsFixed(1)}%', style: theme.textTheme.bodySmall),
                ),
              ),
            ),
            Slider(value: frac, onChanged: null),
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
  ) {
    final theme = Theme.of(context);
    final perMap = () {
      try {
        final m = jsonDecode(agr.withdrawalPerParticipantJson) as Map<String, dynamic>?;
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
            onToggleCell: (_, __) {},
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
            Text(l10n.housingAgreementRuleEarlyWithdrawalDisabledHint, style: theme.textTheme.bodySmall)
          else ...[
            if (agr.withdrawalSameForAll == 'true') ...[
              Text('${l10n.housingPlanMinimumNoticeDays}: ${agr.minNoticeDays}'),
              Text('${l10n.housingPlanPenaltyAmount}: ${(agr.penaltyMinor / 100).toStringAsFixed(2)}'),
            ] else ...[
              Text(l10n.housingInviteWithdrawalPerParticipantIntro, style: theme.textTheme.bodySmall),
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
                      '${l10n.housingPlanPenaltyAmount} ${(pen / 100).toStringAsFixed(2)}',
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
          if (!rules.buildingRulesEnabled &&
              rules.buildingRulesText.trim().isEmpty &&
              agr.clauses.trim().isEmpty)
            Text(l10n.housingInviteRuleOffHint, style: theme.textTheme.bodySmall)
          else
            Text(
              rules.buildingRulesText.trim().isEmpty ? agr.clauses : rules.buildingRulesText,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    ];

    for (final r in rules.customRules) {
      if (!r.enabled) continue;
      tiles.add(
        ExpansionTile(
          title: Text(r.title.isEmpty ? l10n.housingAgreementRuleCustomTitleLabel : r.title),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(r.body, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (!rules.dismissedSuggestionIds.contains(kAgreementSuggestionCommonCleanliness)) {
      tiles.add(
        ExpansionTile(
          title: Text('${l10n.housingAgreementSuggestionLabel}: ${l10n.housingAgreementSuggestionCleanlinessTitle}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(l10n.housingAgreementSuggestionCleanlinessBody, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (!rules.dismissedSuggestionIds.contains(kAgreementSuggestionFridgeManagement)) {
      tiles.add(
        ExpansionTile(
          title: Text('${l10n.housingAgreementSuggestionLabel}: ${l10n.housingAgreementSuggestionFridgeTitle}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(l10n.housingAgreementSuggestionFridgeBody, style: theme.textTheme.bodyMedium),
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Future<void> _showCodesDialog(AppLocalizations l10n, List<Participant> roster) async {
    final rng = math.Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code() => List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();

    final coOnly = roster.where((p) => !p.id.endsWith(':self')).toList();
    final entries = <(String, String)>[];
    for (final p in coOnly) {
      entries.add((p.displayName, code()));
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.housingInviteCodesDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.housingInviteCodesDialogBody),
              const SizedBox(height: 12),
              for (final e in entries) ...[
                Text(e.$1, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 4),
                SelectableText(e.$2, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.housingPlanCancel),
          ),
          FilledButton(
            onPressed: () async {
              final buf = StringBuffer()..writeln(l10n.housingInviteCodesDialogTitle);
              for (final e in entries) {
                buf.writeln('${e.$1}: ${e.$2}');
              }
              await Clipboard.setData(ClipboardData(text: buf.toString()));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.housingInviteCodesCopied)),
                );
              }
            },
            child: Text(l10n.housingInviteCodesCopyAll),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = widget.prefs.dateFormat.isEmpty ? 'YYYY-MM-DD' : widget.prefs.dateFormat;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.housingInviteProposalAppBarTitle),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          widget.db.listParticipants(),
          widget.db.listPlanLines(widget.planId),
          widget.db.getAgreementForPlan(widget.planId),
          widget.db.listPlanRatios(widget.planId),
          widget.db.listPlanGroups(widget.planId),
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
          if (agr == null || roster.isEmpty) {
            return Center(child: Text(l10n.housingPlanSummaryMissingAgreement));
          }
          final rules = AgreementRulesDraft.parseStored(
            agreementRulesJson: agr.agreementRulesJson,
            clausesFallback: agr.clauses,
          );
          final pids = roster.map((p) => p.id).toList();
          _focusedParticipantIndex = _focusedParticipantIndex.clamp(0, pids.length - 1);
          if (!_isAuthorPreview) {
            _focusedParticipantIndex = widget.viewerParticipantIndex!.clamp(0, pids.length - 1);
          }

          final entries = _splitEntries(lines, groups);
          final idx = _focusedParticipantIndex;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l10n.housingInviteProposalIntroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.housingPlanPlanStart}: ${formatPreferenceDate(agr.periodStart, fmt)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '${l10n.housingPlanPlanEnd}: ${formatPreferenceDate(agr.periodEnd, fmt)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      formatContractCalendarDuration(agr.periodStart, agr.periodEnd, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.housingInviteParticipantsSectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                            _isAuthorPreview,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.housingInviteExpensesSectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...() {
                      final w = <Widget>[];
                      for (final e in entries) {
                        switch (e) {
                          case _InviteSplitGroup(:final group, :final memberLines):
                            if (_participantInGroup(ratios, group, pids, idx)) {
                              w.add(_readOnlyGroupCard(context, group, memberLines, pids, ratios, idx));
                            }
                          case _InviteSplitUncategorized(:final lines, :final showHeading):
                            if (showHeading &&
                                lines.any((ln) => _participantInLine(ratios, ln, pids, idx))) {
                              w.add(
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
                                  child: Text(
                                    l10n.housingPlanSplitNoCategory,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            }
                            for (final line in lines) {
                              if (!_participantInLine(ratios, line, pids, idx)) continue;
                              w.add(_readOnlyLineCard(context, line, pids, ratios, idx));
                            }
                        }
                      }
                      return w;
                    }(),
                    const SizedBox(height: 8),
                    _readOnlyRules(context, l10n, agr, rules, roster),
                    if (!_isAuthorPreview) ...[
                      const SizedBox(height: 24),
                      if (_locksInviteeResponses(roster.length)) ...[
                        Text(
                          l10n.housingInviteProposalLockedHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...[
                          for (var i = 0; i < roster.length; i++)
                            if (i != widget.viewerParticipantIndex &&
                                (_statusFor(i) == HousingInviteParticipantUiStatus.negotiating ||
                                    _statusFor(i) == HousingInviteParticipantUiStatus.rejected))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${roster[i].displayName}: ${_negotiationMessageByIndex[i]?.trim().isNotEmpty == true ? _negotiationMessageByIndex[i]! : _statusFor(i) == HousingInviteParticipantUiStatus.rejected ? l10n.housingInviteStatusRejected : l10n.housingInviteStatusNegotiating}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                        ],
                      ],
                      FilledButton(
                        onPressed: _locksInviteeResponses(roster.length)
                            ? null
                            : () => setState(() {
                                  _statusByRosterIndex[widget.viewerParticipantIndex!] =
                                      HousingInviteParticipantUiStatus.accepted;
                                }),
                        child: Text(l10n.housingInviteAcceptFull),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _locksInviteeResponses(roster.length)
                            ? null
                            : () => setState(() => _negotiateExpanded = !_negotiateExpanded),
                        child: Text(l10n.housingInviteNegotiate),
                      ),
                      if (_negotiateExpanded && !_locksInviteeResponses(roster.length)) ...[
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
                            setState(() {
                              _statusByRosterIndex[widget.viewerParticipantIndex!] =
                                  HousingInviteParticipantUiStatus.negotiating;
                              _negotiationMessageByIndex[widget.viewerParticipantIndex!] = t;
                              _negotiateExpanded = false;
                            });
                          },
                          child: Text(l10n.housingPlanSave),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: _locksInviteeResponses(roster.length)
                            ? null
                            : () => setState(() {
                                  _statusByRosterIndex[widget.viewerParticipantIndex!] =
                                      HousingInviteParticipantUiStatus.rejected;
                                }),
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
                      if (_isAuthorPreview) ...[
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.housingPlanBack),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _showCodesDialog(l10n, roster),
                          child: Text(l10n.housingInviteGenerateCodes),
                        ),
                      ] else
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.housingPlanBack),
                        ),
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
