import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Maestro-facing [Semantics.identifier] values for housing proposal E2E (debug Android).
const kQaHousingWizardParticipantsStep = 'qa-housing-wizard-participants-step';
const kQaHousingWizardChooseContact = 'qa-housing-wizard-choose-contact';
const kQaHousingWizardDatesStep = 'qa-housing-wizard-dates-step';
const kQaHousingWizardExpensesStep = 'qa-housing-wizard-expenses-step';
const kQaHousingWizardRulesStep = 'qa-housing-wizard-rules-step';
const kQaHousingWizardSummarySubmit = 'qa-housing-wizard-summary-submit';
const kQaHousingInviteRecipientAccept = 'qa-housing-invite-recipient-accept';
const kQaHousingWorkbenchPendingRow = 'qa-housing-workbench-pending-row';
const kQaHousingInviteParticipantLouysQaAccepted =
    'qa-housing-invite-participant-louys-qa-accepted';

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
}) {
  if (!kDebugMode) return child;
  return Semantics(
    identifier: identifier,
    button: button,
    header: header,
    child: child,
  );
}
