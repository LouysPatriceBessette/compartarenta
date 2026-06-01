import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_diff.dart';
import '../../housing/agreement_rules_display.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/quiet_hours_week_grid.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format_money.dart';

/// Read-only agreement rules card (proposal preview, plan summary, invitee view).
class HousingAgreementRulesReadOnlyCard extends StatefulWidget {
  const HousingAgreementRulesReadOnlyCard({
    super.key,
    this.agr,
    required this.rules,
    required this.roster,
    required this.displayCurrency,
    required this.firstDayOfWeekIndex,
    this.onlyRule,
    this.agreementOverride,
    this.compact = false,
    this.contentOnly = false,
    this.embedded = false,
    this.accordionOnlyRule = false,
  });

  /// Required unless [agreementOverride] is set (amendment before/after cards).
  final Agreement? agr;
  final AgreementRulesDraft rules;
  final List<Participant> roster;
  final String displayCurrency;
  final int firstDayOfWeekIndex;

  /// When set, renders only this rule (amendment detail).
  final AgreementRuleIdentity? onlyRule;

  /// Payload agreement slice for amendment before/after cards.
  final AgreementRulesAgreementSlice? agreementOverride;

  /// Hides the section heading when showing a single rule.
  final bool compact;

  /// When [onlyRule] is set with [compact], omits the enabled/disabled header
  /// (e.g. parent accordion tile already shows status).
  final bool contentOnly;

  /// Renders rule body without an outer [Card] (e.g. inside an accordion).
  final bool embedded;

  /// When [onlyRule] is set with [compact], status + title on an
  /// [ExpansionTile] header; body fields revealed on expand.
  final bool accordionOnlyRule;

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

  Widget _ruleExpansionTitle(
    BuildContext context,
    AppLocalizations l10n,
    AgreementRulesDraft rules,
    AgreementRuleIdentity identity,
    String title,
  ) {
    if (widget.onlyRule == null) {
      return Text(title);
    }
    return agreementRuleCardTitleColumn(
      context: context,
      l10n: l10n,
      enabled: isAgreementRuleEnabled(rules, identity),
      title: title,
    );
  }

  bool get _flatSingleRuleDetail =>
      widget.onlyRule != null &&
      widget.compact &&
      !widget.accordionOnlyRule;

  bool get _accordionSingleRuleDetail =>
      widget.onlyRule != null &&
      widget.compact &&
      widget.accordionOnlyRule;

  Widget _buildRuleTile({
    required AgreementRuleIdentity identity,
    required String title,
    required AgreementRulesDraft rules,
    required List<Widget> body,
  }) {
    if (_accordionSingleRuleDetail) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: _ruleExpansionTitle(
            context,
            AppLocalizations.of(context),
            rules,
            identity,
            title,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: body,
        ),
      );
    }
    if (_flatSingleRuleDetail) {
      final padding = widget.embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 12, 16, 12);
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.contentOnly) ...[
              Text(
                agreementRuleEnabledStatusLabel(
                  AppLocalizations.of(context),
                  isAgreementRuleEnabled(rules, identity),
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...body,
          ],
        ),
      );
    }
    return ExpansionTile(
      title: _ruleExpansionTitle(
        context,
        AppLocalizations.of(context),
        rules,
        identity,
        title,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: body,
    );
  }

  bool _matchesOnly(AgreementRuleIdentity identity) {
    final only = widget.onlyRule;
    if (only == null) return true;
    return switch (only) {
      AgreementRuleBuiltinIdentity(:final kind) =>
        identity is AgreementRuleBuiltinIdentity && identity.kind == kind,
      AgreementRuleSuggestionIdentity(:final suggestionId) =>
        (identity is AgreementRuleSuggestionIdentity &&
            identity.suggestionId == suggestionId) ||
        (identity is AgreementRuleCustomIdentity &&
            identity.ruleId ==
                agreementCustomRuleIdForSuggestion(suggestionId)),
      AgreementRuleCustomIdentity(:final ruleId) =>
        identity is AgreementRuleCustomIdentity && identity.ruleId == ruleId,
    };
  }

  String get _clausesText =>
      widget.agreementOverride?.clauses ?? widget.agr?.clauses ?? '';

  int get _minNoticeDays =>
      widget.agreementOverride?.minNoticeDays ?? widget.agr?.minNoticeDays ?? 0;

  int get _penaltyMinor =>
      widget.agreementOverride?.penaltyMinor ?? widget.agr?.penaltyMinor ?? 0;

  String get _withdrawalSameForAll =>
      widget.agreementOverride?.withdrawalSameForAll ??
      widget.agr?.withdrawalSameForAll ??
      'true';

  String get _withdrawalPerParticipantJson =>
      widget.agreementOverride?.withdrawalPerParticipantJson ??
      widget.agr?.withdrawalPerParticipantJson ??
      '{}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = normalizeAgreementRulesForComparison(widget.rules, l10n);
    final perMap = () {
      try {
        final m = jsonDecode(_withdrawalPerParticipantJson)
            as Map<String, dynamic>?;
        return m ?? {};
      } catch (_) {
        return <String, dynamic>{};
      }
    }();

    final tiles = <Widget>[];
    if (_matchesOnly(const AgreementRuleIdentity.builtin(
      AgreementRuleBuiltinKind.curfew,
    ))) {
      tiles.add(
        _buildRuleTile(
          identity: const AgreementRuleIdentity.builtin(
            AgreementRuleBuiltinKind.curfew,
          ),
          title: l10n.housingAgreementRuleCurfewTitle,
          rules: rules,
          body: [
            QuietHoursWeekDayEditor(
              grid: rules.quietHalfHours,
              uiSelectedDayIndex: _quietUiDayIndex,
              onSelectDay: (i) => setState(() => _quietUiDayIndex = i),
              editing: false,
              onToggleCell: (_, _) {},
              labelAbsolute: l10n.housingQuietHoursAbsolute,
              labelModerate: l10n.housingQuietHoursModerate,
              emptyDayLabel: l10n.housingQuietHoursNoneThisDay,
              firstDayOfWeekIndex: widget.firstDayOfWeekIndex,
            ),
            if (!rules.curfewEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: agreementRuleOffHint(
                  context,
                  l10n.housingInviteRuleOffHint,
                ),
              ),
          ],
        ),
      );
    }
    if (_matchesOnly(const AgreementRuleIdentity.builtin(
      AgreementRuleBuiltinKind.earlyWithdrawal,
    ))) {
      tiles.add(
        _buildRuleTile(
          identity: const AgreementRuleIdentity.builtin(
            AgreementRuleBuiltinKind.earlyWithdrawal,
          ),
          title: l10n.housingAgreementRuleEarlyWithdrawalTitle,
          rules: rules,
          body: [
            if (!rules.earlyWithdrawalEnabled)
              agreementRuleOffHint(context, l10n.housingInviteRuleOffHint)
            else ...[
              if (_withdrawalSameForAll == 'true') ...[
                agreementRuleBodyText(
                  context,
                  '${l10n.housingPlanMinimumNoticeDays}: $_minNoticeDays',
                ),
                agreementRuleBodyText(
                  context,
                  '${l10n.housingPlanPenaltyAmount}: ${formatMinorAsMoney(context, _penaltyMinor, widget.displayCurrency)}',
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
      );
    }
    if (_matchesOnly(const AgreementRuleIdentity.builtin(
      AgreementRuleBuiltinKind.building,
    ))) {
      tiles.add(
        _buildRuleTile(
          identity: const AgreementRuleIdentity.builtin(
            AgreementRuleBuiltinKind.building,
          ),
          title: l10n.housingAgreementRuleBuildingTitle,
          rules: rules,
          body: [
            if (!rules.buildingRulesEnabled)
              agreementRuleOffHint(context, l10n.housingInviteRuleOffHint)
            else
              agreementRuleBodyText(
                context,
                rules.buildingRulesText.trim().isEmpty
                    ? _clausesText
                    : rules.buildingRulesText,
              ),
          ],
        ),
      );
    }

    for (final r in rules.customRules) {
      final identity = AgreementRuleIdentity.custom(r.id);
      if (!_matchesOnly(identity)) continue;
      if (!r.enabled && widget.onlyRule == null) continue;
      final customTitle = r.title.isEmpty
          ? l10n.housingAgreementRuleCustomTitleLabel
          : r.title;
      tiles.add(
        _buildRuleTile(
          identity: identity,
          title: customTitle,
          rules: rules,
          body: [agreementRuleBodyText(context, r.body)],
        ),
      );
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact)
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
    );

    if (widget.embedded) return column;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: column,
    );
  }
}
