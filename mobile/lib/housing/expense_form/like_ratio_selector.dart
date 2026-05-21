import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_numbers.dart';
import 'expense_ratio_template_repository.dart';

/// Two-line dropdown for ratio templates ("Like").
class LikeRatioSelector extends StatelessWidget {
  const LikeRatioSelector({
    super.key,
    required this.templates,
    required this.participantIds,
    required this.selectedTemplateId,
    required this.onSelected,
  });

  final List<PlanRatioTemplate> templates;
  final List<String> participantIds;
  final String? selectedTemplateId;
  final ValueChanged<String?> onSelected;

  static const String blankValue = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (templates.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String?>(
      key: ValueKey<String?>(selectedTemplateId),
      initialValue: selectedTemplateId ?? blankValue,
      decoration: InputDecoration(labelText: l10n.housingExpenseLikeLabel),
      items: [
        DropdownMenuItem(
          value: blankValue,
          enabled: false,
          child: Text(
            l10n.housingExpenseLikeBlankHint,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        for (final t in templates)
          DropdownMenuItem(
            value: t.id,
            child: _TwoLineTemplateItem(
              title: t.displayTitle,
              weights: ExpenseRatioTemplateRepository.decodeWeights(
                t.weightsJson,
              ),
              participantIds: participantIds,
            ),
          ),
      ],
      onChanged: (v) {
        if (v == null || v == blankValue) return;
        onSelected(v);
      },
    );
  }
}

class _TwoLineTemplateItem extends StatelessWidget {
  const _TwoLineTemplateItem({
    required this.title,
    required this.weights,
    required this.participantIds,
  });

  final String title;
  final Map<String, int> weights;
  final List<String> participantIds;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    for (final pid in participantIds) {
      final w = weights[pid] ?? 0;
      parts.add(
        formatShareOfTotalPercentNoSuffix(
          context,
          shareNumeratorMinor: w,
          totalDenominatorMinor: ExpenseRatioTemplateRepository.weightScale,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Text(
          parts.join(' / '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
