import '../../db/app_database.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';
import 'housing_participation_change_service.dart';
import 'housing_participation_membership_service.dart';

/// Hub tile enablement and banner visibility for participation changes.
class HousingParticipationHubGates {
  const HousingParticipationHubGates({
    required this.showParticipationBanner,
    this.participationBannerText,
    required this.enterExpenseEnabled,
    required this.requestAmendmentEnabled,
    required this.majorChangeEnabled,
    this.majorChangeSubtitle,
    required this.isPastAgreementForSelf,
    required this.pendingChangeId,
    this.pendingChangeKind,
    required this.isEjectionCandidate,
  });

  final bool showParticipationBanner;
  final String? participationBannerText;
  final bool enterExpenseEnabled;
  final bool requestAmendmentEnabled;
  final bool majorChangeEnabled;
  final String? majorChangeSubtitle;
  final bool isPastAgreementForSelf;
  final String? pendingChangeId;
  final HousingParticipationChangeKind? pendingChangeKind;
  final bool isEjectionCandidate;

  static Future<HousingParticipationHubGates> compute({
    required AppDatabase db,
    required String planId,
    required String selfParticipantId,
    required String Function({
      required String initiatorName,
      required String? targetName,
      required DateTime? departureDate,
    }) bannerTextBuilder,
    required String ejectionCandidateSubtitle,
  }) async {
    final membership = HousingParticipationMembershipService(db);
    await membership.ensureMembershipsForPlan(planId);
    final isPast =
        !await membership.isActiveMember(planId, selfParticipantId);

    if (isPast) {
      return HousingParticipationHubGates(
        showParticipationBanner: false,
        enterExpenseEnabled: false,
        requestAmendmentEnabled: false,
        majorChangeEnabled: false,
        isPastAgreementForSelf: true,
        pendingChangeId: null,
        isEjectionCandidate: false,
      );
    }

    final changeSvc = HousingParticipationChangeService(db);
    await changeSvc.applyDueVoluntaryWithdrawals(planId);
    final pending = await changeSvc.pendingForPlan(planId);
    final amendmentPending =
        await HousingProposalTransportService(db).hasPendingAmendmentForUi(
          planId,
        );

    if (pending == null) {
      return HousingParticipationHubGates(
        showParticipationBanner: false,
        enterExpenseEnabled: true,
        requestAmendmentEnabled: !amendmentPending,
        majorChangeEnabled: !amendmentPending,
        isPastAgreementForSelf: false,
        pendingChangeId: null,
        isEjectionCandidate: false,
      );
    }

    final kind = HousingParticipationChangeKind.fromWire(pending.kind);
    final roster = await participantsForPlan(db, planId);
    final initiatorName = displayNameForParticipant(
      pending.initiatorParticipantId,
      roster,
    );
    final targetName =
        pending.targetParticipantId == null
            ? null
            : displayNameForParticipant(pending.targetParticipantId!, roster);

    final isCandidate =
        kind == HousingParticipationChangeKind.ejection &&
        pending.targetParticipantId == selfParticipantId;

    final bannerText = bannerTextBuilder(
      initiatorName: initiatorName,
      targetName: targetName,
      departureDate: pending.departureDate,
    );

    return switch (kind) {
      HousingParticipationChangeKind.immediateTermination =>
        HousingParticipationHubGates(
          showParticipationBanner: true,
          participationBannerText: bannerText,
          enterExpenseEnabled: true,
          requestAmendmentEnabled: false,
          majorChangeEnabled: false,
          isPastAgreementForSelf: false,
          pendingChangeId: pending.id,
          pendingChangeKind: kind,
          isEjectionCandidate: false,
        ),
      HousingParticipationChangeKind.voluntaryWithdrawal =>
        HousingParticipationHubGates(
          showParticipationBanner: true,
          participationBannerText: bannerText,
          enterExpenseEnabled: true,
          requestAmendmentEnabled: true,
          majorChangeEnabled: false,
          isPastAgreementForSelf: false,
          pendingChangeId: pending.id,
          pendingChangeKind: kind,
          isEjectionCandidate: false,
        ),
      HousingParticipationChangeKind.ejection => HousingParticipationHubGates(
        showParticipationBanner: true,
        participationBannerText: bannerText,
        enterExpenseEnabled: !isCandidate,
        requestAmendmentEnabled: !isCandidate,
        majorChangeEnabled: !isCandidate,
        majorChangeSubtitle: isCandidate ? ejectionCandidateSubtitle : null,
        isPastAgreementForSelf: false,
        pendingChangeId: pending.id,
        pendingChangeKind: kind,
        isEjectionCandidate: isCandidate,
      ),
      null => HousingParticipationHubGates(
        showParticipationBanner: false,
        enterExpenseEnabled: true,
        requestAmendmentEnabled: !amendmentPending,
        majorChangeEnabled: !amendmentPending,
        isPastAgreementForSelf: false,
        pendingChangeId: null,
        isEjectionCandidate: false,
      ),
    };
  }
}
