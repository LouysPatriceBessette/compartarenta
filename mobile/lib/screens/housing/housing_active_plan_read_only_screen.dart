import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/participation/housing_participation_membership_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_agreement_rules_read_only.dart';
import 'housing_invite_sunburst.dart';
import 'housing_proposal_expenses_detail_screen.dart';

/// Read-only view of the in-force plan (active agreement snapshot on device).
class HousingActivePlanReadOnlyScreen extends StatefulWidget {
  const HousingActivePlanReadOnlyScreen({
    super.key,
    required this.planId,
    required this.prefs,
  });

  final String planId;
  final AppPreferences prefs;

  @override
  State<HousingActivePlanReadOnlyScreen> createState() =>
      _HousingActivePlanReadOnlyScreenState();
}

class _HousingActivePlanReadOnlyScreenState
    extends State<HousingActivePlanReadOnlyScreen> {
  int _focusedParticipantIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final db = AppDatabase.processScope;
    final dateFmt = effectiveDateFormat(widget.prefs);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingActivePlanReadOnlyTitle)),
      body: FutureBuilder<_ReadOnlyPayload?>(
        future: _load(db, l10n, dateFmt),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            return Center(child: Text(l10n.housingRealizedExpenseLoadFailed));
          }
          final roster = data.roster;
          final pids = roster.map((p) => p.id).toList(growable: false);
          final focusIdx = pids.isEmpty
              ? 0
              : _focusedParticipantIndex.clamp(0, pids.length - 1);
          final focused = roster.isEmpty ? null : roster[focusIdx];
          final sunSlices = focused == null
              ? <InviteSunburstSlice>[]
              : buildInviteSunburstSlices(
                  lines: data.lines,
                  groups: data.groups,
                  ratios: data.ratios,
                  participantIdsOrdered: pids,
                  participantId: focused.id,
                  l10n: l10n,
                  displayCurrency: data.currency,
                );

          return ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              Text(
                l10n.housingActivePlanDatesLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                data.periodRange,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.housingInviteParticipantsSectionTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (roster.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < roster.length; i++)
                      ChoiceChip(
                        selected: focusIdx == i,
                        label: Text(roster[i].displayName),
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => _focusedParticipantIndex = i);
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              if (focused != null)
                HousingInviteSunburstChart(
                  l10n: l10n,
                  slices: sunSlices,
                  participantName: focused.displayName,
                ),
              if (data.lines.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => HousingProposalExpensesDetailScreen(
                            db: db,
                            planId: widget.planId,
                            participantIds: pids,
                            participantNames: [
                              for (final p in roster) p.displayName,
                            ],
                            defaultCurrency: data.currency,
                            dateFormat: dateFmt,
                          ),
                        ),
                      );
                    },
                    child: Text(l10n.housingInviteViewExpensesDetail),
                  ),
                ),
                if (sunburstSlicesHaveMonthlyNormalized(sunSlices))
                  HousingInviteSunburstMonthlyFootnote(l10n: l10n),
              ],
              const SizedBox(height: 20),
              HousingAgreementRulesReadOnlyCard(
                agr: data.agreement,
                rules: data.rules,
                roster: roster,
                displayCurrency: data.currency,
                firstDayOfWeekIndex: widget.prefs.resolvedFirstDayOfWeekIndex(
                  Localizations.localeOf(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_ReadOnlyPayload?> _load(
    AppDatabase db,
    AppLocalizations l10n,
    String dateFmt,
  ) async {
    final plan = await (db.select(db.plans)
          ..where((t) => t.id.equals(widget.planId)))
        .getSingleOrNull();
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (plan == null || agreement == null) return null;

    final participants = await HousingParticipationMembershipService(db)
        .activeParticipantsForPlan(widget.planId);
    final range =
        '${formatPreferenceDate(agreement.periodStart, dateFmt)}'
        ' – '
        '${formatPreferenceDate(agreement.periodEnd, dateFmt)}';
    final lines = await db.listPlanLines(widget.planId);
    final ratios = await db.listPlanRatios(widget.planId);
    final groups = await db.listPlanGroups(widget.planId);

    return _ReadOnlyPayload(
      periodRange: range,
      agreement: agreement,
      rules: AgreementRulesDraft.parseStored(
        agreementRulesJson: agreement.agreementRulesJson,
        clausesFallback: agreement.clauses,
      ),
      roster: participants,
      lines: lines,
      ratios: ratios,
      groups: groups,
      currency: displayCurrencyCodeForPlan(widget.prefs, lines),
    );
  }
}

class _ReadOnlyPayload {
  const _ReadOnlyPayload({
    required this.periodRange,
    required this.agreement,
    required this.rules,
    required this.roster,
    required this.lines,
    required this.ratios,
    required this.groups,
    required this.currency,
  });

  final String periodRange;
  final Agreement agreement;
  final AgreementRulesDraft rules;
  final List<Participant> roster;
  final List<PlanLine> lines;
  final List<PlanRatio> ratios;
  final List<PlanGroup> groups;
  final String currency;
}
