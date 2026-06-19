import 'package:flutter/material.dart';

import '../../activity/relay_activity_log_service.dart';
import '../../debug/web_dev_host_session.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
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
    DateTime? proposedPeriodEnd,
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

    final transport = HousingProposalTransportService(_db);
    final activeRevisionId =
        await transport.resolveActiveRevisionIdForPlan(planId);
    final packageId = activeRevisionId == null
        ? null
        : await transport.packageIdHoldingActiveRevision(
            planId,
            activeRevisionId: activeRevisionId,
          );
    final fork = activeRevisionId == null || packageId == null
        ? null
        : (
            packageId: packageId,
            revisionId: activeRevisionId,
          );

    final proposerId = '$planId:self';
    return runWithDeferredDevHostSessionSave(_db, () async {
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
            if (proposedPeriodEnd != null) {
              final agr = payload['agreement'];
              if (agr is Map) {
                agr['periodEnd'] = proposedPeriodEnd.toIso8601String();
              }
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
          debugPrint(
            'housing_amendment: relay send failed for $planId revision=$revisionId '
            '(failedParticipants=${send.failedParticipantIds.length})',
          );
          await PlanAgreementProposalService(_db).abandonPendingRevision(planId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.housingInviteTransportFailed)),
            );
          }
          return false;
        }
        debugPrint(
          'housing_amendment: relay sent to ${send.sentCount} target(s) '
          'for $planId revision=$revisionId',
        );
      } catch (e) {
        await PlanAgreementProposalService(_db).abandonPendingRevision(planId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
          );
        }
        return false;
      }

      return true;
    });
  }
}
