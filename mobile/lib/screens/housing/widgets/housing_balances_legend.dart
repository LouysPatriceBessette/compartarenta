import 'package:flutter/material.dart';

import '../../../housing/realized_expense/realized_expense_balance.dart';
import '../../../l10n/app_localizations.dart';
import '../../../util/format_money.dart';

class HousingBalancesLegend extends StatelessWidget {
  const HousingBalancesLegend({
    super.key,
    required this.participants,
    required this.modeData,
    required this.currency,
  });

  final List<HousingBalanceParticipant> participants;
  final HousingBalanceModeData modeData;
  final String currency;

  static const List<Color> _palette = [
    Color(0xFFD32F2F),
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameById = {
      for (final participant in participants)
        participant.participantId: participant.displayName,
    };
    final outgoingByParticipant = <String, List<PairwiseBalanceEntry>>{
      for (final participant in participants) participant.participantId: [],
    };
    for (final edge in modeData.edges) {
      outgoingByParticipant[edge.fromParticipantId]?.add(edge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.housingBalancesLegendTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < participants.length; i++) ...[
          _LegendRow(
            participant: participants[i],
            color: _palette[i % _palette.length],
            details: (outgoingByParticipant[participants[i].participantId] ??
                    const [])
                .map(
                  (edge) => l10n.housingBalancesOwesAmountTo(
                    formatMinorAsMoney(context, edge.amountMinor, currency),
                    nameById[edge.toParticipantId] ?? edge.toParticipantId,
                  ),
                )
                .toList(growable: false),
            emptyLabel: l10n.housingBalancesOwesNobody,
          ),
          if (i != participants.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

final class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.participant,
    required this.color,
    required this.details,
    required this.emptyLabel,
  });

  final HousingBalanceParticipant participant;
  final Color color;
  final List<String> details;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '${participant.letter} - ${participant.displayName}${participant.isInactive ? ' ${l10n.housingBalancesInactiveMarker}' : ''}',
                  style: textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (details.isEmpty)
              Text(emptyLabel, style: textTheme.bodyMedium)
            else
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(detail, style: textTheme.bodyMedium),
                ),
          ],
        ),
      ),
    );
  }
}
