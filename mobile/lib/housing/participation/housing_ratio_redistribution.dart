import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../split_minor_by_weights.dart';

/// Redistributes each departing participant's ratio weights equally among
/// [remainingParticipantIds] for every line/group bucket.
Future<void> redistributeRatiosAfterDeparture({
  required AppDatabase db,
  required String planId,
  required String departingParticipantId,
  required List<String> remainingParticipantIds,
}) async {
  if (remainingParticipantIds.isEmpty) return;

  final allRatios = await db.listPlanRatios(planId);
  final departingRatios =
      allRatios.where((r) => r.participantId == departingParticipantId).toList();
  if (departingRatios.isEmpty) return;

  for (final depRatio in departingRatios) {
    final remainingRatios = allRatios
        .where(
          (r) =>
              r.participantId != departingParticipantId &&
              r.lineId == depRatio.lineId &&
              r.groupId == depRatio.groupId &&
              remainingParticipantIds.contains(r.participantId),
        )
        .toList();
    if (remainingRatios.isEmpty) {
      await (db.delete(db.planRatios)..where((t) => t.id.equals(depRatio.id)))
          .go();
      continue;
    }

    final equalWeights = List<int>.generate(
      remainingRatios.length,
      (i) => 10000 ~/ remainingRatios.length + (i < 10000 % remainingRatios.length ? 1 : 0),
    );
    final shares = splitMinorByWeights(depRatio.weight, equalWeights);
    for (var i = 0; i < remainingRatios.length; i++) {
      final row = remainingRatios[i];
      await db.upsertPlanRatio(
        PlanRatiosCompanion(
          id: drift.Value(row.id),
          planId: drift.Value(row.planId),
          participantId: drift.Value(row.participantId),
          lineId: drift.Value(row.lineId),
          groupId: drift.Value(row.groupId),
          weight: drift.Value(row.weight + shares[i]),
          createdAt: drift.Value(row.createdAt),
        ),
      );
    }
    await (db.delete(db.planRatios)..where((t) => t.id.equals(depRatio.id)))
        .go();
  }
}
