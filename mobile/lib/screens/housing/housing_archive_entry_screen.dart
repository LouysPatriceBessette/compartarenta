import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_plan_screen.dart';

class HousingArchiveEntryScreen extends StatefulWidget {
  const HousingArchiveEntryScreen({
    super.key,
    required this.prefs,
    required this.planId,
  });

  final AppPreferences prefs;
  final String planId;

  @override
  State<HousingArchiveEntryScreen> createState() =>
      _HousingArchiveEntryScreenState();
}

class _HousingArchiveEntryScreenState extends State<HousingArchiveEntryScreen> {
  final AppDatabase _db = AppDatabase.processScope;
  late Future<List<HousingProposalArchive>> _load =
      HousingProposalTransportService(_db).listArchivesForPlan(widget.planId);

  void _reload() {
    setState(() {
      _load = HousingProposalTransportService(
        _db,
      ).listArchivesForPlan(widget.planId);
    });
  }

  Future<void> _forkArchive(HousingProposalArchive archive) async {
    await HousingProposalTransportService(_db).prepareForkFromArchive(
      planId: widget.planId,
      revisionId: archive.revisionId,
    );
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            HousingPlanScreen(prefs: widget.prefs, planId: widget.planId),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _editDraft(HousingProposalArchive archive) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingPlanScreen(
          prefs: widget.prefs,
          planId: archive.editorPlanId ?? widget.planId,
          openEditorInitially: true,
        ),
      ),
    );
    if (mounted) _reload();
  }

  void _viewArchive(HousingProposalArchive archive) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingInviteProposalScreen(
          db: _db,
          planId: widget.planId,
          prefs: widget.prefs,
          revisionId: archive.revisionId,
        ),
      ),
    );
  }

  Future<void> _newPlan() async {
    final id = 'housing:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    await HousingProposalTransportService(
      _db,
    ).createStandaloneDraftEntry(listPlanId: widget.planId, draftPlanId: id);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingPlanScreen(
          prefs: widget.prefs,
          planId: id,
          openEditorInitially: true,
        ),
      ),
    );
    if (mounted) _reload();
  }

  String _archiveTitle(AppLocalizations l10n, HousingProposalArchive archive) {
    if (archive.isDraft) return l10n.housingArchiveDraftTitle;
    return switch (archive.status) {
      ProposalResponseStatus.negotiate => l10n.housingArchiveNegotiatingTitle,
      ProposalResponseStatus.rejected => l10n.housingArchiveRejectedTitle,
      ProposalResponseStatus.accepted ||
      ProposalResponseStatus.pending => archive.title,
    };
  }

  String _archiveDate(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.housingArchiveEntryTitle)),
        body: FutureBuilder<List<HousingProposalArchive>>(
          future: _load,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final archives = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.housingArchiveEntryBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final archive in archives)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => archive.canFork
                          ? _forkArchive(archive)
                          : archive.isDraft
                          ? _editDraft(archive)
                          : _viewArchive(archive),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _archiveTitle(l10n, archive),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _archiveDate(archive.invalidatedAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 4,
                              child: TextButton(
                                onPressed: () => archive.canFork
                                    ? _forkArchive(archive)
                                    : archive.isDraft
                                    ? _editDraft(archive)
                                    : _viewArchive(archive),
                                child: Text(
                                  archive.canFork
                                      ? l10n.housingArchiveCreateDerivedAction
                                      : archive.isDraft
                                      ? l10n.housingArchiveEditDraftAction
                                      : l10n.housingArchiveViewAction,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _newPlan,
                  child: Text(l10n.housingArchiveCreateNewPlan),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
