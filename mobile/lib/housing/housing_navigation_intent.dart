import 'package:flutter/foundation.dart';

/// Pending navigation after a housing notification tap.
class HousingNavigationIntent {
  HousingNavigationIntent._();

  static String? pendingRealizedExpenseReviewId;
  static final ValueNotifier<int> reviewRequestTick = ValueNotifier<int>(0);

  /// After a housing-proposal notification tap: open pending amendment UI.
  static String? pendingOpenAmendmentPlanId;
  static final ValueNotifier<int> openAmendmentTick = ValueNotifier<int>(0);

  /// After a housing-proposal notification tap: open proposal UI for [planId].
  static String? pendingOpenProposalPlanId;
  static final ValueNotifier<int> openProposalTick = ValueNotifier<int>(0);

  static void requestReview(String expenseId) {
    pendingRealizedExpenseReviewId = expenseId;
    reviewRequestTick.value = reviewRequestTick.value + 1;
  }

  static void requestOpenPendingAmendment(String planId) {
    pendingOpenAmendmentPlanId = planId;
    openAmendmentTick.value = openAmendmentTick.value + 1;
  }

  static void requestOpenPendingProposal(String planId) {
    pendingOpenProposalPlanId = planId;
    openProposalTick.value = openProposalTick.value + 1;
  }

  static String? takePendingReview() {
    final id = pendingRealizedExpenseReviewId;
    pendingRealizedExpenseReviewId = null;
    return id;
  }

  static String? takePendingOpenAmendmentPlanId() {
    final id = pendingOpenAmendmentPlanId;
    pendingOpenAmendmentPlanId = null;
    return id;
  }

  static String? takePendingOpenProposalPlanId() {
    final id = pendingOpenProposalPlanId;
    pendingOpenProposalPlanId = null;
    return id;
  }
}
