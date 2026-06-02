import 'package:compartarenta/housing/expense_form/expense_plan_line_form_snapshot.dart';
import 'package:compartarenta/housing/expense_form/expense_recurrence_spec.dart';
import 'package:compartarenta/housing/expense_form/expense_split_grid_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpensePlanLineFormSnapshot', () {
    ExpenseSplitGridState splitWithWeights(Map<String, int> weights) {
      final ids = weights.keys.toList();
      final state = ExpenseSplitGridState(
        participantIds: ids,
        displayNames: ids,
        rows: [
          for (final id in ids)
            ExpenseSplitRow(
              participantId: id,
              displayName: id,
              amountMinor: 0,
              weightBps: weights[id]!,
            ),
        ],
        totalMinor: 10000,
      );
      return state..applyWeights(weights);
    }

    test('detects title change', () {
      const baseline = ExpensePlanLineFormSnapshot(
        titleTrim: 'Rent',
        descriptionTrim: '',
        amountMinor: 10000,
        isRecurring: false,
        amountIsBudgetCap: false,
        paymentResponsibleId: null,
        recurrenceEncoded: null,
        weightBpsByParticipant: {'p1': 5000, 'p2': 5000},
        selectedTemplateId: null,
      );
      final current = ExpensePlanLineFormSnapshot.fromFormState(
        title: 'Rent updated',
        description: '',
        amountMinor: 10000,
        isRecurring: false,
        amountIsBudgetCap: false,
        paymentResponsibleId: null,
        recurrence: null,
        split: splitWithWeights({'p1': 5000, 'p2': 5000}),
        selectedTemplateId: null,
      );
      expect(current == baseline, isFalse);
    });

    test('detects split weight change', () {
      final split = splitWithWeights({'p1': 5000, 'p2': 5000});
      final baseline = ExpensePlanLineFormSnapshot.fromFormState(
        title: 'Rent',
        description: '',
        amountMinor: 10000,
        isRecurring: false,
        amountIsBudgetCap: false,
        paymentResponsibleId: null,
        recurrence: null,
        split: split,
        selectedTemplateId: null,
      );
      final current = ExpensePlanLineFormSnapshot.fromFormState(
        title: 'Rent',
        description: '',
        amountMinor: 10000,
        isRecurring: false,
        amountIsBudgetCap: false,
        paymentResponsibleId: null,
        recurrence: null,
        split: splitWithWeights({'p1': 7000, 'p2': 3000}),
        selectedTemplateId: null,
      );
      expect(current == baseline, isFalse);
    });

    test('matches identical form state', () {
      final split = splitWithWeights({'p1': 5000, 'p2': 5000});
      final spec = MonthlyDayRecurrence(day: 15);
      final baseline = ExpensePlanLineFormSnapshot.fromFormState(
        title: ' Rent ',
        description: ' note ',
        amountMinor: 10000,
        isRecurring: true,
        amountIsBudgetCap: true,
        paymentResponsibleId: 'plan:p0',
        recurrence: spec,
        split: split,
        selectedTemplateId: 'tpl-1',
      );
      final current = ExpensePlanLineFormSnapshot.fromFormState(
        title: 'Rent',
        description: 'note',
        amountMinor: 10000,
        isRecurring: true,
        amountIsBudgetCap: true,
        paymentResponsibleId: 'plan:p0',
        recurrence: spec,
        split: split,
        selectedTemplateId: 'tpl-1',
      );
      expect(current, baseline);
    });
  });
}
