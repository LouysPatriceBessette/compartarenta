import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../prefs/app_preferences.dart';
import 'housing_plan_screen.dart';
import 'housing_workbench_screen.dart';

/// Count of housing [Plan] rows where this device has a `planId:self` participant.
Future<int> housingPlansWithSelfParticipantCount(AppDatabase db) async {
  final housing =
      await (db.select(db.plans)..where((t) => t.type.equals('housing'))).get();
  var n = 0;
  for (final p in housing) {
    final self = await (db.select(db.participants)
          ..where((t) => t.id.equals('${p.id}:self')))
        .getSingleOrNull();
    if (self != null) n++;
  }
  return n;
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
  late final Future<int> _housingWithSelfCountFuture =
      housingPlansWithSelfParticipantCount(AppDatabase.processScope);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _housingWithSelfCountFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final n = snap.data ?? 0;
        if (n > 1) {
          return HousingWorkbenchScreen(prefs: widget.prefs);
        }
        return HousingPlanScreen(prefs: widget.prefs);
      },
    );
  }
}
