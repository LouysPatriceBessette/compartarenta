import 'package:flutter/foundation.dart';

import 'expense_recurrence_spec.dart';
import 'expense_split_grid_logic.dart';

/// Comparable form state for amendment edit (detect changes vs loaded line).
@immutable
final class ExpensePlanLineFormSnapshot {
  const ExpensePlanLineFormSnapshot({
    required this.titleTrim,
    required this.descriptionTrim,
    required this.amountMinor,
    required this.isRecurring,
    required this.amountIsBudgetCap,
    required this.paymentResponsibleId,
    required this.recurrenceEncoded,
    required this.weightBpsByParticipant,
    required this.selectedTemplateId,
  });

  final String titleTrim;
  final String descriptionTrim;
  final int? amountMinor;
  final bool isRecurring;
  final bool amountIsBudgetCap;
  final String? paymentResponsibleId;
  final String? recurrenceEncoded;
  final Map<String, int> weightBpsByParticipant;
  final String? selectedTemplateId;

  factory ExpensePlanLineFormSnapshot.fromFormState({
    required String title,
    required String description,
    required int? amountMinor,
    required bool isRecurring,
    required bool amountIsBudgetCap,
    required String? paymentResponsibleId,
    required ExpenseRecurrenceSpec? recurrence,
    required ExpenseSplitGridState? split,
    required String? selectedTemplateId,
  }) {
    return ExpensePlanLineFormSnapshot(
      titleTrim: title.trim(),
      descriptionTrim: description.trim(),
      amountMinor: amountMinor,
      isRecurring: isRecurring,
      amountIsBudgetCap: amountIsBudgetCap,
      paymentResponsibleId: paymentResponsibleId,
      recurrenceEncoded: isRecurring && recurrence != null
          ? ExpenseRecurrenceSpec.encode(recurrence)
          : null,
      weightBpsByParticipant: _weightsFromSplit(split),
      selectedTemplateId: selectedTemplateId,
    );
  }

  static Map<String, int> _weightsFromSplit(ExpenseSplitGridState? split) {
    if (split == null) return const {};
    return {
      for (final row in split.rows) row.participantId: row.weightBps,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensePlanLineFormSnapshot &&
        titleTrim == other.titleTrim &&
        descriptionTrim == other.descriptionTrim &&
        amountMinor == other.amountMinor &&
        isRecurring == other.isRecurring &&
        amountIsBudgetCap == other.amountIsBudgetCap &&
        paymentResponsibleId == other.paymentResponsibleId &&
        recurrenceEncoded == other.recurrenceEncoded &&
        selectedTemplateId == other.selectedTemplateId &&
        mapEquals(weightBpsByParticipant, other.weightBpsByParticipant);
  }

  @override
  int get hashCode => Object.hash(
        titleTrim,
        descriptionTrim,
        amountMinor,
        isRecurring,
        amountIsBudgetCap,
        paymentResponsibleId,
        recurrenceEncoded,
        selectedTemplateId,
        Object.hashAllUnordered(weightBpsByParticipant.entries),
      );
}
