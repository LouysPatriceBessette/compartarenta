import 'package:compartarenta/housing/amendment/housing_amendment_line_edit_highlight.dart';
import 'package:compartarenta/housing/expense_form/expense_plan_line_view_data.dart';
import 'package:flutter_test/flutter_test.dart';

ExpensePlanLineViewData _view({
  String title = 'Renta',
  String description = '',
  bool isRecurring = false,
  String? recurrenceSummary,
  String amountText = '715.0 CAD',
  bool amountIsBudgetCap = false,
  String paymentLabel = 'All',
  String? likeTemplateTitle,
}) {
  return ExpensePlanLineViewData(
    title: title,
    description: description,
    isRecurring: isRecurring,
    recurrenceSummary: recurrenceSummary,
    amountText: amountText,
    amountIsBudgetCap: amountIsBudgetCap,
    paymentResponsibleLabel: paymentLabel,
    split: null,
    likeTemplateTitle: likeTemplateTitle,
    currencyCode: 'CAD',
  );
}

void main() {
  test('diffLineEditHighlightFields detects amount change only', () {
    final baseline = _view(amountText: '715.0 CAD');
    final proposed = _view(amountText: '755.0 CAD');
    final fields = diffLineEditHighlightFields(
      baseline: baseline,
      proposed: proposed,
    );
    expect(fields, {HousingAmendmentLineEditHighlightField.amount});
  });

  test('diffLineEditHighlightFields ignores unchanged fields', () {
    final baseline = _view();
    final proposed = _view();
    expect(
      diffLineEditHighlightFields(baseline: baseline, proposed: proposed),
      isEmpty,
    );
  });

  test('lineEditHighlightPredicate maps enum keys to form field keys', () {
    final predicate = lineEditHighlightPredicate({
      HousingAmendmentLineEditHighlightField.amount,
    });
    expect(predicate, isNotNull);
    expect(predicate!('amount'), isTrue);
    expect(predicate('title'), isFalse);
  });
}
