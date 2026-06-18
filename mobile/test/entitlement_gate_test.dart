import 'package:compartarenta/entitlement/entitlement_gate.dart';
import 'package:compartarenta/relay/envelopes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntitlementGate', () {
    test('isGatedKind covers housing kinds 5–9 only', () {
      expect(EntitlementGate.isGatedKind(EnvelopeKind.housingProposal), isTrue);
      expect(
        EntitlementGate.isGatedKind(EnvelopeKind.housingRealizedExpenseReject),
        isTrue,
      );
      expect(EntitlementGate.isGatedKind(EnvelopeKind.profileUpdate), isFalse);
      expect(
        EntitlementGate.isGatedKind(EnvelopeKind.housingParticipationChangePropose),
        isFalse,
      );
    });

    test('forHousing serializes relay gate metadata', () {
      final gate = EntitlementGate.forHousing(
        participantInstallationId: 'inst-alpha',
        planId: 'plan-1',
        kind: EnvelopeKind.housingRealizedExpenseAccept,
        expenseId: 'exp-9',
        decisionKind: 'accepted',
      );
      expect(gate.toJson(), {
        'module': 'housing',
        'participant_installation_id': 'inst-alpha',
        'plan_id': 'plan-1',
        'operation': 'housing_realized_expense_accept',
        'expense_id': 'exp-9',
        'decision_kind': 'accepted',
      });
    });
  });
}
