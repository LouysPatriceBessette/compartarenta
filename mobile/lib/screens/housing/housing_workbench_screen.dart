import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import 'housing_active_plan_screen.dart';
import 'housing_archive_entry_screen.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_plan_screen.dart';

class _WorkbenchRow {
  const _WorkbenchRow({
    required this.plan,
    required this.hasPending,
    required this.hasActive,
    required this.hasArchive,
    required this.sortDate,
    required this.pendingResponseCount,
    required this.participantCount,
    this.archive,
  });

  final Plan plan;
  final bool hasPending;
  final bool hasActive;
  final bool hasArchive;
  final DateTime sortDate;
  final int pendingResponseCount;
  final int participantCount;
  final HousingProposalArchive? archive;
}

/// Lists housing plans on this device where the user has a `planId:self` row.
class HousingWorkbenchScreen extends StatefulWidget {
  const HousingWorkbenchScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<HousingWorkbenchScreen> createState() => _HousingWorkbenchScreenState();
}

class _HousingWorkbenchScreenState extends State<HousingWorkbenchScreen> {
  final AppDatabase _db = AppDatabase.processScope;
  late Future<List<_WorkbenchRow>> _load = _fetch();
  bool _creatingDerivedDraft = false;

  void _reload() {
    setState(() {
      _load = _fetch();
    });
  }

  Future<List<_WorkbenchRow>> _fetch() async {
    final housing = await (_db.select(
      _db.plans,
    )..where((t) => t.type.equals('housing'))).get();
    final out = <_WorkbenchRow>[];
    for (final p in housing) {
      final self = await (_db.select(
        _db.participants,
      )..where((t) => t.id.equals('${p.id}:self'))).getSingleOrNull();
      if (self == null) continue;
      final transport = HousingProposalTransportService(_db);
      if (await transport.isHiddenDraftPlan(p.id)) continue;
      final pkg = await (_db.select(
        _db.proposalPackages,
      )..where((t) => t.planId.equals(p.id))).getSingleOrNull();
      final pending = pkg?.pendingRevisionId != null;
      final active = pkg?.activeRevisionId != null;
      final archiveRows = await transport.listArchivesForPlan(p.id);
      final archivedRows = archiveRows
          .where((a) => !a.isDraft && !a.isPending)
          .toList();
      final archive = archivedRows.isNotEmpty;
      archivedRows.sort((a, b) => b.invalidatedAt.compareTo(a.invalidatedAt));
      final latestArchive = archivedRows.isEmpty ? null : archivedRows.first;
      DateTime? pendingDate;
      var pendingResponseCount = 0;
      if (pending) {
        for (final archive in archiveRows) {
          if (archive.isPending) {
            pendingDate = archive.invalidatedAt;
            pendingResponseCount = archive.pendingResponseCount;
            break;
          }
        }
      }
      out.add(
        _WorkbenchRow(
          plan: p,
          hasPending: pending,
          hasActive: active,
          hasArchive: archive,
          sortDate: pendingDate ?? latestArchive?.invalidatedAt ?? p.createdAt,
          pendingResponseCount: pendingResponseCount,
          participantCount: await _participantCountForPlan(p.id),
          archive: latestArchive,
        ),
      );
    }
    out.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return out;
  }

  String _rowTitle(Plan p) {
    final t = p.title.trim();
    return t.isEmpty ? p.id : t;
  }

  String _pendingRowTitle(AppLocalizations l10n, _WorkbenchRow row) {
    return l10n.housingArchivePendingTitle(row.pendingResponseCount);
  }

  String _draftRowTitle(AppLocalizations l10n, _WorkbenchRow row) {
    final count = row.archive?.participantCount ?? row.participantCount;
    if (count > 0) return l10n.housingArchiveDraftParticipantsTitle(count);
    return _rowTitle(row.plan);
  }

  Future<int> _participantCountForPlan(String planId) async {
    final participants = await _db.listParticipants();
    return participants
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .length;
  }

  String _archiveRowTitle(AppLocalizations l10n, _WorkbenchRow row) {
    final archive = row.archive;
    if (archive == null) return _rowTitle(row.plan);
    return switch (archive.status) {
      ProposalResponseStatus.negotiate => l10n.housingArchiveNegotiatingTitle,
      ProposalResponseStatus.rejected => l10n.housingArchiveRejectedTitle,
      ProposalResponseStatus.accepted ||
      ProposalResponseStatus.pending => archive.title,
    };
  }

  String _workbenchDate(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  void _openPlanEditor(String planId) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HousingPlanScreen(
              prefs: widget.prefs,
              planId: planId,
              openEditorInitially: true,
            ),
          ),
        )
        .then((_) => _reload());
  }

  void _openInvitePreview(String planId) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HousingInviteProposalScreen(
              db: _db,
              planId: planId,
              prefs: widget.prefs,
            ),
          ),
        )
        .then((_) => _reload());
  }

  void _openActivePlan() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const HousingActivePlanScreen()),
    );
  }

  void _openArchiveEntry(String planId) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                HousingArchiveEntryScreen(prefs: widget.prefs, planId: planId),
          ),
        )
        .then((_) => _reload());
  }

  void _viewArchive(_WorkbenchRow row) {
    final archive = row.archive;
    if (archive == null) {
      _openArchiveEntry(row.plan.id);
      return;
    }
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HousingInviteProposalScreen(
              db: _db,
              planId: row.plan.id,
              prefs: widget.prefs,
              revisionId: archive.revisionId,
            ),
          ),
        )
        .then((_) => _reload());
  }

  Future<void> _forkArchive(_WorkbenchRow row) async {
    if (_creatingDerivedDraft) return;
    final archive = row.archive;
    if (archive == null) return;
    setState(() => _creatingDerivedDraft = true);
    final id = 'housing:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await HousingProposalTransportService(_db).createForkDraftFromArchive(
        listPlanId: row.plan.id,
        revisionId: archive.revisionId,
        draftPlanId: id,
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
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
      await HousingProposalTransportService(
        _db,
      ).revealDraftEntry(listPlanId: row.plan.id, draftPlanId: id);
    } finally {
      if (mounted) {
        setState(() => _creatingDerivedDraft = false);
        _reload();
      }
    }
  }

  Future<void> _newPlan() async {
    final id = 'housing:${DateTime.now().toUtc().microsecondsSinceEpoch}';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.housingWorkbenchTitle),
      ),
      body: FutureBuilder<List<_WorkbenchRow>>(
        future: _load,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.housingWorkbenchEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final drafts = rows
              .where((r) => !r.hasPending && !r.hasActive && !r.hasArchive)
              .toList();
          final pending = rows.where((r) => r.hasPending).toList();
          final active = rows.where((r) => r.hasActive).toList();
          final archives = rows
              .where((r) => r.hasArchive && !r.hasPending && !r.hasActive)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (drafts.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchDraftsSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in drafts)
                  _planCard(
                    context,
                    title: _draftRowTitle(l10n, r),
                    date: r.sortDate,
                    onTap: () => _openPlanEditor(r.plan.id),
                  ),
                const SizedBox(height: 24),
              ],
              if (pending.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchPendingSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in pending)
                  _planCard(
                    context,
                    title: _pendingRowTitle(l10n, r),
                    date: r.sortDate,
                    onTap: () => _openInvitePreview(r.plan.id),
                  ),
                const SizedBox(height: 24),
              ],
              if (archives.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchArchivedSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in archives)
                  _planCard(
                    context,
                    title: _archiveRowTitle(l10n, r),
                    date: r.sortDate,
                    onTap: () => _viewArchive(r),
                    actionLabel: r.archive?.canFork == true
                        ? l10n.housingArchiveCreateDerivedAction
                        : null,
                    onAction:
                        r.archive?.canFork == true && !_creatingDerivedDraft
                        ? () => _forkArchive(r)
                        : null,
                  ),
                const SizedBox(height: 24),
              ],
              if (active.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchActiveSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in active)
                  _planCard(
                    context,
                    title: _rowTitle(r.plan),
                    date: r.sortDate,
                    onTap: _openActivePlan,
                  ),
                const SizedBox(height: 24),
              ],
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

  Widget _planCard(
    BuildContext context, {
    required String title,
    required DateTime date,
    required VoidCallback onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _workbenchDate(date),
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
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  flex: 4,
                  child: TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
