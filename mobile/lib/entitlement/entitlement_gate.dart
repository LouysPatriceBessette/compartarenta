import '../relay/envelopes.dart';

/// Minimal relay-visible metadata for housing entitlement gating (kinds 5–9).
class EntitlementGate {
  const EntitlementGate({
    required this.module,
    required this.participantInstallationId,
    required this.planId,
    this.operation,
    this.expenseId,
    this.revisionId,
    this.decisionKind,
  });

  final String module;
  final String participantInstallationId;
  final String planId;
  final String? operation;
  final String? expenseId;
  final String? revisionId;
  final String? decisionKind;

  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'participant_installation_id': participantInstallationId,
      'plan_id': planId,
      if (operation != null && operation!.isNotEmpty) 'operation': operation,
      if (expenseId != null && expenseId!.isNotEmpty) 'expense_id': expenseId,
      if (revisionId != null && revisionId!.isNotEmpty)
        'revision_id': revisionId,
      if (decisionKind != null && decisionKind!.isNotEmpty)
        'decision_kind': decisionKind,
    };
  }

  static bool isGatedKind(int kind) {
    switch (kind) {
      case EnvelopeKind.housingProposal:
      case EnvelopeKind.housingProposalResponse:
      case EnvelopeKind.housingRealizedExpensePropose:
      case EnvelopeKind.housingRealizedExpenseAccept:
      case EnvelopeKind.housingRealizedExpenseReject:
        return true;
      default:
        return false;
    }
  }

  static String operationForKind(int kind) {
    switch (kind) {
      case EnvelopeKind.housingProposal:
        return 'housing_proposal';
      case EnvelopeKind.housingProposalResponse:
        return 'housing_proposal_response';
      case EnvelopeKind.housingRealizedExpensePropose:
        return 'housing_realized_expense_propose';
      case EnvelopeKind.housingRealizedExpenseAccept:
        return 'housing_realized_expense_accept';
      case EnvelopeKind.housingRealizedExpenseReject:
        return 'housing_realized_expense_reject';
      default:
        return '';
    }
  }

  factory EntitlementGate.forHousing({
    required String participantInstallationId,
    required String planId,
    required int kind,
    String? expenseId,
    String? revisionId,
    String? decisionKind,
  }) {
    return EntitlementGate(
      module: 'housing',
      participantInstallationId: participantInstallationId,
      planId: planId,
      operation: operationForKind(kind),
      expenseId: expenseId,
      revisionId: revisionId,
      decisionKind: decisionKind,
    );
  }
}
