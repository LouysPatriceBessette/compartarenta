import 'package:flutter/material.dart';

/// Canonical short validity choices (invitations, proposal acceptance windows, …).
///
/// Keep these four options everywhere so UX stays consistent.
abstract final class StandardValidityDurations {
  static const List<Duration> values = [
    Duration(hours: 3),
    Duration(hours: 8),
    Duration(hours: 24),
    Duration(hours: 48),
  ];

  static String segmentLabel(Duration d) {
    final h = d.inHours;
    return '${h}h';
  }
}

/// Segmented control for [StandardValidityDurations.values].
class StandardValidityDurationSegmented extends StatelessWidget {
  const StandardValidityDurationSegmented({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Duration selected;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final safe = StandardValidityDurations.values.contains(selected)
        ? selected
        : StandardValidityDurations.values[2];
    return SegmentedButton<Duration>(
      segments: [
        for (final d in StandardValidityDurations.values)
          ButtonSegment<Duration>(
            value: d,
            label: Text(StandardValidityDurations.segmentLabel(d)),
          ),
      ],
      selected: {safe},
      onSelectionChanged: (s) {
        if (s.isEmpty) return;
        onChanged(s.first);
      },
    );
  }
}
