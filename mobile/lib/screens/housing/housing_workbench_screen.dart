import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
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
  });

  final Plan plan;
  final bool hasPending;
  final bool hasActive;
  final bool hasArchive;
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
  late final Future<List<_WorkbenchRow>> _load = _fetch();

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
      final pkg = await (_db.select(
        _db.proposalPackages,
      )..where((t) => t.planId.equals(p.id))).getSingleOrNull();
      final pending = pkg?.pendingRevisionId != null;
      final active = pkg?.activeRevisionId != null;
      final archive = await HousingProposalTransportService(
        _db,
      ).planHasArchives(p.id);
      out.add(
        _WorkbenchRow(
          plan: p,
          hasPending: pending,
          hasActive: active,
          hasArchive: archive,
        ),
      );
    }
    out.sort((a, b) {
      final ta = a.plan.title.trim();
      final tb = b.plan.title.trim();
      final ca = ta.isEmpty ? a.plan.id : ta;
      final cb = tb.isEmpty ? b.plan.id : tb;
      return ca.toLowerCase().compareTo(cb.toLowerCase());
    });
    return out;
  }

  String _rowTitle(Plan p) {
    final t = p.title.trim();
    return t.isEmpty ? p.id : t;
  }

  void _openPlanEditor(String planId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingPlanScreen(prefs: widget.prefs, planId: planId),
      ),
    );
  }

  void _openInvitePreview(String planId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingInviteProposalScreen(
          db: _db,
          planId: planId,
          prefs: widget.prefs,
        ),
      ),
    );
  }

  void _openActivePlan() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const HousingActivePlanScreen()),
    );
  }

  void _openArchiveEntry(String planId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            HousingArchiveEntryScreen(prefs: widget.prefs, planId: planId),
      ),
    );
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
              if (active.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchActiveSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in active)
                  Card(
                    child: ListTile(
                      title: Text(_rowTitle(r.plan)),
                      subtitle: Text(r.plan.id),
                      trailing: TextButton(
                        onPressed: _openActivePlan,
                        child: Text(l10n.housingWorkbenchOpenPlan),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
              if (drafts.isNotEmpty) ...[
                Text(
                  l10n.housingWorkbenchDraftsSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in drafts)
                  Card(
                    child: ListTile(
                      title: Text(_rowTitle(r.plan)),
                      subtitle: Text(r.plan.id),
                      trailing: TextButton(
                        onPressed: () => _openPlanEditor(r.plan.id),
                        child: Text(l10n.housingWorkbenchOpenPlan),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
              if (archives.isNotEmpty) ...[
                Text(
                  l10n.housingArchiveEntryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in archives)
                  Card(
                    child: ListTile(
                      title: Text(_rowTitle(r.plan)),
                      subtitle: Text(r.plan.id),
                      trailing: TextButton(
                        onPressed: () => _openArchiveEntry(r.plan.id),
                        child: Text(l10n.housingWorkbenchOpenPlan),
                      ),
                    ),
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
                  Card(
                    child: ListTile(
                      title: Text(_rowTitle(r.plan)),
                      subtitle: Text(r.plan.id),
                      trailing: TextButton(
                        onPressed: () => _openInvitePreview(r.plan.id),
                        child: Text(l10n.housingWorkbenchOpenPlan),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
