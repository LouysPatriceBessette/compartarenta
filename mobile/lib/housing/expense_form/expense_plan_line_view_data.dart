import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'expense_amount_parse.dart';
import 'expense_ratio_template_repository.dart';
import 'plan_participant_dropdown_value.dart';
import 'expense_recurrence_labels.dart';
import 'expense_recurrence_spec.dart';
import 'expense_split_grid_logic.dart';

/// Loaded expense line for read-only presentation (proposal carousel, etc.).
class ExpensePlanLineViewData {
  const ExpensePlanLineViewData({
    required this.title,
    required this.description,
    required this.isRecurring,
    required this.recurrenceSummary,
    required this.amountText,
    required this.amountIsBudgetCap,
    required this.paymentResponsibleLabel,
    required this.split,
    required this.likeTemplateTitle,
    required this.currencyCode,
  });

  final String title;
  final String description;
  final bool isRecurring;
  final String? recurrenceSummary;
  final String amountText;
  final bool amountIsBudgetCap;
  final String paymentResponsibleLabel;
  final ExpenseSplitGridState? split;
  final String? likeTemplateTitle;
  final String currencyCode;

  static Future<ExpensePlanLineViewData?> load({
    required AppDatabase db,
    required String planId,
    required PlanLine line,
    required List<String> participantIds,
    required List<String> participantNames,
    required AppLocalizations l10n,
    required String dateFormat,
    required String defaultCurrency,
  }) async {
    final recurrence =
        ExpenseRecurrenceSpec.parseStored(line.recurrenceSpecJson) ??
        ExpenseRecurrenceSpec.fromLegacyDayOfMonth(line.recurrenceDayOfMonth);

    String paymentLabel = l10n.housingExpensePaymentResponsibleAll;
    final payId = resolvePlanParticipantDropdownValue(
      line.paymentResponsibleParticipantId,
      participantIds,
    );
    if (payId != null) {
      final idx = participantIds.indexOf(payId);
      if (idx >= 0) {
        paymentLabel = participantNames[idx];
      }
    }

    String? likeTitle;
    if (line.ratioTemplateId != null) {
      final templates = await ExpenseRatioTemplateRepository(db).listForPlan(
        planId,
      );
      for (final t in templates) {
        if (t.id == line.ratioTemplateId) {
          likeTitle = t.displayTitle;
          break;
        }
      }
    }

    final ratios = await db.listPlanRatios(planId);
    final weights = {
      for (final r in ratios.where((r) => r.lineId == line.id))
        r.participantId: r.weight,
    };
    final total = line.amountMinor ?? 0;
    ExpenseSplitGridState? split;
    if (total > 0 && weights.length == participantIds.length) {
      split = ExpenseSplitGridState(
        participantIds: participantIds,
        displayNames: participantNames,
        rows: [
          for (var i = 0; i < participantIds.length; i++)
            ExpenseSplitRow(
              participantId: participantIds[i],
              displayName: participantNames[i],
              amountMinor: 0,
              weightBps: weights[participantIds[i]] ?? 0,
            ),
        ],
        totalMinor: total,
      )..applyWeights(weights);
    }

    return ExpensePlanLineViewData(
      title: line.title,
      description: line.description,
      isRecurring: line.isRecurring,
      recurrenceSummary: line.isRecurring && recurrence != null
          ? formatRecurrenceSpecSummary(l10n, dateFormat, recurrence)
          : null,
      amountText: minorToAmountText(line.amountMinor),
      amountIsBudgetCap: line.amountIsBudgetCap,
      paymentResponsibleLabel: paymentLabel,
      split: split,
      likeTemplateTitle: likeTitle,
      currencyCode: line.currency.trim().isEmpty
          ? defaultCurrency
          : line.currency.trim(),
    );
  }
}
