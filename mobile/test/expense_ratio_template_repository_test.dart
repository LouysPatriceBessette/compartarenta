import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/expense_form/expense_ratio_template_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listSelectableForPlan hides equal parts and dedupes signatures', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-like-filter';
    final repo = ExpenseRatioTemplateRepository(db);
    final now = DateTime.utc(2026, 6, 1);

    await repo.registerIfNew(
      planId: planId,
      displayTitle: 'Loyer',
      weights: {'$planId:self': 5000, '$planId:p0': 5000},
      createdAt: now,
    );
    await db.upsertPlanRatioTemplate(
      PlanRatioTemplatesCompanion.insert(
        id: 'ratioTpl:dup',
        planId: planId,
        displayTitle: 'Loyer copy',
        weightsJson: ExpenseRatioTemplateRepository.encodeWeights({
          '$planId:self': 5000,
          '$planId:p0': 5000,
        }),
        createdAt: now.add(const Duration(microseconds: 1)),
      ),
    );
    await repo.registerIfNew(
      planId: planId,
      displayTitle: 'Carottes',
      weights: {'$planId:self': 0, '$planId:p0': 10000},
      createdAt: now,
    );

    final selectable = await repo.listSelectableForPlan(planId);
    expect(selectable.length, 1);
    expect(selectable.single.displayTitle, 'Carottes');

    await db.close();
  });
}
