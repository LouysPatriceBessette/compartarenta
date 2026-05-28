import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../prefs/app_preferences.dart';
import '../../screens/housing/housing_amendment_detail_screen.dart';
import '../../screens/housing/housing_invite_proposal_screen.dart';
import '../proposals/housing_proposal_transport_service.dart';
import 'housing_amendment_summary.dart';

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
  final hasActive = await transport.hasActiveRevision(planId);
  final openAmendment = isAmendment ||
      await pendingRevisionIsAmendment(
        db,
        planId,
        revisionId: revisionId,
      );
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
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
              revisionId: revisionId,
            ),
    ),
  );
}
