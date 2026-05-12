import 'package:flutter/material.dart';

import '../housing/quiet_hours_week_grid.dart';

String _formatHm24(int minuteFromMidnight) {
  final h = minuteFromMidnight ~/ 60;
  final m = minuteFromMidnight % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String _narrowDayLetter(MaterialLocalizations mat, int calendarWeekday0Sun) {
  return mat.narrowWeekdays[calendarWeekday0Sun % 7];
}

int _calendarWeekdayForUiColumn(MaterialLocalizations mat, int uiDayIndex) {
  return (mat.firstDayOfWeekIndex + uiDayIndex) % 7;
}

/// Half-hour week grid: tap toggles between 0 (owner use) and 1 (offered to co-sharers).
class BinaryAvailabilityWeekEditor extends StatelessWidget {
  const BinaryAvailabilityWeekEditor({
    super.key,
    required this.grid,
    required this.uiSelectedDayIndex,
    required this.onSelectDay,
    required this.onToggleCell,
    required this.labelAvailable,
    required this.labelOwnerOnly,
    this.rowHeight = 22,
  });

  final List<List<int>> grid;
  final int uiSelectedDayIndex;
  final ValueChanged<int> onSelectDay;
  final void Function(int uiDay, int slot) onToggleCell;
  final String labelAvailable;
  final String labelOwnerOnly;
  final double rowHeight;

  static const double _timeColWidth = 52;

  @override
  Widget build(BuildContext context) {
    final mat = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dayLetters = List.generate(
      kQuietHoursDays,
      (i) => _narrowDayLetter(mat, _calendarWeekdayForUiColumn(mat, i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: _timeColWidth),
            for (var i = 0; i < kQuietHoursDays; i++)
              Expanded(
                child: Center(
                  child: ChoiceChip(
                    label: Text(dayLetters[i]),
                    selected: uiSelectedDayIndex == i,
                    onSelected: (_) => onSelectDay(i),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Wrap(
            spacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 14, height: 14, color: scheme.primaryContainer),
                  const SizedBox(width: 6),
                  Text(labelAvailable, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 14, height: 14, color: scheme.surfaceContainerHighest),
                  const SizedBox(width: 6),
                  Text(labelOwnerOnly, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kQuietHoursSlotsPerDay,
          itemBuilder: (context, slot) {
            final minute = slot * 30;
            final timeLabel = _formatHm24(minute);
            final v = grid[uiSelectedDayIndex][slot] == 1 ? 1 : 0;
            final fill = v == 1 ? scheme.primaryContainer : scheme.surfaceContainerHighest;
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: _timeColWidth,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(timeLabel, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: fill,
                      child: InkWell(
                        onTap: () => onToggleCell(uiSelectedDayIndex, slot),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
