import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('immediate termination limits relay to active members only', () {
    expect(
      HousingParticipationChangeKind.immediateTermination
          .relayBroadcastLimitedToActiveMembers,
      isTrue,
    );
    expect(
      HousingParticipationChangeKind.ejection.relayBroadcastLimitedToActiveMembers,
      isFalse,
    );
    expect(
      HousingParticipationChangeKind.voluntaryWithdrawal
          .relayBroadcastLimitedToActiveMembers,
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
