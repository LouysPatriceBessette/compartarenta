import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../prefs/app_preferences.dart';
import '../../screens/housing/housing_active_plan_screen.dart';
import '../../screens/housing/housing_amendment_detail_screen.dart';
import '../../screens/housing/housing_amendment_journal_screen.dart';
import '../../screens/housing/housing_invite_proposal_screen.dart';
import '../proposals/housing_proposal_transport_service.dart';
import 'housing_amendment_summary.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Replaces the current route with the active-plan hub when [planId] is in force.
///
/// Returns true when navigation ran.
Future<bool> openHousingActivePlanHubIfActive(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required AppPreferences prefs,
}) async {
  final transport = HousingProposalTransportService(db);
  if (!await transport.hasActiveRevision(planId)) return false;
  final packageId = await transport.primaryPackageIdForPlan(planId);
  if (packageId == null || !context.mounted) return false;
  await navigateToRoute<void>(context, 
    MaterialPageRoute<void>(
      builder: (_) => HousingActivePlanScreen(
        planId: planId,
        packageId: packageId,
        prefs: prefs,
      ),
    ),
  );
  return true;
}

/// Opens the amendment detail screen or the full-plan proposal screen.
Future<void> openHousingPendingProposalOrAmendment(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required AppPreferences prefs,
  String? revisionId,
  bool isAmendment = false,
}) async {
  final transport = HousingProposalTransportService(db);
  await transport.reconcileStalePackagePending(planId);
  final pendingId =
      revisionId ?? await transport.pendingRevisionIdForPlan(planId);
  if (pendingId == null) {
    if (!context.mounted) return;
    await openHousingActivePlanHubIfActive(
      context,
      db: db,
      planId: planId,
      prefs: prefs,
    );
    return;
  }
  final openAmendment =
      isAmendment ||
      await pendingRevisionIsAmendment(
        db,
        planId,
        revisionId: pendingId,
      );
  if (!context.mounted) return;
  await navigateToChildRoute<void>(context, 
    MaterialPageRoute<void>(
      builder: (_) => openAmendment
          ? HousingAmendmentDetailScreen(
              db: db,
              planId: planId,
              prefs: prefs,
              revisionId: pendingId,
            )
          : HousingInviteProposalScreen(
              db: db,
              planId: planId,
              prefs: prefs,
              revisionId: pendingId,
            ),
    ),
  );
}

/// Opens a settled (archived) amendment in read-only detail.
Future<void> openHousingSettledAmendmentDetail(
  BuildContext context, {
  required AppDatabase db,
  required String planId,
  required AppPreferences prefs,
  required String revisionId,
}) {
  return navigateToChildRoute<void>(context, 
    MaterialPageRoute<void>(
      builder: (_) => HousingAmendmentDetailScreen(
        db: db,
        planId: planId,
        prefs: prefs,
        revisionId: revisionId,
        readOnlySettled: true,
      ),
    ),
  );
}

/// Opens the settled-amendment journal (no pending-request banner).
Future<void> openHousingAmendmentJournal(
  BuildContext context, {
  required String planId,
  required AppPreferences prefs,
}) {
  return navigateToChildRoute<void>(context, 
    MaterialPageRoute<void>(
      builder: (_) => HousingAmendmentJournalScreen(
        planId: planId,
        prefs: prefs,
      ),
    ),
  );
}
