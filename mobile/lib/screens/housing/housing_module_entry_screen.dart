import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../prefs/app_preferences.dart';
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
  late final Future<List<Plan>> _housingWithSelfFuture =
      housingPlansWithSelfParticipant(AppDatabase.processScope);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: FutureBuilder<List<Plan>>(
        future: _housingWithSelfFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final plans = snap.data ?? const <Plan>[];
          if (plans.length > 1) {
            return HousingWorkbenchScreen(prefs: widget.prefs);
          }
          if (plans.isEmpty) {
            return HousingPlanScreen(prefs: widget.prefs);
          }
          return FutureBuilder<ProposalPackage?>(
            future:
                (AppDatabase.processScope.select(
                      AppDatabase.processScope.proposalPackages,
                    )..where((t) => t.planId.equals(plans.single.id)))
                    .getSingleOrNull(),
            builder: (context, pkgSnap) {
              if (pkgSnap.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final pkg = pkgSnap.data;
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
              return FutureBuilder<bool>(
                future: HousingProposalTransportService(
                  AppDatabase.processScope,
                ).planHasArchives(plans.single.id),
                builder: (context, archiveSnap) {
                  if (archiveSnap.connectionState != ConnectionState.done) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (archiveSnap.data == true) {
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
              );
            },
          );
        },
      ),
    );
  }
}
