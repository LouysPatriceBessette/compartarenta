import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_display.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/quiet_hours_week_grid.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format_money.dart';

/// Read-only agreement rules card (proposal preview, plan summary, invitee view).
class HousingAgreementRulesReadOnlyCard extends StatefulWidget {
  const HousingAgreementRulesReadOnlyCard({
    super.key,
    required this.agr,
    required this.rules,
    required this.roster,
    required this.displayCurrency,
    required this.firstDayOfWeekIndex,
  });

  final Agreement agr;
  final AgreementRulesDraft rules;
  final List<Participant> roster;
  final String displayCurrency;
  final int firstDayOfWeekIndex;

  @override
  State<HousingAgreementRulesReadOnlyCard> createState() =>
      _HousingAgreementRulesReadOnlyCardState();
}

class _HousingAgreementRulesReadOnlyCardState
    extends State<HousingAgreementRulesReadOnlyCard> {
  int _quietUiDayIndex = 0;

  String _displayNameForParticipantId(String id) {
    for (final p in widget.roster) {
      if (p.id == id) return p.displayName;
    }
    return id;
  }

  ({String title, String body}) _suggestionText(
    String suggestionId,
    String defaultTitle,
    String defaultBody,
  ) {
    final edit = widget.rules.suggestionEdits[suggestionId];
    if (edit == null) return (title: defaultTitle, body: defaultBody);
    return (
      title: edit.title.isEmpty ? defaultTitle : edit.title,
      body: agreementRuleBodyPlain(
        edit.body.isEmpty ? defaultBody : edit.body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perMap = () {
      try {
        final m =
            jsonDecode(widget.agr.withdrawalPerParticipantJson)
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
            grid: widget.rules.quietHalfHours,
            uiSelectedDayIndex: _quietUiDayIndex,
            onSelectDay: (i) => setState(() => _quietUiDayIndex = i),
            editing: false,
            onToggleCell: (_, _) {},
            labelAbsolute: l10n.housingQuietHoursAbsolute,
            labelModerate: l10n.housingQuietHoursModerate,
            emptyDayLabel: l10n.housingQuietHoursNoneThisDay,
            firstDayOfWeekIndex: widget.firstDayOfWeekIndex,
          ),
          if (!widget.rules.curfewEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: agreementRuleOffHint(context, l10n.housingInviteRuleOffHint),
            ),
        ],
      ),
      ExpansionTile(
        title: Text(l10n.housingAgreementRuleEarlyWithdrawalTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (!widget.rules.earlyWithdrawalEnabled)
            agreementRuleOffHint(context, l10n.housingInviteRuleOffHint)
          else ...[
            if (widget.agr.withdrawalSameForAll == 'true') ...[
              agreementRuleBodyText(
                context,
                '${l10n.housingPlanMinimumNoticeDays}: ${widget.agr.minNoticeDays}',
              ),
              agreementRuleBodyText(
                context,
                '${l10n.housingPlanPenaltyAmount}: ${formatMinorAsMoney(context, widget.agr.penaltyMinor, widget.displayCurrency)}',
              ),
            ] else ...[
              agreementRuleBodyText(
                context,
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
                    child: agreementRuleBodyText(
                      context,
                      '${_displayNameForParticipantId(e.key.toString())}: '
                      '${l10n.housingPlanMinimumNoticeDays} $notice; '
                      '${l10n.housingPlanPenaltyAmount} ${formatMinorAsMoney(context, pen, widget.displayCurrency)}',
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
          if (!widget.rules.buildingRulesEnabled)
            agreementRuleOffHint(context, l10n.housingInviteRuleOffHint)
          else
            agreementRuleBodyText(
              context,
              widget.rules.buildingRulesText.trim().isEmpty
                  ? widget.agr.clauses
                  : widget.rules.buildingRulesText,
            ),
        ],
      ),
    ];

    for (final r in widget.rules.customRules) {
      if (!r.enabled) continue;
      tiles.add(
        ExpansionTile(
          title: Text(
            r.title.isEmpty
                ? l10n.housingAgreementRuleCustomTitleLabel
                : r.title,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [agreementRuleBodyText(context, r.body)],
        ),
      );
    }

    void addSuggestionTile({
      required String suggestionId,
      required String defaultTitle,
      required String defaultBody,
    }) {
      if (widget.rules.dismissedSuggestionIds.contains(suggestionId)) return;
      if (!agreementSuggestionIsEnabled(widget.rules, suggestionId)) return;
      final text = _suggestionText(suggestionId, defaultTitle, defaultBody);
      final edited = agreementSuggestionWasEdited(
        widget.rules,
        suggestionId,
        defaultTitle: defaultTitle,
        defaultBody: defaultBody,
      );
      final title = edited
          ? text.title
          : '${l10n.housingAgreementSuggestionLabel}: ${text.title}';
      tiles.add(
        ExpansionTile(
          title: Text(title),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            agreementRuleBodyText(context, text.body),
          ],
        ),
      );
    }

    addSuggestionTile(
      suggestionId: kAgreementSuggestionCommonCleanliness,
      defaultTitle: l10n.housingAgreementSuggestionCleanlinessTitle,
      defaultBody: l10n.housingAgreementSuggestionCleanlinessBody,
    );
    addSuggestionTile(
      suggestionId: kAgreementSuggestionFridgeManagement,
      defaultTitle: l10n.housingAgreementSuggestionFridgeTitle,
      defaultBody: l10n.housingAgreementSuggestionFridgeBody,
    );

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
}
