import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../activity/relay_activity_log_service.dart';
import '../../contacts/contact_module_anchor.dart';
import '../../db/app_database.dart';
import '../participation/housing_participation_change_kind.dart';
import '../participation/housing_participation_change_service.dart';
import 'plan_agreement_proposal_service.dart';
import 'housing_proposal_revision_state.dart';
import 'housing_proposal_transport_service.dart';

/// Wire value stored on invalidated revisions when the agreement ended.
const kAgreementExpiredInvalidationStatus = 'agreement_expired';

/// Settles unfinished votes after the agreement end date (local midnight after
/// [periodEnd]). Returns plan ids that were processed.
Future<List<String>> settleExpiredAgreementVotes(AppDatabase db) async {
  final processed = <String>[];
  final housingPlans = await (db.select(db.plans)
        ..where((t) => t.type.equals('housing')))
      .get();
  final now = DateTime.now();

  for (final plan in housingPlans) {
    final selfPid = '${plan.id}:self';
    final selfRow = await (db.select(db.participants)
          ..where((t) => t.id.equals(selfPid)))
        .getSingleOrNull();
    if (selfRow == null) continue;

    final agr = await db.getAgreementForPlan(plan.id);
    if (agr == null) continue;
    if (!agreementVoteExpiryApplies(periodEnd: agr.periodEnd, now: now)) {
      continue;
    }

    var changed = false;
    changed = await _expireOpenProposalVotes(db, plan.id) || changed;
    changed = await _expireParticipationChangeVotes(db, plan.id) || changed;

    if (changed) {
      processed.add(plan.id);
    }
  }

  return processed;
}

Future<bool> _expireOpenProposalVotes(AppDatabase db, String planId) async {
  final transport = HousingProposalTransportService(db);
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final pendingId = pkg?.pendingRevisionId;
  if (pendingId == null || pendingId.isEmpty) return false;

  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(pendingId)))
      .getSingleOrNull();
  if (rev == null) return false;

  final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  final state = HousingProposalRevisionState.fromPayload(payload);
  if (!state.isOpen) return false;

  payload['lifecycleState'] = 'archived';
  payload['invalidatedByStatus'] = kAgreementExpiredInvalidationStatus;
  payload.remove('invalidatedByParticipantId');
  await (db.update(db.proposalRevisions)..where((t) => t.id.equals(pendingId)))
      .write(
    ProposalRevisionsCompanion(
      payloadJson: drift.Value(jsonEncode(payload)),
    ),
  );
  await (db.update(db.proposalPackages)..where((t) => t.planId.equals(planId)))
      .write(
    const ProposalPackagesCompanion(pendingRevisionId: drift.Value(null)),
  );

  final responses = await (db.select(db.proposalResponses)
        ..where((t) => t.revisionId.equals(pendingId)))
      .get();
  for (final response in responses) {
    if (response.status != ProposalResponseStatus.pending.name) continue;
    await (db.update(db.proposalResponses)
          ..where((t) => t.id.equals(response.id)))
        .write(
      ProposalResponsesCompanion(
        status: drift.Value(ProposalResponseStatus.rejected.name),
        respondedAt: drift.Value(DateTime.now().toUtc()),
      ),
    );
  }

  await RelayActivityLogService(db).append(
    kind: RelayActivityLogKinds.housingProposalAgreementExpired,
    initiatorKind: RelayActivityLogService.initiatorSystem,
    planId: planId,
    packageId: payload['packageId']?.toString(),
    revisionId: pendingId,
  );
  await transport.reconcileStalePackagePending(planId);
  return true;
}

Future<bool> _expireParticipationChangeVotes(
  AppDatabase db,
  String planId,
) async {
  final changeSvc = HousingParticipationChangeService(db);
  final pending = await changeSvc.pendingForPlan(planId);
  if (pending == null) return false;
  final kind = HousingParticipationChangeKind.fromWire(pending.kind);
  if (kind == null ||
      kind == HousingParticipationChangeKind.voluntaryWithdrawal) {
    return false;
  }

  await (db.update(db.housingParticipationChanges)
        ..where((t) => t.id.equals(pending.id)))
      .write(
    HousingParticipationChangesCompanion(
      status: drift.Value(HousingParticipationChangeStatus.aborted.wireValue),
    ),
  );

  await RelayActivityLogService(db).append(
    kind: RelayActivityLogKinds.housingParticipationChangeAgreementExpired,
    initiatorKind: RelayActivityLogService.initiatorSystem,
    planId: planId,
    details: {'changeId': pending.id, 'kind': pending.kind},
  );
  return true;
}
