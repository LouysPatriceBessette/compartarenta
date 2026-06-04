import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_ratio_redistribution.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redistributeRatiosAfterDeparture splits departing weight equally', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'housing:test';
    const p0 = 'housing:test:p0';
    const p1 = 'housing:test:p1';
    const p2 = 'housing:test:p2';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    for (final id in [p0, p1, p2]) {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: id,
          displayName: id,
          avatarId: 'a',
          createdAt: DateTime.utc(2026),
        ),
      );
    }

    const lineId = 'line1';
    for (final entry in [
      (p0, 3333),
      (p1, 3333),
      (p2, 3334),
    ]) {
      await db.upsertPlanRatio(
        PlanRatiosCompanion.insert(
          id: '${lineId}_${entry.$1}',
          planId: planId,
          participantId: entry.$1,
          lineId: drift.Value(lineId),
          weight: entry.$2,
          createdAt: DateTime.utc(2026),
        ),
      );
    }

    await redistributeRatiosAfterDeparture(
      db: db,
      planId: planId,
      departingParticipantId: p2,
      remainingParticipantIds: [p0, p1],
    );

    final ratios = await db.listPlanRatios(planId);
    expect(ratios.length, 2);
    final w0 = ratios.firstWhere((r) => r.participantId == p0).weight;
    final w1 = ratios.firstWhere((r) => r.participantId == p1).weight;
    expect(w0 + w1, 10000);
    expect((w0 - w1).abs(), lessThanOrEqualTo(1));
    expect(w0, greaterThan(3333));
    expect(w1, greaterThan(3333));
  });
}
