import 'dart:convert';

import '../../db/app_database.dart';
import 'plan_agreement_proposal_service.dart';

/// Parsed proposal revision metadata from [ProposalRevisions.payloadJson].
class HousingProposalRevisionState {
  const HousingProposalRevisionState({
    required this.lifecycleState,
    this.responseExpiresAtUtc,
    this.forkedFromRevisionId,
    this.forkedFromPackageId,
  });

  final String lifecycleState;
  final DateTime? responseExpiresAtUtc;
  final String? forkedFromRevisionId;
  final String? forkedFromPackageId;

  bool get isOpen => lifecycleState == 'open';

  bool get isArchived => lifecycleState == 'archived';

  bool get isExpiredByClock {
    final expires = responseExpiresAtUtc;
    if (expires == null) return false;
    return DateTime.now().toUtc().isAfter(expires);
  }

  static HousingProposalRevisionState fromPayload(Map<String, dynamic> payload) {
    DateTime? expires;
    final raw = payload['responseExpiresAt'];
    if (raw is String && raw.isNotEmpty) {
      expires = DateTime.tryParse(raw)?.toUtc();
    }
    return HousingProposalRevisionState(
      lifecycleState: (payload['lifecycleState'] as String?) ?? 'open',
      responseExpiresAtUtc: expires,
      forkedFromRevisionId: payload['forkedFromRevisionId'] as String?,
      forkedFromPackageId: payload['forkedFromPackageId'] as String?,
    );
  }

  static HousingProposalRevisionState fromJson(String payloadJson) {
    return fromPayload(
      jsonDecode(payloadJson) as Map<String, dynamic>,
    );
  }
}

/// Whether [participantId] may still submit Accept / Negotiate / Refuse.
bool housingParticipantMayRespond({
  required HousingProposalRevisionState revision,
  required String participantResponseStatus,
  required String proposerParticipantId,
  required String participantId,
}) {
  if (participantId == proposerParticipantId) return false;
  if (!revision.isOpen || revision.isExpiredByClock) return false;
  return participantResponseStatus == ProposalResponseStatus.pending.name;
}
