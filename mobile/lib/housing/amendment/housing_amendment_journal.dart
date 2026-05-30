import 'dart:convert';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_amendment_settlement.dart';
import 'housing_amendment_summary.dart';
import 'housing_amendment_type.dart';
import '../proposals/plan_agreement_proposal_service.dart';

/// One settled plan-change entry for the journal list.
class HousingAmendmentJournalEntry {
  const HousingAmendmentJournalEntry({
    required this.revisionId,
    required this.summary,
    required this.accepted,
    required this.actorDisplayName,
    required this.settledAt,
  });

  final String revisionId;
  final HousingAmendmentSummary summary;
  final bool accepted;
  final String actorDisplayName;
  final DateTime settledAt;
}

Future<List<HousingAmendmentJournalEntry>> loadHousingAmendmentJournal({
  required AppDatabase db,
  required String planId,
  required AppLocalizations l10n,
  required String dateFormat,
}) async {
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  if (pkg == null) return const [];

  final revisions = await (db.select(db.proposalRevisions)
        ..where((t) => t.packageId.equals(pkg.id)))
      .get();
  final roster = await participantsForPlan(db, planId);
  String nameFor(String participantId) =>
      displayNameForParticipant(participantId, roster);

  final entries = <HousingAmendmentJournalEntry>[];
  for (final rev in revisions) {
    if (rev.id == pkg.pendingRevisionId) continue;
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }
    if (payload['lifecycleState'] != 'archived') continue;
    final type = resolveAmendmentType(
      pendingPayload: payload,
      activeRevisionId: pkg.activeRevisionId,
      pendingRevisionId: rev.id,
    );
    if (type == null) continue;

    final summary = await loadHousingAmendmentSummary(
      db: db,
      planId: planId,
      revisionId: rev.id,
      l10n: l10n,
      dateFormat: dateFormat,
    );
    if (summary == null) continue;

    final accepted = archivedAmendmentWasAccepted(payload);
    final actorId = await settledAmendmentActorParticipantId(
      db: db,
      revisionId: rev.id,
      proposerParticipantId: summary.proposerParticipantId,
      archivedPayload: payload,
    );
    final actorName = actorId == null || actorId.isEmpty
        ? summary.proposerDisplayName
        : nameFor(actorId);

    DateTime settledAt = rev.createdAt;
    if (accepted) {
      final responses = await (db.select(db.proposalResponses)
            ..where((t) => t.revisionId.equals(rev.id)))
          .get();
      for (final r in responses) {
        if (r.status != ProposalResponseStatus.accepted.name) continue;
        final at = r.respondedAt;
        if (at != null && at.isAfter(settledAt)) settledAt = at;
      }
    } else {
      final response = actorId == null || actorId.isEmpty
          ? null
          : await (db.select(db.proposalResponses)
                ..where((t) => t.revisionId.equals(rev.id))
                ..where((t) => t.participantId.equals(actorId)))
              .getSingleOrNull();
      settledAt = response?.respondedAt ?? rev.createdAt;
    }

    entries.add(
      HousingAmendmentJournalEntry(
        revisionId: rev.id,
        summary: summary,
        accepted: accepted,
        actorDisplayName: actorName,
        settledAt: settledAt,
      ),
    );
  }

  entries.sort((a, b) => b.settledAt.compareTo(a.settledAt));
  return entries;
}
