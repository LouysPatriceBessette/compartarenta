import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import 'housing_active_plan_screen.dart';
import 'housing_archive_entry_screen.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_plan_screen.dart';
import 'housing_workbench_screen.dart';

/// Housing [Plan] rows where this device has a `planId:self` participant.
Future<List<Plan>> housingPlansWithSelfParticipant(AppDatabase db) async {
  final housing = await (db.select(
    db.plans,
  )..where((t) => t.type.equals('housing'))).get();
  final out = <Plan>[];
  for (final p in housing) {
    final self = await (db.select(
      db.participants,
    )..where((t) => t.id.equals('${p.id}:self'))).getSingleOrNull();
    if (self != null) out.add(p);
  }
  return out;
}

class _HousingEntrySnapshot {
  const _HousingEntrySnapshot({
    required this.plans,
    this.package,
    this.hasArchives = false,
  });

  final List<Plan> plans;
  final ProposalPackage? package;
  final bool hasArchives;
}

/// Routes to [HousingWorkbenchScreen] when there is more than one housing plan
/// with a local self row; otherwise opens [HousingPlanScreen] directly.
class HousingModuleEntryScreen extends StatefulWidget {
  const HousingModuleEntryScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<HousingModuleEntryScreen> createState() =>
      _HousingModuleEntryScreenState();
}

class _HousingModuleEntryScreenState extends State<HousingModuleEntryScreen> {
  /// Must be stable across rebuilds — a new [Future] each [build] restarts
  /// [FutureBuilder] forever (visible as a flickering screen).
  Future<_HousingEntrySnapshot>? _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadEntry();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
  }

  @override
  void dispose() {
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    setState(() => _entryFuture = _loadEntry());
  }

  Future<_HousingEntrySnapshot> _loadEntry() async {
    final db = AppDatabase.processScope;
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) {
      debugPrint('housing entry inbox poll skipped: relay not configured');
    } else {
      // Do not block the housing route on relay I/O (can take seconds per contact).
      unawaited(
        orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
          debugPrint('housing entry inbox poll: $e\n$st');
        }),
      );
    }
    final plans = await housingPlansWithSelfParticipant(db);
    if (plans.length != 1) {
      return _HousingEntrySnapshot(plans: plans);
    }
    final planId = plans.single.id;
    final pkg = await (db.select(
      db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).getSingleOrNull();
    final hasArchives = await HousingProposalTransportService(
      db,
    ).planHasArchives(planId);
    return _HousingEntrySnapshot(
      plans: plans,
      package: pkg,
      hasArchives: hasArchives,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: FutureBuilder<_HousingEntrySnapshot>(
        future: _entryFuture ?? _loadEntry(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final entry =
              snap.data ?? const _HousingEntrySnapshot(plans: <Plan>[]);
          final plans = entry.plans;
          if (plans.length > 1) {
            return HousingWorkbenchScreen(prefs: widget.prefs);
          }
          if (plans.isEmpty) {
            return HousingPlanScreen(prefs: widget.prefs);
          }
          final pkg = entry.package;
          if (pkg?.activeRevisionId != null) {
            return const HousingActivePlanScreen();
          }
          if (pkg?.pendingRevisionId != null) {
            return HousingInviteProposalScreen(
              db: AppDatabase.processScope,
              planId: plans.single.id,
              prefs: widget.prefs,
            );
          }
          if (entry.hasArchives) {
            return HousingArchiveEntryScreen(
              prefs: widget.prefs,
              planId: plans.single.id,
            );
          }
          return HousingPlanScreen(
            prefs: widget.prefs,
            planId: plans.single.id,
          );
        },
      ),
    );
  }
}
