import 'package:flutter/material.dart';

import '../expense_form/expense_plan_line_view_data.dart';
import '../expense_form/expense_split_grid_logic.dart';

/// Fields that can be highlighted in a line-edit amendment expense detail.
enum HousingAmendmentLineEditHighlightField {
  title,
  description,
  recurring,
  recurrence,
  amount,
  amountType,
  payment,
  split,
  likeTemplate,
}

/// Semi-transparent yellow used for changed values in line-edit detail cards.
const housingAmendmentLineEditHighlightColor = Color(0x66FFEB3B);

Set<HousingAmendmentLineEditHighlightField> diffLineEditHighlightFields({
  required ExpensePlanLineViewData baseline,
  required ExpensePlanLineViewData proposed,
}) {
  final out = <HousingAmendmentLineEditHighlightField>{};
  if (baseline.title.trim() != proposed.title.trim()) {
    out.add(HousingAmendmentLineEditHighlightField.title);
  }
  if (baseline.description.trim() != proposed.description.trim()) {
    out.add(HousingAmendmentLineEditHighlightField.description);
  }
  if (baseline.isRecurring != proposed.isRecurring) {
    out.add(HousingAmendmentLineEditHighlightField.recurring);
  }
  if ((baseline.recurrenceSummary ?? '').trim() !=
      (proposed.recurrenceSummary ?? '').trim()) {
    out.add(HousingAmendmentLineEditHighlightField.recurrence);
  }
  if (baseline.amountText.trim() != proposed.amountText.trim()) {
    out.add(HousingAmendmentLineEditHighlightField.amount);
  }
  if (baseline.amountIsBudgetCap != proposed.amountIsBudgetCap) {
    out.add(HousingAmendmentLineEditHighlightField.amountType);
  }
  if (baseline.paymentResponsibleLabel.trim() !=
      proposed.paymentResponsibleLabel.trim()) {
    out.add(HousingAmendmentLineEditHighlightField.payment);
  }
  if ((baseline.likeTemplateTitle ?? '').trim() !=
      (proposed.likeTemplateTitle ?? '').trim()) {
    out.add(HousingAmendmentLineEditHighlightField.likeTemplate);
  }
  if (!_splitWeightsEqual(baseline.split, proposed.split)) {
    out.add(HousingAmendmentLineEditHighlightField.split);
  }
  return out;
}

bool _splitWeightsEqual(
  ExpenseSplitGridState? a,
  ExpenseSplitGridState? b,
) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.rows.length != b.rows.length) return false;
  for (var i = 0; i < a.rows.length; i++) {
    if (a.rows[i].participantId != b.rows[i].participantId) return false;
    if (a.rows[i].weightBps != b.rows[i].weightBps) return false;
  }
  return true;
}

const _lineEditHighlightFieldKeys = {
  HousingAmendmentLineEditHighlightField.title: 'title',
  HousingAmendmentLineEditHighlightField.description: 'description',
  HousingAmendmentLineEditHighlightField.recurring: 'recurring',
  HousingAmendmentLineEditHighlightField.recurrence: 'recurrence',
  HousingAmendmentLineEditHighlightField.amount: 'amount',
  HousingAmendmentLineEditHighlightField.amountType: 'amountType',
  HousingAmendmentLineEditHighlightField.payment: 'payment',
  HousingAmendmentLineEditHighlightField.split: 'split',
  HousingAmendmentLineEditHighlightField.likeTemplate: 'likeTemplate',
};

bool Function(String fieldKey)? lineEditHighlightPredicate(
  Set<HousingAmendmentLineEditHighlightField> fields,
) {
  if (fields.isEmpty) return null;
  final keys = fields.map((f) => _lineEditHighlightFieldKeys[f]!).toSet();
  return (fieldKey) => keys.contains(fieldKey);
}
