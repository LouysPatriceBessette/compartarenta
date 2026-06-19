import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_inline_draft_plan.dart';
import 'package:compartarenta/housing/housing_plan_id.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveInlineHousingDraftPlanId reuses best orphan draft', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const orphan = 'housing:11111111-1111-4111-8111-111111111111';
    const empty = 'housing:22222222-2222-4222-8222-222222222222';
    final now = DateTime.utc(2026, 6, 19);

    await db.upsertPlan(
      PlansCompanion.insert(
        id: orphan,
        type: 'housing',
        createdAt: now,
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$orphan',
        planId: orphan,
        periodStart: now,
        periodEnd: now.add(const Duration(days: 180)),
        createdAt: now,
      ),
    );
    await db.upsertPlan(
      PlansCompanion.insert(
        id: empty,
        type: 'housing',
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    );

    expect(await resolveInlineHousingDraftPlanId(db), orphan);
  });

  test('resolveInlineHousingDraftPlanId mints once when no draft exists', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await resolveInlineHousingDraftPlanId(db);
    expect(id.startsWith(kHousingPlanIdPrefix), isTrue);
    expect(looksLikeUuid(id.substring(kHousingPlanIdPrefix.length)), isTrue);
  });
}
