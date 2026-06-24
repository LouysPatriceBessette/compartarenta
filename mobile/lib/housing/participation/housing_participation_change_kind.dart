/// Kind of major participation change.
enum HousingParticipationChangeKind {
  voluntaryWithdrawal('voluntary_withdrawal'),
  ejection('ejection');

  const HousingParticipationChangeKind(this.wireValue);

  final String wireValue;

  static HousingParticipationChangeKind? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final k in HousingParticipationChangeKind.values) {
      if (k.wireValue == value) return k;
    }
    return null;
  }

  bool get requiresUnanimousVote => this == ejection;

  /// Voluntary withdrawal: peers acknowledge notice (no reject); not a vote.
  bool get requiresPeerAcknowledgement =>
      this == HousingParticipationChangeKind.voluntaryWithdrawal;
}

/// Roster participant who leaves the plan for [kind], when applicable.
String? participationChangeDepartureParticipantId({
  required HousingParticipationChangeKind? kind,
  required String initiatorParticipantId,
  required String? targetParticipantId,
}) {
  return switch (kind) {
    HousingParticipationChangeKind.ejection => targetParticipantId,
    HousingParticipationChangeKind.voluntaryWithdrawal => initiatorParticipantId,
    null => null,
  };
}

/// Lifecycle status of a participation change request.
enum HousingParticipationChangeStatus {
  pending('pending'),
  effective('effective'),
  aborted('aborted');

  const HousingParticipationChangeStatus(this.wireValue);

  final String wireValue;

  static HousingParticipationChangeStatus? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in HousingParticipationChangeStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}

/// A decider's vote on a participation change.
enum HousingParticipationDecisionStatus {
  accepted('accepted'),
  rejected('rejected');

  const HousingParticipationDecisionStatus(this.wireValue);

  final String wireValue;

  static HousingParticipationDecisionStatus? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in HousingParticipationDecisionStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}

/// Per-participant membership in an active housing plan.
enum HousingPlanMembershipStatus {
  active('active'),
  departed('departed');

  const HousingPlanMembershipStatus(this.wireValue);

  final String wireValue;

  static HousingPlanMembershipStatus? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in HousingPlanMembershipStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
