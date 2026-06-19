// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../housing/housing_navigation_intent.dart';
import '../relay/handshake_orchestrator.dart';

Future<void> showHousingBrowserNotification({
  required String title,
  required String body,
  String? expenseId,
  String? openProposalPlanId,
  String? openAmendmentPlanId,
  String? openParticipationChangePlanId,
  String? openParticipationChangeId,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  debugPrint(
    'housing_browser_notification: show title=$title '
    'proposalPlanId=${openProposalPlanId ?? '-'} '
    'amendmentPlanId=${openAmendmentPlanId ?? '-'}',
  );
  final notification = html.Notification(title, body: body);
  notification.onClick.listen((_) async {
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator != null) {
      await orchestrator.pollSteadyStateInboxes().catchError((
        Object e,
        StackTrace st,
      ) {
        debugPrint('housing browser notification click poll: $e\n$st');
      });
    }
    if (expenseId != null && expenseId.isNotEmpty) {
      HousingNavigationIntent.requestReview(expenseId);
    } else if (openProposalPlanId != null && openProposalPlanId.isNotEmpty) {
      HousingNavigationIntent.requestOpenPendingProposal(openProposalPlanId);
    } else if (openAmendmentPlanId != null && openAmendmentPlanId.isNotEmpty) {
      HousingNavigationIntent.requestOpenPendingAmendment(openAmendmentPlanId);
    } else if (openParticipationChangePlanId != null &&
        openParticipationChangePlanId.isNotEmpty &&
        openParticipationChangeId != null &&
        openParticipationChangeId.isNotEmpty) {
      HousingNavigationIntent.requestOpenParticipationChangeDetail(
        planId: openParticipationChangePlanId,
        changeId: openParticipationChangeId,
      );
    }
    html.window.location.hash = '/housing';
    notification.close();
  });
}
