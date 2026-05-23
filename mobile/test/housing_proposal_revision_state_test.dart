import 'package:compartarenta/housing/proposals/housing_proposal_revision_state.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('participant may respond while open and before expiry', () {
    final revision = HousingProposalRevisionState.fromPayload({
      'lifecycleState': 'open',
      'responseExpiresAt':
          DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
    });
    expect(
      housingParticipantMayRespond(
        revision: revision,
        participantResponseStatus: ProposalResponseStatus.pending.name,
        proposerParticipantId: 'plan:self',
        participantId: 'plan:p0',
      ),
      isTrue,
    );
  });

  test('participant may not respond after expiry', () {
    final revision = HousingProposalRevisionState.fromPayload({
      'lifecycleState': 'open',
      'responseExpiresAt':
          DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
    });
    expect(revision.isExpiredByClock, isTrue);
    expect(
      housingParticipantMayRespond(
        revision: revision,
        participantResponseStatus: ProposalResponseStatus.pending.name,
        proposerParticipantId: 'plan:self',
        participantId: 'plan:p0',
      ),
      isFalse,
    );
  });

  test('fork metadata does not imply inherited expiry', () {
    final revision = HousingProposalRevisionState.fromPayload({
      'lifecycleState': 'open',
      'forkedFromRevisionId': 'rev:parent',
      'forkedFromPackageId': 'pkg:parent',
    });
    expect(revision.responseExpiresAtUtc, isNull);
    expect(revision.forkedFromRevisionId, 'rev:parent');
  });
}
