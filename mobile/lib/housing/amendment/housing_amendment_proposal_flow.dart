import 'package:flutter/material.dart';

import '../../activity/relay_activity_log_service.dart';
import '../../app_root_navigator.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import 'housing_amendment_navigation.dart';
import '../housing_response_deadline_dialog.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../proposals/plan_agreement_proposal_service.dart';
import 'housing_amendment_type.dart';

/// Creates and sends a single-change amendment revision for an active plan.
class HousingAmendmentProposalFlow {
  HousingAmendmentProposalFlow(this._db);

  final AppDatabase _db;

  Future<bool> submitAmendment({
    required BuildContext context,
    required String planId,
    required AppPreferences prefs,
    required HousingAmendmentType amendmentType,
    String? targetLineId,
    void Function(Map<String, dynamic> payload)? patchRevisionPayload,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (await HousingProposalTransportService(_db).hasOpenPendingAmendment(planId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingAmendmentPendingBlocks)),
        );
      }
      return false;
    }
    if (!context.mounted) return false;

    final selected = await showHousingResponseDeadlineDialog(context);
    if (selected == null || !context.mounted) return false;

    final notificationResult = await const NotificationFlowPermissionTrigger()
        .ensure(
          context: context,
          prefs: prefs,
          switches: const {
            NotificationFlowSwitch.housingDecisionChange,
            NotificationFlowSwitch.housingOfferExpiration,
          },
        );
    if (notificationResult == NotificationFlowPermissionResult.abortFlow ||
        !context.mounted) {
      return false;
    }

    final pkg = await (_db.select(_db.proposalPackages)
          ..where((t) => t.planId.equals(planId)))
        .getSingleOrNull();
    final activeRevisionId = pkg?.activeRevisionId;
    final fork = activeRevisionId == null
        ? null
        : (
            packageId: pkg!.id,
            revisionId: activeRevisionId,
          );

    final proposerId = '$planId:self';
    late final String revisionId;
    try {
      revisionId = await PlanAgreementProposalService(_db)
          .createRevisionFromCurrentDraft(
            planId: planId,
            proposerParticipantId: proposerId,
            responseExpiresAt: DateTime.now().toUtc().add(selected),
            forkedFromPackageId: fork?.packageId,
            forkedFromRevisionId: fork?.revisionId,
          );
      await HousingProposalTransportService(_db).updateRevisionPayload(
        revisionId: revisionId,
        mutate: (payload) {
          payload['amendmentType'] = amendmentType.wireValue;
          if (targetLineId != null) {
            payload['amendmentTargetLineId'] = targetLineId;
          }
          patchRevisionPayload?.call(payload);
        },
      );
      if (fork != null) {
        await RelayActivityLogService(_db).append(
          kind: RelayActivityLogKinds.housingProposalForkCreated,
          initiatorKind: RelayActivityLogService.initiatorSelf,
          planId: planId,
          revisionId: revisionId,
          details: {
            'forkedFromRevisionId': fork.revisionId,
            'forkedFromPackageId': fork.packageId,
            'amendment': true,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
        );
      }
      return false;
    }

    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      await PlanAgreementProposalService(_db).abandonPendingRevision(planId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingPlanCouldNotContinue('relay'))),
        );
      }
      return false;
    }

    try {
      final send = await orchestrator.sendHousingProposalToPlanParticipants(
        planId: planId,
        revisionId: revisionId,
      );
      if (send.sentCount == 0) {
        await PlanAgreementProposalService(_db).abandonPendingRevision(planId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.housingInviteTransportFailed)),
          );
        }
        return false;
      }
    } catch (e) {
      await PlanAgreementProposalService(_db).abandonPendingRevision(planId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
        );
      }
      return false;
    }

    if (!context.mounted) return true;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    final navContext = appRootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return true;
    await openHousingPendingProposalOrAmendment(
      navContext,
      db: _db,
      planId: planId,
      prefs: prefs,
      revisionId: revisionId,
      isAmendment: true,
    );
    return true;
  }
}
