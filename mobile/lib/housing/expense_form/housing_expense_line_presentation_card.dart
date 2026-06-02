import 'package:flutter/material.dart';

import 'expense_plan_line_form_body.dart';
import 'expense_plan_line_view_data.dart';
import '../amendment/housing_amendment_line_edit_highlight.dart';

/// Read-only expense line card (same layout as plan expense detail carousel).
class HousingExpenseLinePresentationCard extends StatelessWidget {
  const HousingExpenseLinePresentationCard({
    super.key,
    required this.viewData,
    this.highlightFields,
  });

  final ExpensePlanLineViewData viewData;
  final Set<HousingAmendmentLineEditHighlightField>? highlightFields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlights = highlightFields;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpensePlanLineFormBody.presentation(
          viewData: viewData,
          highlightPredicate: highlights == null
              ? null
              : lineEditHighlightPredicate(highlights),
          highlightColor: highlights == null
              ? null
              : housingAmendmentLineEditHighlightColor,
        ),
      ),
    );
  }
}
