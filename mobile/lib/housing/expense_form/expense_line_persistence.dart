import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../../housing/housing_plan_draft_backup.dart';
import '../../prefs/app_preferences.dart';
import 'expense_ratio_template_repository.dart';
import 'expense_recurrence_spec.dart';
import 'expense_split_grid_logic.dart';

/// Saves one expense line + ratios + optional ratio template from the unified form.
class ExpenseLinePersistence {
  ExpenseLinePersistence(this._db);

  final AppDatabase _db;

  Future<void> save({
    required String planId,
    required String? existingLineId,
    required String title,
    required String description,
    required String currency,
    required bool isRecurring,
    required ExpenseRecurrenceSpec? recurrenceSpec,
    required int? amountMinor,
    required bool amountIsBudgetCap,
    required String? paymentResponsibleParticipantId,
    required ExpenseSplitGridState? split,
    required int sortOrder,
    required DateTime createdAt,
    required ExpenseRatioTemplateRepository templates,
    AppPreferences? prefsForBackup,
  }) async {
    final lineId = existingLineId ??
        HousingPlanDraftBackup.newLineId(createdAt);
    final specJson = recurrenceSpec == null
        ? ''
        : ExpenseRecurrenceSpec.encode(recurrenceSpec);

    String? ratioTemplateId;
    if (split != null &&
        split.totalMinor > 0 &&
        !split.weightsAreEqualParts) {
      ratioTemplateId = await templates.registerIfNew(
        planId: planId,
        displayTitle: title,
        weights: split.weightsByParticipant(),
        createdAt: createdAt,
      );
    }

    await _db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: lineId,
        planId: planId,
        isRecurring: isRecurring,
        title: title.trim(),
        currency: currency,
        amountUsesRange: const drift.Value(false),
        amountMinor: amountMinor == null
            ? const drift.Value.absent()
            : drift.Value(amountMinor),
        minAmountMinor: const drift.Value.absent(),
        maxAmountMinor: const drift.Value.absent(),
        amountIsBudgetCap: drift.Value(amountIsBudgetCap),
        description: drift.Value(description.trim()),
        cadence: const drift.Value('monthly'),
        recurrenceDayOfMonth: const drift.Value.absent(),
        recurrenceSpecJson: drift.Value(specJson),
        sortOrder: drift.Value(sortOrder),
        groupId: const drift.Value(null),
        paymentResponsibleParticipantId: drift.Value(
          paymentResponsibleParticipantId,
        ),
        ratioTemplateId: drift.Value(ratioTemplateId),
        createdAt: createdAt,
      ),
    );

    final ratiosForLine = <PlanRatio>[];
    if (split != null && split.totalMinor > 0) {
      await (_db.delete(_db.planRatios)
            ..where((t) => t.lineId.equals(lineId)))
          .go();
      for (final row in split.rows) {
        final ratio = PlanRatio(
          id: 'ratio:$planId:$lineId:${row.participantId}',
          planId: planId,
          participantId: row.participantId,
          lineId: lineId,
          groupId: null,
          weight: row.weightBps,
          createdAt: createdAt,
        );
        ratiosForLine.add(ratio);
        await _db.upsertPlanRatio(
          PlanRatiosCompanion.insert(
            id: ratio.id,
            planId: ratio.planId,
            participantId: ratio.participantId,
            lineId: drift.Value(ratio.lineId),
            groupId: const drift.Value.absent(),
            weight: ratio.weight,
            createdAt: ratio.createdAt,
          ),
        );
      }
    }

    final prefs = prefsForBackup;
    if (prefs != null) {
      await HousingPlanDraftBackup.recordExpenseSave(
        db: _db,
        prefs: prefs,
        line: PlanLine(
          id: lineId,
          planId: planId,
          isRecurring: isRecurring,
          title: title.trim(),
          currency: currency,
          amountUsesRange: false,
          amountMinor: amountMinor,
          minAmountMinor: null,
          maxAmountMinor: null,
          description: description.trim(),
          cadence: 'monthly',
          recurrenceDayOfMonth: null,
          sortOrder: sortOrder,
          groupId: null,
          amountIsBudgetCap: amountIsBudgetCap,
          paymentResponsibleParticipantId: paymentResponsibleParticipantId,
          recurrenceSpecJson: specJson,
          ratioTemplateId: ratioTemplateId,
          createdAt: createdAt,
        ),
        ratiosForLine: ratiosForLine,
      );
      await _db.syncWebStorageToDisk();
    }
  }
}
