/// Kind of major participation change.
enum HousingParticipationChangeKind {
  immediateTermination('immediate_termination'),
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

  bool get requiresUnanimousVote =>
      this == immediateTermination || this == ejection;

  /// Relay propose/decision/notify reaches every connected contact unless true.
  ///
  /// Only post-ejection major changes (e.g. immediate termination) exclude
  /// departed members; ejection itself must still reach the target.
  bool get relayBroadcastLimitedToActiveMembers =>
      this == immediateTermination;
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
