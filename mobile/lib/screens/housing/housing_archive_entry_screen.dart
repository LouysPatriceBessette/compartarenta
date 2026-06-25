import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/housing_module_exit.dart';
import '../../housing/housing_plan_id.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_plan_screen.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

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
  bool _creatingDerivedDraft = false;

  void _reload() {
    setState(() {
      _load = HousingProposalTransportService(
        _db,
      ).listArchivesForPlan(widget.planId);
    });
  }

  Future<void> _forkArchive(HousingProposalArchive archive) async {
    if (_creatingDerivedDraft) return;
    setState(() => _creatingDerivedDraft = true);
    final id = newHousingPlanId();
    try {
      HousingNavigationIntent.navigateSuppressProposalSettledRedirect();
      try {
        await HousingProposalTransportService(_db).createForkDraftFromArchive(
          listPlanId: widget.planId,
          revisionId: archive.revisionId,
          draftPlanId: id,
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } finally {
        HousingNavigationIntent.popSuppressProposalSettledRedirect();
      }
      if (!mounted) return;
      await HousingNavigationIntent.navigateToPlanScreenRootOverlay<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HousingPlanScreen(
            prefs: widget.prefs,
            planId: id,
            openEditorInitially: true,
          ),
        ),
      );
      await HousingProposalTransportService(
        _db,
      ).revealDraftEntry(listPlanId: widget.planId, draftPlanId: id);
    } finally {
      if (mounted) {
        setState(() => _creatingDerivedDraft = false);
        _reload();
      }
    }
  }

  Future<void> _editDraft(HousingProposalArchive archive) async {
    await HousingNavigationIntent.navigateToPlanScreenRootOverlay<void>(
      context,
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
    navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder: (_) => HousingInviteProposalScreen(
          db: _db,
          planId: archive.isPending
              ? archive.editorPlanId ?? widget.planId
              : widget.planId,
          prefs: widget.prefs,
          revisionId: archive.revisionId,
        ),
      ),
    );
  }

  Future<void> _newPlan() async {
    if (_creatingDerivedDraft) return;
    setState(() => _creatingDerivedDraft = true);
    final id = newHousingPlanId();
    try {
      HousingNavigationIntent.navigateSuppressProposalSettledRedirect();
      try {
        await HousingProposalTransportService(
          _db,
        ).createStandaloneDraftEntry(
          listPlanId: widget.planId,
          draftPlanId: id,
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } finally {
        HousingNavigationIntent.popSuppressProposalSettledRedirect();
      }
      if (!mounted) return;
      await HousingNavigationIntent.navigateToPlanScreenRootOverlay<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HousingPlanScreen(
            prefs: widget.prefs,
            planId: id,
            openEditorInitially: true,
          ),
        ),
      );
      await HousingProposalTransportService(
        _db,
      ).revealDraftEntry(listPlanId: widget.planId, draftPlanId: id);
    } finally {
      if (mounted) {
        setState(() => _creatingDerivedDraft = false);
        _reload();
      }
    }
  }

  String _archiveTitle(AppLocalizations l10n, HousingProposalArchive archive) {
    if (archive.isExpired) return l10n.housingArchiveExpiredTitle;
    if (archive.isDraft) {
      return archive.participantCount > 0
          ? l10n.housingArchiveDraftParticipantsTitle(archive.participantCount)
          : l10n.housingArchiveDraftTitle;
    }
    if (archive.isPending) {
      return l10n.housingArchivePendingTitle(archive.pendingResponseCount);
    }
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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => exitHousingModule(context)),
        title: Text(l10n.housingArchiveEntryTitle),
      ),
      body: FutureBuilder<List<HousingProposalArchive>>(
          future: _load,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final archives = snap.data!;
            final drafts = archives.where((a) => a.isDraft).toList();
            final pending = archives.where((a) => a.isPending).toList();
            final archived = archives
                .where((a) => !a.isDraft && !a.isPending)
                .toList();
            void sortNewestFirst(List<HousingProposalArchive> rows) {
              rows.sort((a, b) => b.invalidatedAt.compareTo(a.invalidatedAt));
            }

            sortNewestFirst(drafts);
            sortNewestFirst(pending);
            sortNewestFirst(archived);
            return ListView(
              padding: screenBodyScrollPadding(context),
              children: [
                Text(
                  l10n.housingArchiveEntryBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ..._section(
                  context,
                  l10n.housingWorkbenchDraftsSection,
                  drafts,
                ),
                ..._section(
                  context,
                  l10n.housingWorkbenchPendingSection,
                  pending,
                ),
                ..._section(
                  context,
                  l10n.housingWorkbenchArchivedSection,
                  archived,
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
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<HousingProposalArchive> rows,
  ) {
    if (rows.isEmpty) return const <Widget>[];
    return <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final archive in rows) _archiveCard(context, archive),
      const SizedBox(height: 24),
    ];
  }

  Widget _archiveCard(BuildContext context, HousingProposalArchive archive) {
    final l10n = AppLocalizations.of(context);
    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            archive.isDraft ? _editDraft(archive) : _viewArchive(archive),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _archiveDate(archive.invalidatedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (archive.canFork || archive.isDraft)
                Flexible(
                  flex: 4,
                  child: TextButton(
                    onPressed: archive.canFork && _creatingDerivedDraft
                        ? null
                        : () => archive.canFork
                              ? _forkArchive(archive)
                              : _editDraft(archive),
                    child: Text(
                      archive.canFork
                          ? l10n.housingArchiveCreateDerivedAction
                          : l10n.housingArchiveEditDraftAction,
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
    );
    if (!kDebugMode || !archive.isExpired) return card;
    return Semantics(
      identifier: 'qa-housing-archive-expired',
      label: l10n.housingArchiveExpiredTitle,
      child: card,
    );
  }
}
