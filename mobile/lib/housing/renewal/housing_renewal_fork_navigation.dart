import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../housing_navigation_intent.dart';
import '../housing_plan_id.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../../prefs/app_preferences.dart';
import '../../screens/housing/housing_plan_screen.dart';

/// Forks the active revision into a new draft plan and opens the editor.
Future<void> startHousingRenewalForkFromActiveRevision({
  required BuildContext context,
  required AppDatabase db,
  required String listPlanId,
  required AppPreferences prefs,
}) async {
  final draftPlanId = newHousingPlanId();
  HousingNavigationIntent.navigateSuppressProposalSettledRedirect();
  try {
    await HousingProposalTransportService(db).createForkDraftFromActiveRevision(
      listPlanId: listPlanId,
      draftPlanId: draftPlanId,
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;
    await HousingNavigationIntent.navigateToPlanScreenRootOverlay<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HousingPlanScreen(
          prefs: prefs,
          planId: draftPlanId,
          openEditorInitially: true,
        ),
      ),
    );
    await HousingProposalTransportService(db).revealDraftEntry(
      listPlanId: listPlanId,
      draftPlanId: draftPlanId,
    );
  } finally {
    HousingNavigationIntent.popSuppressProposalSettledRedirect();
  }
}
