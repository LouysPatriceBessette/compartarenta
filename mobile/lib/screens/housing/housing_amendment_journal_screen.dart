import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../housing/amendment/housing_amendment_journal.dart';
import '../../housing/amendment/housing_change_journal.dart';
import '../../housing/participation/housing_participation_change_journal.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_amendment_detail_screen.dart';
import 'housing_participation_change_detail_screen.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Chronological log of accepted and refused in-force plan changes and
/// participation changes.
class HousingAmendmentJournalScreen extends StatefulWidget {
  const HousingAmendmentJournalScreen({
    super.key,
    required this.planId,
    required this.prefs,
  });

  final String planId;
  final AppPreferences prefs;

  @override
  State<HousingAmendmentJournalScreen> createState() =>
      _HousingAmendmentJournalScreenState();
}

class _HousingAmendmentJournalScreenState
    extends State<HousingAmendmentJournalScreen> {
  late Future<List<HousingChangeJournalEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final l10n = switch (code) {
      'fr' => lookupAppLocalizations(const Locale('fr')),
      'es' => lookupAppLocalizations(const Locale('es')),
      _ => lookupAppLocalizations(const Locale('en')),
    };
    setState(() {
      _entriesFuture = loadHousingChangeJournal(
        db: AppDatabase.processScope,
        planId: widget.planId,
        l10n: l10n,
        dateFormat: effectiveDateFormat(widget.prefs),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(widget.prefs);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentJournalTitle)),
      body: FutureBuilder<List<HousingChangeJournalEntry>>(
        future: _entriesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? const [];
          if (entries.isEmpty) {
            return Center(child: Text(l10n.housingAmendmentJournalEmpty));
          }
          return ListView.separated(
            padding: housingAmendmentScreenPadding(context),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return switch (entry) {
                HousingChangeJournalAmendmentEntry(:final entry) =>
                  _AmendmentCard(
                    entry: entry,
                    l10n: l10n,
                    dateFmt: dateFmt,
                    planId: widget.planId,
                    prefs: widget.prefs,
                    onReturn: _reload,
                  ),
                HousingChangeJournalParticipationEntry(:final entry) =>
                  _ParticipationCard(
                    entry: entry,
                    l10n: l10n,
                    dateFmt: dateFmt,
                    planId: widget.planId,
                    prefs: widget.prefs,
                    onReturn: _reload,
                  ),
              };
            },
          );
        },
      ),
    );
  }
}

class _AmendmentCard extends StatelessWidget {
  const _AmendmentCard({
    required this.entry,
    required this.l10n,
    required this.dateFmt,
    required this.planId,
    required this.prefs,
    required this.onReturn,
  });

  final HousingAmendmentJournalEntry entry;
  final AppLocalizations l10n;
  final String dateFmt;
  final String planId;
  final AppPreferences prefs;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final summary = entry.summary;
    final statusLabel = entry.accepted
        ? l10n.housingAmendmentJournalAccepted
        : l10n.housingAmendmentJournalRefused;
    return Card(
      child: ListTile(
        title: Text(summary.journalListSubject(l10n)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusLabel),
            Text(
              l10n.housingAmendmentJournalCardSubtitle(
                entry.actorDisplayName,
                formatPreferenceDate(entry.settledAt, dateFmt),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await navigateToRoute<void>(context, 
            MaterialPageRoute<void>(
              builder: (_) => HousingAmendmentDetailScreen(
                db: AppDatabase.processScope,
                planId: planId,
                prefs: prefs,
                revisionId: entry.revisionId,
                readOnlySettled: true,
              ),
            ),
          );
          onReturn();
        },
      ),
    );
  }
}

class _ParticipationCard extends StatelessWidget {
  const _ParticipationCard({
    required this.entry,
    required this.l10n,
    required this.dateFmt,
    required this.planId,
    required this.prefs,
    required this.onReturn,
  });

  final HousingParticipationChangeJournalEntry entry;
  final AppLocalizations l10n;
  final String dateFmt;
  final String planId;
  final AppPreferences prefs;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(entry.subject(l10n)),
        subtitle: Text(
          l10n.housingAmendmentJournalCardSubtitle(
            entry.actorDisplayName,
            formatPreferenceDate(entry.occurredAt, dateFmt),
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await navigateToRoute<void>(context, 
            MaterialPageRoute<void>(
              builder: (_) => HousingParticipationChangeDetailScreen(
                changeId: entry.changeId,
                planId: planId,
                packageId: entry.packageId,
                prefs: prefs,
              ),
            ),
          );
          onReturn();
        },
      ),
    );
  }
}
