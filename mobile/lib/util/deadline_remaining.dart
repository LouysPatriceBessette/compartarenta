import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'display_date.dart';

/// How [DeadlineRemaining.compute] classifies time until [deadlineUtc].
enum DeadlineRemainingKind {
  days,
  today,
  countdown,
  expired,
}

/// Snapshot of time remaining until a UTC deadline (for labels and enablement).
class DeadlineRemaining {
  const DeadlineRemaining._({
    required this.kind,
    this.days,
    this.countdownText,
  });

  final DeadlineRemainingKind kind;
  final int? days;
  final String? countdownText;

  bool get isExpired => kind == DeadlineRemainingKind.expired;

  /// Classifies [deadlineUtc] relative to [nowUtc].
  static DeadlineRemaining compute(DateTime deadlineUtc, DateTime nowUtc) {
    final remaining = deadlineUtc.difference(nowUtc);
    if (remaining <= Duration.zero) {
      return const DeadlineRemaining._(kind: DeadlineRemainingKind.expired);
    }
    if (remaining > const Duration(hours: 24)) {
      return DeadlineRemaining._(
        kind: DeadlineRemainingKind.days,
        days: remaining.inHours ~/ 24,
      );
    }
    if (remaining > const Duration(hours: 4)) {
      return const DeadlineRemaining._(kind: DeadlineRemainingKind.today);
    }
    return DeadlineRemaining._(
      kind: DeadlineRemainingKind.countdown,
      countdownText: formatCountdown(remaining),
    );
  }

  /// `HH:MM:SS` when ≥ 1 hour left; `MM:SS` when &lt; 1 hour.
  static String formatCountdown(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 99 * 3600 + 59 * 60 + 59);
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String label(AppLocalizations l10n) => switch (kind) {
        DeadlineRemainingKind.days => l10n.deadlineRemainingInDays(days!),
        DeadlineRemainingKind.today => l10n.deadlineRemainingToday,
        DeadlineRemainingKind.countdown =>
          l10n.deadlineRemainingCountdown(countdownText!),
        DeadlineRemainingKind.expired => l10n.deadlineRemainingExpired,
      };
}

/// Live-updating relative label for a UTC deadline (days / today / countdown / expired).
class DeadlineRelativeLabel extends StatefulWidget {
  const DeadlineRelativeLabel({
    super.key,
    required this.deadlineUtc,
    required this.l10n,
    this.textAlign = TextAlign.center,
    this.style,
    this.countdownStyle,
  });

  final DateTime deadlineUtc;
  final AppLocalizations l10n;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextStyle? countdownStyle;

  @override
  State<DeadlineRelativeLabel> createState() => _DeadlineRelativeLabelState();
}

class _DeadlineRelativeLabelState extends State<DeadlineRelativeLabel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _startTickIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DeadlineRelativeLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineUtc != widget.deadlineUtc) {
      _tick?.cancel();
      _startTickIfNeeded();
    }
  }

  void _startTickIfNeeded() {
    _tick?.cancel();
    if (!widget.deadlineUtc.isAfter(DateTime.now().toUtc())) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!widget.deadlineUtc.isAfter(DateTime.now().toUtc())) {
        _tick?.cancel();
        _tick = null;
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = DeadlineRemaining.compute(
      widget.deadlineUtc,
      DateTime.now().toUtc(),
    );
    final base = widget.style ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
    final textStyle = snapshot.kind == DeadlineRemainingKind.countdown
        ? (widget.countdownStyle ??
            base?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ))
        : snapshot.kind == DeadlineRemainingKind.expired
            ? base?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              )
            : base;

    return Text(
      snapshot.label(widget.l10n),
      textAlign: widget.textAlign,
      style: textStyle,
    );
  }
}

/// Title, absolute date/time, and live relative hint for a UTC deadline.
class DeadlineDisplay extends StatelessWidget {
  const DeadlineDisplay({
    super.key,
    required this.title,
    required this.deadlineUtc,
    required this.dateFormat,
    required this.l10n,
  });

  final String title;
  final DateTime deadlineUtc;
  final String dateFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whenText = formatPreferenceDateTime(deadlineUtc, dateFormat);
    final dateStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.12,
    );

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          whenText,
          textAlign: TextAlign.center,
          style: dateStyle,
        ),
        SizedBox(height: deadlineDateToRelativeGap(theme)),
        DeadlineRelativeLabel(
          deadlineUtc: deadlineUtc,
          l10n: l10n,
        ),
      ],
    );
  }
}

/// Gap after a date line before a relative deadline line (50% of body line height).
double deadlineDateToRelativeGap(ThemeData theme) {
  final style = theme.textTheme.bodyMedium;
  final fontSize = style?.fontSize ?? 14;
  final height = style?.height ?? 1.2;
  return fontSize * height * 0.5;
}
