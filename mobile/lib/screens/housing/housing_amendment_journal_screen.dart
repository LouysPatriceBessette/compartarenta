import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_journal.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/amendment/housing_amendment_screen_padding.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import 'housing_amendment_detail_screen.dart';

/// Chronological log of accepted and refused in-force plan changes.
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

class _HousingAmendmentJournalScreenState extends State<HousingAmendmentJournalScreen> {
  late Future<List<HousingAmendmentJournalEntry>> _entriesFuture;

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
      _entriesFuture = loadHousingAmendmentJournal(
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
      body: FutureBuilder<bool>(
        future: HousingProposalTransportService(AppDatabase.processScope)
            .hasOpenPendingAmendment(widget.planId),
        builder: (context, pendingSnap) {
          final hasPending = pendingSnap.data ?? false;
          return FutureBuilder<List<HousingAmendmentJournalEntry>>(
            future: _entriesFuture,
            builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? const [];
          if (entries.isEmpty && !hasPending) {
            return Center(child: Text(l10n.housingAmendmentJournalEmpty));
          }
          return ListView.separated(
            padding: housingAmendmentScreenPadding(context),
            itemCount: entries.length + (hasPending ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (hasPending && index == 0) {
                return Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.edit_notifications_outlined),
                    title: Text(l10n.housingActiveHubPendingAmendment),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openHousingPendingProposalOrAmendment(
                      context,
                      db: AppDatabase.processScope,
                      planId: widget.planId,
                      prefs: widget.prefs,
                      isAmendment: true,
                    ),
                  ),
                );
              }
              final entryIndex = hasPending ? index - 1 : index;
              final entry = entries[entryIndex];
              final summary = entry.summary;
              final statusLabel = entry.accepted
                  ? l10n.housingAmendmentJournalAccepted
                  : l10n.housingAmendmentJournalRefused;
              return Card(
                child: ListTile(
                  title: Text(
                    l10n.housingAmendmentJournalCardTitle(
                      summary.subjectLabel(l10n),
                      statusLabel,
                    ),
                  ),
                  subtitle: Text(
                    l10n.housingAmendmentJournalCardSubtitle(
                      entry.actorDisplayName,
                      formatPreferenceDate(entry.settledAt, dateFmt),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => HousingAmendmentDetailScreen(
                          db: AppDatabase.processScope,
                          planId: widget.planId,
                          prefs: widget.prefs,
                          revisionId: entry.revisionId,
                          readOnlySettled: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
            },
          );
        },
      ),
    );
  }
}
