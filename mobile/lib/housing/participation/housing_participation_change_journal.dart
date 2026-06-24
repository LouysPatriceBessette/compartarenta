import 'package:drift/drift.dart';

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
  final packageRow = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final packageId = packageRow?.id;

  final changes = await (db.select(db.housingParticipationChanges)
        ..where((t) {
          if (packageId == null) {
            return t.planId.equals(planId);
          }
          return t.planId.equals(planId) | t.packageId.equals(packageId);
        })
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  final byChangeId = <String, HousingParticipationChange>{};
  for (final change in changes) {
    byChangeId.putIfAbsent(change.id, () => change);
  }
  if (byChangeId.isEmpty) return const [];

  final roster = await participantsForPlan(db, planId);
  String nameFor(String participantId) =>
      displayNameForParticipant(participantId, roster);

  final entries = <HousingParticipationChangeJournalEntry>[];

  for (final change in byChangeId.values) {
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    if (kind == null) continue;

    final status = HousingParticipationChangeStatus.fromWire(change.status);
    final eventKind = switch (status) {
      HousingParticipationChangeStatus.effective =>
        HousingParticipationJournalEventKind.effective,
      HousingParticipationChangeStatus.aborted =>
        HousingParticipationJournalEventKind.aborted,
      HousingParticipationChangeStatus.pending ||
      null => HousingParticipationJournalEventKind.proposed,
    };
    final occurredAt =
        status == HousingParticipationChangeStatus.effective ||
            status == HousingParticipationChangeStatus.aborted
        ? change.settledAt ?? change.createdAt
        : change.createdAt;

    entries.add(
      HousingParticipationChangeJournalEntry(
        changeId: change.id,
        packageId: change.packageId,
        kind: kind,
        eventKind: eventKind,
        actorDisplayName: nameFor(change.initiatorParticipantId),
        occurredAt: occurredAt,
      ),
    );
  }

  entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return entries;
}
