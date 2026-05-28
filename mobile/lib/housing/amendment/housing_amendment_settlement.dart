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
  if (status == 'expired') return false;
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
