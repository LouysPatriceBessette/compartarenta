import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Maestro-facing [Semantics.identifier] values for housing proposal E2E (debug Android).
const kQaHousingWizardParticipantsStep = 'qa-housing-wizard-participants-step';
const kQaHousingWizardChooseContact = 'qa-housing-wizard-choose-contact';
const kQaHousingWizardNext = 'qa-housing-wizard-next';
const kQaHousingWizardAddExpense = 'qa-housing-wizard-add-expense';
const kQaHousingWizardDatesStep = 'qa-housing-wizard-dates-step';
const kQaHousingWizardExpensesStep = 'qa-housing-wizard-expenses-step';
const kQaHousingWizardRulesStep = 'qa-housing-wizard-rules-step';
const kQaHousingWizardSummarySubmit = 'qa-housing-wizard-summary-submit';
const kQaHousingWizardSummary = 'qa-housing-wizard-summary';
const kQaHousingInviteProposalScreen = 'qa-housing-invite-proposal-screen';
const kQaHousingInviteResponseDeadlineDialog =
    'qa-housing-invite-response-deadline-dialog';
const kQaHousingInviteResponseDeadlineContinue =
    'qa-housing-invite-response-deadline-continue';
const kQaHousingInviteRecipientAccept = 'qa-housing-invite-recipient-accept';
const kQaHousingWorkbenchPendingRow = 'qa-housing-workbench-pending-row';
const kQaHousingInviteParticipantLouysQaAccepted =
    'qa-housing-invite-participant-louys-qa-accepted';
const kQaHousingActiveHub = 'qa-housing-active-hub';
const kQaHousingHubBack = 'qa-housing-hub-back';
const kQaHousingHubJournals = 'qa-housing-hub-journals';
const kQaHousingJournalsMonthlyExpenses =
    'qa-housing-journals-monthly-expenses';
const kQaHousingBeforeDueJournalCard = 'qa-housing-before-due-journal-card';
const kQaHousingOverdueJournalCard = 'qa-housing-overdue-journal-card';
/// AppBar title « Dépenses acceptées » / Accepted expenses on monthly journal.
const kQaHousingMonthlyExpensesScreen = 'qa-housing-monthly-expenses-screen';
const kQaHousingExpensesMonthPrev = 'qa-housing-expenses-month-prev';
const kQaHousingExpensesMonthNext = 'qa-housing-expenses-month-next';

/// Stable chip id when [displayName] has accepted (invitation status row).
String qaHousingInviteParticipantAcceptedSemanticsId(String displayName) {
  final slug = displayName
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'qa-housing-invite-participant-${slug.isEmpty ? 'unnamed' : slug}-accepted';
}

/// Step header [Semantics.identifier] for wizard steps 1–3 (participants uses its own anchor).
String? qaHousingWizardStepHeaderId(int stepIndex) {
  if (!kDebugMode) return null;
  return switch (stepIndex) {
    1 => kQaHousingWizardDatesStep,
    2 => kQaHousingWizardExpensesStep,
    3 => kQaHousingWizardRulesStep,
    _ => null,
  };
}

Widget qaHousingProposalSemantics({
  required String identifier,
  required Widget child,
  bool button = false,
  bool header = false,
  VoidCallback? onTap,
  bool? enabled,
}) {
  if (!kDebugMode) return child;
  final semanticsEnabled = enabled ?? true;
  return Semantics(
    identifier: identifier,
    button: button,
    header: header,
    enabled: enabled,
    excludeSemantics: button,
    onTap: button && semanticsEnabled ? onTap : null,
    child: child,
  );
}
