import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_navigation.dart';
import '../../housing/amendment/housing_amendment_summary.dart';
import '../../housing/housing_module_exit.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
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
  final transport = HousingProposalTransportService(db);
  final out = <Plan>[];
  for (final p in housing) {
    if (await transport.isHiddenDraftPlan(p.id)) continue;
    final self = await (db.select(
      db.participants,
    )..where((t) => t.id.equals('${p.id}:self'))).getSingleOrNull();
    if (self == null) continue;
    if (!await transport.hasActiveRevision(p.id) &&
        await transport.anyOtherHousingPlanHasActiveRevision(
          exceptPlanId: p.id,
        )) {
      continue;
    }
    out.add(p);
  }
  return out;
}

class _HousingEntrySnapshot {
  const _HousingEntrySnapshot({
    required this.plans,
    this.package,
    this.hasArchives = false,
    this.primaryActivePlan,
    this.primaryActivePackage,
  });

  final List<Plan> plans;
  final ProposalPackage? package;
  final bool hasArchives;
  /// When exactly one housing plan has an in-force agreement, open its hub.
  final Plan? primaryActivePlan;
  final ProposalPackage? primaryActivePackage;
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
  int _workbenchReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadEntry();
    // Register after the first frame so an inbox tick during build cannot
    // call setState while the route is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HousingNavigationIntent.openAmendmentTick.addListener(
        _onOpenAmendmentIntent,
      );
      HousingNavigationIntent.openProposalTick.addListener(
        _onOpenProposalIntent,
      );
      HousingNavigationIntent.entryReloadTick.addListener(_onEntryReloadIntent);
      _openPendingAmendmentFromNotificationIfAny();
      _openPendingProposalFromNotificationIfAny();
    });
  }

  @override
  void dispose() {
    HousingNavigationIntent.openAmendmentTick.removeListener(
      _onOpenAmendmentIntent,
    );
    HousingNavigationIntent.openProposalTick.removeListener(
      _onOpenProposalIntent,
    );
    HousingNavigationIntent.entryReloadTick.removeListener(
      _onEntryReloadIntent,
    );
    super.dispose();
  }

  void _onEntryReloadIntent() {
    if (!mounted) return;
    _reloadEntry();
  }

  void _onOpenAmendmentIntent() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingAmendmentFromNotificationIfAny();
    });
  }

  void _onOpenProposalIntent() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingProposalFromNotificationIfAny();
    });
  }

  Future<void> _openPendingAmendmentFromNotificationIfAny() async {
    var planId = HousingNavigationIntent.takePendingOpenAmendmentPlanId();
    if (!mounted) return;
    final db = AppDatabase.processScope;
    final transport = HousingProposalTransportService(db);
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null) {
      await orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing amendment open poll: $e\n$st');
      });
    }
    planId ??= await transport.housingPlanIdWithAmendmentAwaitingLocalResponse();
    if (planId == null) {
      debugPrint('housing: notification tap but no pending amendment plan');
      return;
    }
    final pendingId = await transport.pendingRevisionIdForPlan(planId);
    if (pendingId == null) {
      debugPrint('housing: no pendingRevisionId on plan $planId');
      return;
    }
    if (!mounted) return;
    await openHousingPendingProposalOrAmendment(
      context,
      db: db,
      planId: planId,
      prefs: widget.prefs,
      revisionId: pendingId,
      isAmendment: true,
    );
    if (mounted) _reloadEntry();
  }

  Future<void> _openPendingProposalFromNotificationIfAny() async {
    var planId = HousingNavigationIntent.takePendingOpenProposalPlanId();
    if (!mounted) return;
    final db = AppDatabase.processScope;
    final transport = HousingProposalTransportService(db);
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null) {
      await orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing proposal open poll: $e\n$st');
      });
    }
    if (planId == null || planId.isEmpty) {
      // Fallback: if any plan has a non-amendment pending revision, open it.
      final plans = await housingPlansWithSelfParticipant(db);
      for (final p in plans) {
        final pendingId = await transport.resolvePendingRevisionIdForPlan(p.id);
        if (pendingId == null) continue;
        final isAmendment = await pendingRevisionIsAmendment(
          db,
          p.id,
          revisionId: pendingId,
          reconcileFirst: false,
        );
        if (!isAmendment) {
          planId = p.id;
          break;
        }
      }
    }
    if (planId == null || planId.isEmpty) return;

    final pendingId = await transport.resolvePendingRevisionIdForPlan(planId);
    if (pendingId == null) {
      debugPrint('housing: no pendingRevisionId on plan $planId');
      return;
    }
    if (!mounted) return;
    await openHousingPendingProposalOrAmendment(
      context,
      db: db,
      planId: planId,
      prefs: widget.prefs,
      revisionId: pendingId,
      isAmendment: false,
    );
    if (mounted) _reloadEntry();
  }

  void _reloadEntry() {
    setState(() {
      _workbenchReloadToken++;
      _entryFuture = _loadEntry();
    });
  }

  Future<_HousingEntrySnapshot> _loadEntry() async {
    final db = AppDatabase.processScope;
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) {
      debugPrint('housing entry inbox poll skipped: relay not configured');
    } else {
      await orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing entry inbox poll: $e\n$st');
      });
    }
    final plans = await housingPlansWithSelfParticipant(db);
    final transport = HousingProposalTransportService(db);
    for (final plan in plans) {
      await transport.expireOpenRevisionsForPlan(plan.id);
      await transport.reconcileStalePackagePending(plan.id);
    }

    Plan? primaryActivePlan;
    ProposalPackage? primaryActivePackage;
    for (final plan in plans) {
      if (!await transport.hasActiveRevision(plan.id)) continue;
      if (primaryActivePlan != null) {
        primaryActivePlan = null;
        primaryActivePackage = null;
        break;
      }
      primaryActivePlan = plan;
      primaryActivePackage = await (db.select(db.proposalPackages)
            ..where((t) => t.planId.equals(plan.id)))
          .getSingleOrNull();
    }

    if (plans.length != 1) {
      return _HousingEntrySnapshot(
        plans: plans,
        primaryActivePlan: primaryActivePlan,
        primaryActivePackage: primaryActivePackage,
      );
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
      primaryActivePlan: primaryActivePlan,
      primaryActivePackage: primaryActivePackage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exitHousingModule(context);
      },
      child: FutureBuilder<_HousingEntrySnapshot>(
        future: _entryFuture ?? _loadEntry(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.housingPlanLoadError('${snap.error}'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _reloadEntry,
                        child: Text(l10n.commonRestart),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final entry =
              snap.data ?? const _HousingEntrySnapshot(plans: <Plan>[]);
          final plans = entry.plans;
          final primary = entry.primaryActivePlan;
          final primaryPkg = entry.primaryActivePackage;
          if (primary != null && primaryPkg != null) {
            return HousingActivePlanScreen(
              key: ValueKey('active-hub-${primary.id}'),
              planId: primary.id,
              packageId: primaryPkg.id,
              prefs: widget.prefs,
            );
          }
          if (plans.length > 1) {
            return HousingWorkbenchScreen(
              key: ValueKey(_workbenchReloadToken),
              prefs: widget.prefs,
            );
          }
          if (plans.isEmpty) {
            return HousingPlanScreen(prefs: widget.prefs);
          }
          final pkg = entry.package;
          if (pkg?.pendingRevisionId != null) {
            return FutureBuilder<bool>(
              future: pendingRevisionIsAmendment(
                AppDatabase.processScope,
                plans.single.id,
              ),
              builder: (context, amendmentSnap) {
                if (amendmentSnap.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final isAmendment = amendmentSnap.data ?? false;
                if (isAmendment && primary != null && primaryPkg != null) {
                  return HousingActivePlanScreen(
                    key: ValueKey('active-hub-${primary.id}'),
                    planId: primary.id,
                    packageId: primaryPkg.id,
                    prefs: widget.prefs,
                  );
                }
                return HousingInviteProposalScreen(
                  db: AppDatabase.processScope,
                  planId: plans.single.id,
                  prefs: widget.prefs,
                );
              },
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
