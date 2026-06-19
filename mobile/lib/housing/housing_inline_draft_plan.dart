import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import 'housing_plan_id.dart';
import 'proposals/housing_proposal_transport_service.dart';

/// Resolves the housing plan row for the inline wizard on [HousingModuleEntryScreen].
///
/// While the author has not yet earned a `:self` participant row, entry reloads
/// (inbox ticks) must not mint a new UUID on every rebuild. Reuse the best
/// existing orphan draft, or create one id once per session.
Future<String> resolveInlineHousingDraftPlanId(AppDatabase db) async {
  final transport = HousingProposalTransportService(db);
  final rows = await (db.select(db.plans)
        ..where((t) => t.type.equals('housing'))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
      .get();

  String? bestId;
  var bestScore = -1;
  for (final plan in rows) {
    if (await transport.isHiddenDraftPlan(plan.id)) continue;
    if (await transport.hasActiveRevision(plan.id)) continue;
    final score = await _inlineDraftScore(db, plan.id);
    if (score > bestScore) {
      bestScore = score;
      bestId = plan.id;
    }
  }
  return bestId ?? newHousingPlanId();
}

Future<int> _inlineDraftScore(AppDatabase db, String planId) async {
  var score = 0;
  if (await db.getAgreementForPlan(planId) != null) score += 4;
  score += (await db.listPlanLines(planId)).length * 3;
  final participants = await db.listParticipants();
  score += participants
      .where(
        (p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'),
      )
      .length;
  return score;
}
