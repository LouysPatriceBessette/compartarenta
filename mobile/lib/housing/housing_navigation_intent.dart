import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_root_navigator.dart';

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

  /// After a housing-decision notification tap: open settled amendment detail.
  static String? pendingOpenSettledAmendmentPlanId;
  static String? pendingOpenSettledAmendmentRevisionId;
  static final ValueNotifier<int> openSettledAmendmentTick = ValueNotifier<int>(0);

  /// After a participation-change notification tap: open detail screen.
  static String? pendingOpenParticipationChangeId;
  static String? pendingOpenParticipationChangePlanId;
  static final ValueNotifier<int> openParticipationChangeTick = ValueNotifier<int>(0);

  /// Bumps when [HousingModuleEntryScreen] should re-resolve hub / archive / plan.
  static final ValueNotifier<int> entryReloadTick = ValueNotifier<int>(0);

  /// While > 0, [_SummaryView] must not auto-navigate after a proposal settles
  /// (e.g. user opened a new draft plan on the root navigator).
  static int _suppressProposalSettledRedirectDepth = 0;

  /// [HousingPlanScreen] routes pushed with [pushPlanScreenRootOverlay].
  static int _rootOverlayPlanScreenDepth = 0;

  static bool get suppressProposalSettledRedirect =>
      _suppressProposalSettledRedirectDepth > 0;

  static bool get hasRootOverlayPlanScreen => _rootOverlayPlanScreenDepth > 0;

  static void pushSuppressProposalSettledRedirect() {
    _suppressProposalSettledRedirectDepth++;
  }

  static void popSuppressProposalSettledRedirect() {
    if (_suppressProposalSettledRedirectDepth > 0) {
      _suppressProposalSettledRedirectDepth--;
    }
  }

  static void requestEntryReload() {
    entryReloadTick.value = entryReloadTick.value + 1;
  }

  /// Opens [HousingPlanScreen] above the module (archive / workbench flows).
  static Future<T?> pushPlanScreenRootOverlay<T>(
    BuildContext context,
    Route<T> route,
  ) {
    _rootOverlayPlanScreenDepth++;
    return Navigator.of(context, rootNavigator: true)
        .push(route)
        .whenComplete(() {
          if (_rootOverlayPlanScreenDepth > 0) {
            _rootOverlayPlanScreenDepth--;
          }
        });
  }

  /// Remounts [/housing] so [HousingModuleEntryScreen] re-resolves, and pops a
  /// root-pushed [HousingPlanScreen] overlay when present.
  static void remountHousingModule(BuildContext context) {
    if (hasRootOverlayPlanScreen) {
      final rootNav = Navigator.of(context, rootNavigator: true);
      if (rootNav.canPop()) {
        rootNav.pop();
      }
    }
    final rootCtx = appRootNavigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) {
      GoRouter.of(rootCtx).go('/housing');
    }
    requestEntryReload();
  }

  /// After a housing proposal settles (accepted → hub, rejected → archive).
  static void onProposalSettled(BuildContext context) {
    if (suppressProposalSettledRedirect) {
      assert(() {
        debugPrint(
          'housing: proposal settled redirect suppressed (depth=$_suppressProposalSettledRedirectDepth)',
        );
        return true;
      }());
      return;
    }
    remountHousingModule(context);
  }

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

  static void requestOpenSettledAmendmentDetail({
    required String planId,
    required String revisionId,
  }) {
    pendingOpenSettledAmendmentPlanId = planId;
    pendingOpenSettledAmendmentRevisionId = revisionId;
    openSettledAmendmentTick.value = openSettledAmendmentTick.value + 1;
  }

  static void requestOpenParticipationChangeDetail({
    required String planId,
    required String changeId,
  }) {
    pendingOpenParticipationChangePlanId = planId;
    pendingOpenParticipationChangeId = changeId;
    openParticipationChangeTick.value = openParticipationChangeTick.value + 1;
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

  static ({String planId, String revisionId})? takePendingOpenSettledAmendment() {
    final planId = pendingOpenSettledAmendmentPlanId;
    final revisionId = pendingOpenSettledAmendmentRevisionId;
    pendingOpenSettledAmendmentPlanId = null;
    pendingOpenSettledAmendmentRevisionId = null;
    if (planId == null ||
        planId.isEmpty ||
        revisionId == null ||
        revisionId.isEmpty) {
      return null;
    }
    return (planId: planId, revisionId: revisionId);
  }

  static ({String planId, String changeId})? takePendingOpenParticipationChange() {
    final planId = pendingOpenParticipationChangePlanId;
    final changeId = pendingOpenParticipationChangeId;
    pendingOpenParticipationChangePlanId = null;
    pendingOpenParticipationChangeId = null;
    if (planId == null ||
        planId.isEmpty ||
        changeId == null ||
        changeId.isEmpty) {
      return null;
    }
    return (planId: planId, changeId: changeId);
  }
}
