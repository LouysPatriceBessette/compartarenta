import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'expense_recurrence_spec.dart';

/// Picks agreement-bounded range and confirms recurrence kind.
Future<ExpenseRecurrenceSpec?> showExpenseRecurrenceFlow({
  required BuildContext context,
  required DateTime periodStart,
  required DateTime periodEnd,
  required ExpenseRecurrenceSpec? initial,
}) async {
  final l10n = AppLocalizations.of(context);
  final startLocal = DateUtils.dateOnly(periodStart.toLocal());
  final endLocal = DateUtils.dateOnly(periodEnd.toLocal());
  final range = await showDateRangePicker(
    context: context,
    firstDate: startLocal,
    lastDate: endLocal,
    initialDateRange: DateTimeRange(
      start: startLocal,
      end: startLocal,
    ),
  );
  if (range == null || !context.mounted) return null;

  final anchor = range.start.toUtc().toIso8601String().split('T').first;
  final day = range.start.day;
  final spanDays = range.end.difference(range.start).inDays;

  final options = <_RecurrenceChoice>[
    _RecurrenceChoice(
      label: l10n.housingExpenseRecurrenceMonthlyDay(day, anchor),
      spec: MonthlyDayRecurrence(day: day, anchorIso: anchor),
    ),
    if (spanDays >= 1)
      _RecurrenceChoice(
        label: l10n.housingExpenseRecurrenceEveryNDays(spanDays, anchor),
        spec: EveryNDaysRecurrence(n: spanDays, anchorIso: anchor),
      ),
    _RecurrenceChoice(
      label: l10n.housingExpenseRecurrenceNthWeekday(anchor),
      spec: NthWeekdayRecurrence(
        ordinal: 2,
        weekday: range.start.weekday,
        anchorIso: anchor,
      ),
    ),
  ];

  ExpenseRecurrenceSpec? picked = initial ?? options.first.spec;
  if (!context.mounted) return picked;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.housingExpenseRecurrenceConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in options)
                    RadioListTile<ExpenseRecurrenceSpec>(
                      title: Text(o.label),
                      value: o.spec,
                      groupValue: picked,
                      onChanged: (v) => setDialogState(() => picked = v),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.housingPlanCancel),
              ),
              FilledButton(
                onPressed: picked == null ? null : () => Navigator.pop(ctx),
                child: Text(l10n.housingPlanSave),
              ),
            ],
          );
        },
      );
    },
  );
  return picked;
}

class _RecurrenceChoice {
  _RecurrenceChoice({required this.label, required this.spec});
  final String label;
  final ExpenseRecurrenceSpec spec;
}
