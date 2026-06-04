import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../participation/housing_participation_change_journal.dart';
import 'housing_amendment_journal.dart';

/// Discriminated union entry for the unified housing change log.
sealed class HousingChangeJournalEntry {
  const HousingChangeJournalEntry({required this.occurredAt});

  final DateTime occurredAt;
}

final class HousingChangeJournalAmendmentEntry extends HousingChangeJournalEntry {
  const HousingChangeJournalAmendmentEntry({
    required this.entry,
    required super.occurredAt,
  });

  final HousingAmendmentJournalEntry entry;
}

final class HousingChangeJournalParticipationEntry extends HousingChangeJournalEntry {
  const HousingChangeJournalParticipationEntry({
    required this.entry,
    required super.occurredAt,
  });

  final HousingParticipationChangeJournalEntry entry;
}

/// Merges amendment and participation journal entries sorted by date (newest first).
Future<List<HousingChangeJournalEntry>> loadHousingChangeJournal({
  required AppDatabase db,
  required String planId,
  required AppLocalizations l10n,
  required String dateFormat,
}) async {
  final amendmentEntries = await loadHousingAmendmentJournal(
    db: db,
    planId: planId,
    l10n: l10n,
    dateFormat: dateFormat,
  );
  final participationEntries = await loadHousingParticipationChangeJournal(
    db: db,
    planId: planId,
  );

  final merged = <HousingChangeJournalEntry>[
    for (final e in amendmentEntries)
      HousingChangeJournalAmendmentEntry(
        entry: e,
        occurredAt: e.settledAt,
      ),
    for (final e in participationEntries)
      HousingChangeJournalParticipationEntry(
        entry: e,
        occurredAt: e.occurredAt,
      ),
  ];

  merged.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return merged;
}
