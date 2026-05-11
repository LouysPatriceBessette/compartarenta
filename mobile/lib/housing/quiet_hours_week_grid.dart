import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Half-hour slots per day: 00:00, 00:30, …, 23:30 (48 slots).
const int kQuietHoursSlotsPerDay = 48;

const int kQuietHoursDays = 7;

List<List<int>> quietHoursEmptyGrid() =>
    List.generate(kQuietHoursDays, (_) => List<int>.filled(kQuietHoursSlotsPerDay, 0));

List<List<int>> quietHoursDeepCopy(List<List<int>> src) {
  return List.generate(
    kQuietHoursDays,
    (d) => List<int>.from(src[d]),
  );
}

void quietHoursReplaceFrom(List<List<int>> target, List<List<int>> source) {
  for (var d = 0; d < kQuietHoursDays; d++) {
    for (var s = 0; s < kQuietHoursSlotsPerDay; s++) {
      target[d][s] = source[d][s].clamp(0, 2);
    }
  }
}

List<int> quietHoursFlatten(List<List<int>> grid) {
  final out = List<int>.filled(kQuietHoursDays * kQuietHoursSlotsPerDay, 0);
  for (var d = 0; d < kQuietHoursDays; d++) {
    for (var s = 0; s < kQuietHoursSlotsPerDay; s++) {
      out[d * kQuietHoursSlotsPerDay + s] = grid[d][s].clamp(0, 2);
    }
  }
  return out;
}

List<List<int>>? quietHoursParseFromJson(dynamic raw) {
  if (raw is! List || raw.length != kQuietHoursDays) return null;
  final g = quietHoursEmptyGrid();
  for (var d = 0; d < kQuietHoursDays; d++) {
    final row = raw[d];
    if (row is! List || row.length != kQuietHoursSlotsPerDay) return null;
    for (var s = 0; s < kQuietHoursSlotsPerDay; s++) {
      final v = row[s];
      if (v is! num) return null;
      g[d][s] = v.toInt().clamp(0, 2);
    }
  }
  return g;
}

/// One contiguous arc on the circular week timeline (336 half-hours).
class _QuietArc {
  _QuietArc(this.startG, this.lengthSlots, this.state);

  final int startG;
  final int lengthSlots;
  final int state;

  bool containsG(int g) {
    const n = kQuietHoursDays * kQuietHoursSlotsPerDay;
    for (var k = 0; k < lengthSlots; k++) {
      if ((startG + k) % n == g) return true;
    }
    return false;
  }
}

List<_QuietArc> _findCircularArcs(List<int> flat) {
  const n = kQuietHoursDays * kQuietHoursSlotsPerDay;
  final globalSeen = List<bool>.filled(n, false);
  final arcs = <_QuietArc>[];

  for (var seed = 0; seed < n; seed++) {
    final v = flat[seed];
    if (v == 0 || globalSeen[seed]) continue;

    final comp = <int>{};
    final q = Queue<int>()..add(seed);
    while (q.isNotEmpty) {
      final c = q.removeFirst();
      if (globalSeen[c]) continue;
      if (flat[c] != v) continue;
      globalSeen[c] = true;
      comp.add(c);
      q.add((c - 1 + n) % n);
      q.add((c + 1) % n);
    }

    final any = comp.first;
    var left = any;
    for (var k = 0; k < n; k++) {
      final nxt = (left - 1 + n) % n;
      if (!comp.contains(nxt)) break;
      left = nxt;
    }

    var len = 0;
    var cur = left;
    for (var k = 0; k < n; k++) {
      if (!comp.contains(cur)) break;
      len++;
      cur = (cur + 1) % n;
    }
    arcs.add(_QuietArc(left, len, v));
  }
  return arcs;
}

/// Contiguous row interval within one UI day column for one visual block.
class QuietHoursDaySegment {
  QuietHoursDaySegment({
    required this.startRow,
    required this.endRowExclusive,
    required this.state,
    required this.title,
    required this.rangeLabel,
  });

  final int startRow;
  final int endRowExclusive;
  final int state;
  final String title;
  final String rangeLabel;
}

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

/// [startG] global half-hour index 0..335; [lengthSlots] along the circular week.
String _formatArcRangeLabel(MaterialLocalizations mat, int startG, int lengthSlots) {
  const slotsPerDay = kQuietHoursSlotsPerDay;
  const n = kQuietHoursDays * slotsPerDay;
  if (lengthSlots <= 0) return '';
  final endExclusiveG = (startG + lengthSlots) % n;
  final lastG = (endExclusiveG - 1 + n) % n;

  final startUi = startG ~/ slotsPerDay;
  final startSlot = startG % slotsPerDay;
  final lastUi = lastG ~/ slotsPerDay;
  final lastSlot = lastG % slotsPerDay;

  final startMin = startSlot * 30;
  final endMinInclusive = (lastSlot + 1) * 30 - 1;
  final d0 = _calendarWeekdayForUiColumn(mat, startUi);
  final d1 = _calendarWeekdayForUiColumn(mat, lastUi);
  final l0 = _narrowDayLetter(mat, d0);
  final l1 = _narrowDayLetter(mat, d1);
  final t0 = _formatHm24(startMin);
  final t1 = _formatHm24(endMinInclusive);
  if (l0 == l1) {
    return '$l0 $t0 – $t1';
  }
  return '$l0 $t0 – $l1 $t1';
}

List<QuietHoursDaySegment> quietHoursSegmentsForUiDay({
  required List<List<int>> grid,
  required int uiDayIndex,
  required MaterialLocalizations mat,
  required String labelAbsolute,
  required String labelModerate,
}) {
  final flat = quietHoursFlatten(grid);
  final arcs = _findCircularArcs(flat);
  final segments = <QuietHoursDaySegment>[];

  for (final arc in arcs) {
    final rowsThisDay = <int>[];
    for (var s = 0; s < kQuietHoursSlotsPerDay; s++) {
      final g = uiDayIndex * kQuietHoursSlotsPerDay + s;
      if (arc.containsG(g)) {
        rowsThisDay.add(s);
      }
    }
    if (rowsThisDay.isEmpty) continue;
    rowsThisDay.sort();
    var i = 0;
    while (i < rowsThisDay.length) {
      final rs = rowsThisDay[i];
      var re = rs;
      while (i + 1 < rowsThisDay.length && rowsThisDay[i + 1] == re + 1) {
        i++;
        re = rowsThisDay[i];
      }
      final title = arc.state == 1 ? labelAbsolute : labelModerate;
      final range = _formatArcRangeLabel(mat, arc.startG, arc.lengthSlots);
      segments.add(
        QuietHoursDaySegment(
          startRow: rs,
          endRowExclusive: re + 1,
          state: arc.state,
          title: title,
          rangeLabel: range,
        ),
      );
      i++;
    }
  }

  segments.sort((a, b) => a.startRow.compareTo(b.startRow));
  return segments;
}

class _QuietDayLetterButton extends StatelessWidget {
  const _QuietDayLetterButton({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                letter,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Weekday chips plus either a 30-minute edit grid or a read-only list of quiet periods for the selected day.
class QuietHoursWeekDayEditor extends StatelessWidget {
  const QuietHoursWeekDayEditor({
    super.key,
    required this.grid,
    required this.uiSelectedDayIndex,
    required this.onSelectDay,
    required this.editing,
    required this.onToggleCell,
    required this.labelAbsolute,
    required this.labelModerate,
    required this.emptyDayLabel,
    this.rowHeight = 22,
  });

  final List<List<int>> grid;
  final int uiSelectedDayIndex;
  final ValueChanged<int> onSelectDay;
  final bool editing;
  final void Function(int uiDay, int slot) onToggleCell;
  final String labelAbsolute;
  final String labelModerate;
  /// Shown when the selected day has no absolute or moderate quiet periods (view mode).
  final String emptyDayLabel;
  final double rowHeight;

  static const double _timeColWidth = 52;

  Widget _buildReadOnlyBody(BuildContext context, List<QuietHoursDaySegment> segments) {
    final scheme = Theme.of(context).colorScheme;
    final shown = segments.where((s) => s.state == 1 || s.state == 2).toList();
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Center(
          child: Text(
            emptyDayLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      if (i > 0) {
        final prev = shown[i - 1];
        final cur = shown[i];
        if (cur.startRow > prev.endRowExclusive) {
          children.add(_readOnlyGapSeparator(context, rowHeight));
        }
      }
      children.add(_readOnlyQuietPeriodRow(context, shown[i], rowHeight));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  static Widget _readOnlyGapSeparator(BuildContext context, double rowHeight) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _timeColWidth),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 1,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: scheme.outlineVariant),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _readOnlyQuietPeriodRow(
    BuildContext context,
    QuietHoursDaySegment seg,
    double rowHeight,
  ) {
    final span = seg.endRowExclusive - seg.startRow;
    final showRange = span > 1;
    final rawH = rowHeight * span;
    final blockHeight = showRange ? math.max(rawH, 40.0) : rawH;
    final fill = seg.state == 1 ? const Color(0xFFFFEBEE) : const Color(0xFFFFFDE7);
    final border = seg.state == 1 ? const Color(0xFFC62828) : const Color(0xFFF9A825);
    final timeLabel = _formatHm24(seg.startRow * 30);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: blockHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeColWidth,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Text(timeLabel, style: textTheme.bodySmall),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: fill,
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: border, width: 4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 4, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!showRange)
                        FittedBox(
                          alignment: AlignmentDirectional.centerStart,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            seg.title,
                            maxLines: 1,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color: seg.state == 1
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFFF57F17),
                            ),
                          ),
                        )
                      else
                        Text(
                          seg.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: seg.state == 1
                                ? const Color(0xFFB71C1C)
                                : const Color(0xFFF57F17),
                          ),
                        ),
                      if (showRange)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            seg.rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(height: 1.1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeGrid(BuildContext context, List<QuietHoursDaySegment> segments) {
    final segByStart = <int, QuietHoursDaySegment>{for (final s in segments) s.startRow: s};
    final segContinues = <int, bool>{};
    for (final s in segments) {
      for (var r = s.startRow + 1; r < s.endRowExclusive; r++) {
        segContinues[r] = true;
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: kQuietHoursSlotsPerDay,
      itemBuilder: (context, slot) {
        if (segContinues[slot] ?? false) {
          return const SizedBox.shrink();
        }

        final minute = slot * 30;
        final timeLabel = _formatHm24(minute);
        final segStart = segByStart[slot];

        late final Widget rightCell;
        if (segStart != null) {
          final span = segStart.endRowExclusive - segStart.startRow;
          final showRange = span > 1;
          final rawH = rowHeight * span;
          final blockHeight = showRange ? math.max(rawH, 40.0) : rawH;
          final fill = segStart.state == 1 ? const Color(0xFFFFEBEE) : const Color(0xFFFFFDE7);
          final border = segStart.state == 1 ? const Color(0xFFC62828) : const Color(0xFFF9A825);
          final startRow = segStart.startRow;
          rightCell = Material(
            color: fill,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: double.infinity,
              height: blockHeight,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: border, width: 4),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var k = 0; k < span - 1; k++)
                        SizedBox(
                          height: rowHeight,
                          child: InkWell(
                            onTap: () => onToggleCell(uiSelectedDayIndex, startRow + k),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      Expanded(
                        child: InkWell(
                          onTap: () => onToggleCell(uiSelectedDayIndex, startRow + span - 1),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 4, 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!showRange)
                              FittedBox(
                                alignment: AlignmentDirectional.centerStart,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  segStart.title,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                        color: segStart.state == 1
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFFF57F17),
                                      ),
                                ),
                              )
                            else
                              Text(
                                segStart.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                      color: segStart.state == 1
                                          ? const Color(0xFFB71C1C)
                                          : const Color(0xFFF57F17),
                                    ),
                              ),
                            if (showRange)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  segStart.rangeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        height: 1.1,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          rightCell = Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onToggleCell(uiSelectedDayIndex, slot),
              child: SizedBox(
                width: double.infinity,
                height: rowHeight,
              ),
            ),
          );
        }

        final h = segStart != null
            ? (() {
                final span = segStart.endRowExclusive - segStart.startRow;
                final showRange = span > 1;
                final rawH = rowHeight * span;
                return showRange ? math.max(rawH, 40.0) : rawH;
              })()
            : rowHeight;

        return SizedBox(
          height: h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _timeColWidth,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
                  child: Align(
                    alignment: segStart != null
                        ? AlignmentDirectional.topStart
                        : AlignmentDirectional.centerStart,
                    child: Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              Expanded(child: rightCell),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mat = MaterialLocalizations.of(context);
    final dayLetters = List.generate(
      kQuietHoursDays,
      (i) => _narrowDayLetter(mat, _calendarWeekdayForUiColumn(mat, i)),
    );

    final segments = quietHoursSegmentsForUiDay(
      grid: grid,
      uiDayIndex: uiSelectedDayIndex,
      mat: mat,
      labelAbsolute: labelAbsolute,
      labelModerate: labelModerate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < kQuietHoursDays; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 1,
                    end: 1,
                  ),
                  child: _QuietDayLetterButton(
                    letter: dayLetters[i],
                    selected: i == uiSelectedDayIndex,
                    onTap: () => onSelectDay(i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: editing ? _buildEditModeGrid(context, segments) : _buildReadOnlyBody(context, segments),
        ),
      ],
    );
  }
}
