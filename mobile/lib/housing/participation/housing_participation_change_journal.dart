import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';

/// Lifecycle event recorded in the unified change journal.
enum HousingParticipationJournalEventKind {
  proposed,
  decision,
  effective,
  aborted,
}

/// One participation-change timeline entry.
class HousingParticipationChangeJournalEntry {
  const HousingParticipationChangeJournalEntry({
    required this.changeId,
    required this.packageId,
    required this.kind,
    required this.eventKind,
    required this.actorDisplayName,
    required this.occurredAt,
    this.decisionAccepted,
  });

  final String changeId;
  final String packageId;
  final HousingParticipationChangeKind kind;
  final HousingParticipationJournalEventKind eventKind;
  final String actorDisplayName;
  final DateTime occurredAt;

  /// When [eventKind] is [HousingParticipationJournalEventKind.decision].
  final bool? decisionAccepted;

  String subject(AppLocalizations l10n) {
    final kindLabel = switch (kind) {
      HousingParticipationChangeKind.immediateTermination =>
        l10n.housingParticipationJournalSubjectTermination,
      HousingParticipationChangeKind.voluntaryWithdrawal =>
        l10n.housingParticipationJournalSubjectWithdrawal,
      HousingParticipationChangeKind.ejection =>
        l10n.housingParticipationJournalSubjectEjection,
    };
    final eventLabel = switch (eventKind) {
      HousingParticipationJournalEventKind.proposed =>
        l10n.housingParticipationJournalProposed,
      HousingParticipationJournalEventKind.decision =>
        decisionAccepted == true
            ? l10n.housingParticipationJournalDecisionAccepted
            : l10n.housingParticipationJournalDecisionRejected,
      HousingParticipationJournalEventKind.effective =>
        l10n.housingParticipationJournalEffective,
      HousingParticipationJournalEventKind.aborted =>
        l10n.housingParticipationJournalAborted,
    };
    return l10n.housingParticipationJournalSubjectLine(kindLabel, eventLabel);
  }
}

Future<List<HousingParticipationChangeJournalEntry>> loadHousingParticipationChangeJournal({
  required AppDatabase db,
  required String planId,
}) async {
  final changes = await (db.select(db.housingParticipationChanges)
        ..where((t) => t.planId.equals(planId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
  if (changes.isEmpty) return const [];

  final roster = await participantsForPlan(db, planId);
  String nameFor(String participantId) =>
      displayNameForParticipant(participantId, roster);

  final entries = <HousingParticipationChangeJournalEntry>[];

  for (final change in changes) {
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null) continue;

    entries.add(
      HousingParticipationChangeJournalEntry(
        changeId: change.id,
        packageId: change.packageId,
        kind: kind,
        eventKind: HousingParticipationJournalEventKind.proposed,
        actorDisplayName: nameFor(change.initiatorParticipantId),
        occurredAt: change.createdAt,
      ),
    );

    final decisions = await (db.select(db.housingParticipationDecisions)
          ..where((t) => t.changeId.equals(change.id)))
        .get();
    for (final decision in decisions) {
      final status = HousingParticipationDecisionStatus.fromWire(decision.status);
      if (status == null) continue;
      final decidedAt = decision.decidedAt ?? change.createdAt;
      entries.add(
        HousingParticipationChangeJournalEntry(
          changeId: change.id,
          packageId: change.packageId,
          kind: kind,
          eventKind: HousingParticipationJournalEventKind.decision,
          actorDisplayName: nameFor(decision.participantId),
          occurredAt: decidedAt,
          decisionAccepted: status == HousingParticipationDecisionStatus.accepted,
        ),
      );
    }

    final status = HousingParticipationChangeStatus.fromWire(change.status);
    if (status == HousingParticipationChangeStatus.effective ||
        status == HousingParticipationChangeStatus.aborted) {
      final settledAt = change.settledAt ?? change.createdAt;
      entries.add(
        HousingParticipationChangeJournalEntry(
          changeId: change.id,
          packageId: change.packageId,
          kind: kind,
          eventKind: status == HousingParticipationChangeStatus.effective
              ? HousingParticipationJournalEventKind.effective
              : HousingParticipationJournalEventKind.aborted,
          actorDisplayName: nameFor(change.initiatorParticipantId),
          occurredAt: settledAt,
        ),
      );
    }
  }

  entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return entries;
}
