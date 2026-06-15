import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../widgets/dialog_tap_guard.dart';
import '../../util/week_start_calendar.dart';
import 'expense_recurrence_labels.dart';
import 'expense_recurrence_spec.dart';

/// Picks a recurrence range (from the 1st of the current month through plan end)
/// and confirms recurrence kind.
///
/// Returns `null` when the user cancels either step or does not confirm a type.
Future<ExpenseRecurrenceSpec?> showExpenseRecurrenceFlow({
  required BuildContext context,
  required AppPreferences prefs,
  required DateTime periodEnd,
  required ExpenseRecurrenceSpec? initial,
  required String dateFormat,
}) async {
  return DialogTapGuard.run<ExpenseRecurrenceSpec?>(
    'expenseRecurrenceFlow',
    () async {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final endLocal = DateUtils.dateOnly(periodEnd.toLocal());
  var firstDate = DateUtils.dateOnly(DateTime(now.year, now.month, 1));
  if (firstDate.isAfter(endLocal)) {
    firstDate = endLocal;
  }
  final range = await showAppDateRangePicker(
    context: context,
    prefs: prefs,
    firstDate: firstDate,
    lastDate: endLocal,
    saveText: l10n.housingExpenseRecurrenceUseRange,
  );
  if (range == null || !context.mounted) return null;

  final anchor = calendarDateIso(range.start);
  final anchorDisplay = formatRecurrenceAnchorIso(anchor, dateFormat);
  final day = range.start.day;
  final spanDays = inclusiveCalendarDayCount(range.start, range.end);
  final nthOrdinal = ordinalOfWeekdayInMonth(range.start);

  final options = <_RecurrenceChoice>[
    _RecurrenceChoice(
      label: l10n.housingExpenseRecurrenceMonthlyDay(day, anchorDisplay),
      spec: MonthlyDayRecurrence(day: day, anchorIso: anchor),
    ),
    if (spanDays >= 2)
      _RecurrenceChoice(
        label: l10n.housingExpenseRecurrenceEveryNDays(spanDays, anchorDisplay),
        spec: EveryNDaysRecurrence(n: spanDays, anchorIso: anchor),
      ),
    _RecurrenceChoice(
      label: recurrenceNthWeekdayOfMonthLabel(
        l10n,
        anchorDate: range.start,
        anchorIso: anchor,
        dateFormat: dateFormat,
      ),
      spec: NthWeekdayRecurrence(
        ordinal: nthOrdinal,
        weekday: range.start.weekday,
        anchorIso: anchor,
      ),
    ),
  ];

  ExpenseRecurrenceSpec? picked = initial;
  if (!context.mounted) return null;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
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
                    ListTile(
                      title: Text(o.label),
                      leading: Icon(
                        picked == o.spec
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      onTap: () => setDialogState(() => picked = o.spec),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.housingPlanCancel),
              ),
              FilledButton(
                onPressed: picked == null ? null : () => Navigator.pop(ctx, true),
                child: Text(l10n.housingPlanSave),
              ),
            ],
          );
        },
      );
    },
  );
  if (confirmed != true || picked == null) return null;
  return picked;
    },
  );
}

class _RecurrenceChoice {
  _RecurrenceChoice({required this.label, required this.spec});
  final String label;
  final ExpenseRecurrenceSpec spec;
}
