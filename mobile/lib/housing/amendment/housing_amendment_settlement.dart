import '../../db/app_database.dart';
import '../proposals/plan_agreement_proposal_service.dart';

/// Whether an archived revision was accepted into the agreement (including
/// superseded accepted amendments), vs refused or negotiated away.
bool archivedAmendmentWasAccepted(Map<String, dynamic> payload) {
  if ((payload['lifecycleState'] as String?) != 'archived') return false;
  final status = payload['invalidatedByStatus']?.toString();
  if (status == ProposalResponseStatus.rejected.name ||
      status == ProposalResponseStatus.negotiate.name) {
    return false;
  }
  if (status == 'expired' || status == 'agreement_expired') return false;
  return true;
}

/// Revision whose payload is the "before" snapshot for [revisionPayload].
String? amendmentBaselineRevisionId({
  required Map<String, dynamic> revisionPayload,
  required String revisionId,
  required String? packageActiveRevisionId,
  required bool isArchived,
}) {
  final fork = revisionPayload['forkedFromRevisionId']?.toString();
  if (fork != null && fork.isNotEmpty) return fork;

  if (!isArchived &&
      packageActiveRevisionId != null &&
      packageActiveRevisionId != revisionId) {
    return packageActiveRevisionId;
  }

  if (isArchived &&
      !archivedAmendmentWasAccepted(revisionPayload) &&
      packageActiveRevisionId != null &&
      packageActiveRevisionId != revisionId) {
    return packageActiveRevisionId;
  }

  return null;
}

/// Participant who settled an archived amendment (accepting peer or refusing peer).
///
/// Unanimous activation archives without [invalidatedByParticipantId]; use the
/// latest non-proposer acceptance. Refusals store [invalidatedByParticipantId].
Future<String?> settledAmendmentActorParticipantId({
  required AppDatabase db,
  required String revisionId,
  required String proposerParticipantId,
  required Map<String, dynamic> archivedPayload,
}) async {
  if (!archivedAmendmentWasAccepted(archivedPayload)) {
    final id = archivedPayload['invalidatedByParticipantId']?.toString() ?? '';
    return id.isEmpty ? null : id;
  }

  final invalidated =
      archivedPayload['invalidatedByParticipantId']?.toString() ?? '';
  if (invalidated.isNotEmpty) return invalidated;

  final responses = await (db.select(db.proposalResponses)
        ..where((t) => t.revisionId.equals(revisionId)))
      .get();

  String? bestId;
  DateTime? bestAt;
  for (final r in responses) {
    if (r.status != ProposalResponseStatus.accepted.name) continue;
    if (r.participantId == proposerParticipantId) continue;
    final at = r.respondedAt;
    if (bestAt == null || (at != null && at.isAfter(bestAt))) {
      bestAt = at;
      bestId = r.participantId;
    }
  }
  return bestId;
}
