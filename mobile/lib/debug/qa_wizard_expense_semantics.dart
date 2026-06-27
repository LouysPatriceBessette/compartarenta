import 'package:flutter/foundation.dart';

/// Prefix for wizard expense row ids (`…-<slug>` from [PlanLine.title]).
const kQaWizardExpenseIdPrefix = 'qa-housing-wizard-expense-';

/// Fixture ids for `proposal_wizard_expenses`.
const kQaWizardExpenseLoyer = 'qa-housing-wizard-expense-loyer';
const kQaWizardExpenseElectricite = 'qa-housing-wizard-expense-electricite';
const kQaWizardExpenseInternet = 'qa-housing-wizard-expense-internet';

String qaWizardExpenseSemanticsId(String title) {
  assert(kDebugMode);
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return '$kQaWizardExpenseIdPrefix$slug';
}
