import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voluntary withdrawal requires peer acknowledgement', () {
    expect(
      HousingParticipationChangeKind.voluntaryWithdrawal
          .requiresPeerAcknowledgement,
      isTrue,
    );
    expect(
      HousingParticipationChangeKind.ejection.requiresPeerAcknowledgement,
      isFalse,
    );
  });

  test('ejection requires unanimous vote', () {
    expect(HousingParticipationChangeKind.ejection.requiresUnanimousVote, isTrue);
    expect(
      HousingParticipationChangeKind.voluntaryWithdrawal.requiresUnanimousVote,
      isFalse,
    );
  });

  test('departure participant id uses initiator for voluntary withdrawal', () {
    expect(
      participationChangeDepartureParticipantId(
        kind: HousingParticipationChangeKind.voluntaryWithdrawal,
        initiatorParticipantId: 'plan:louys',
        targetParticipantId: 'plan:monica',
      ),
      'plan:louys',
    );
    expect(
      participationChangeDepartureParticipantId(
        kind: HousingParticipationChangeKind.ejection,
        initiatorParticipantId: 'plan:louys',
        targetParticipantId: 'plan:monica',
      ),
      'plan:monica',
    );
  });
}
