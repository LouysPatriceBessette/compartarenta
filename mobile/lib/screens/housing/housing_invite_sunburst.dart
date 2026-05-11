import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/projection/plan_projection.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format_money.dart';

/// One inner-ring category (or uncategorized bucket) with total and focused participant share.
class InviteSunburstSlice {
  InviteSunburstSlice({
    required this.label,
    required this.totalMinor,
    required this.userMinor,
    required this.baseColor,
    required this.currency,
  });

  final String label;
  final int totalMinor;
  final int userMinor;
  final Color baseColor;
  /// ISO currency code used for legend formatting (plan or user preference).
  final String currency;

  double get userFraction =>
      totalMinor <= 0 ? 0.0 : (userMinor / totalMinor).clamp(0.0, 1.0);
}

int _weightLine(List<PlanRatio> ratios, String lineId, String participantId) {
  return ratios
      .where((r) => r.lineId == lineId && r.participantId == participantId)
      .fold<int>(0, (a, r) => a + r.weight);
}

int _weightGroup(List<PlanRatio> ratios, String groupId, String participantId) {
  return ratios
      .where((r) => r.groupId == groupId && r.participantId == participantId)
      .fold<int>(0, (a, r) => a + r.weight);
}

/// Inner-ring slices: each plan group with lines, then uncategorized lines.
List<InviteSunburstSlice> buildInviteSunburstSlices({
  required List<PlanLine> lines,
  required List<PlanGroup> groups,
  required List<PlanRatio> ratios,
  required String participantId,
  required AppLocalizations l10n,
  required String displayCurrency,
}) {
  const palette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF3949AB),
    Color(0xFF039BE5),
    Color(0xFF00838F),
    Color(0xFF5E35B1),
    Color(0xFF0277BD),
    Color(0xFF00695C),
  ];

  var colorIdx = 0;
  Color nextColor() => palette[colorIdx++ % palette.length];

  final sorted = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final knownGroupIds = groups.map((g) => g.id).toSet();
  final out = <InviteSunburstSlice>[];

  for (final g in groups) {
    final members = sorted.where((l) => l.groupId == g.id).toList();
    if (members.isEmpty) continue;
    final basis = members.fold<int>(0, (a, l) => a + PlanProjection.unitMinor(l));
    if (basis <= 0) continue;
    final wg = _weightGroup(ratios, g.id, participantId);
    final userPart = (basis * wg / 10000).round();
    out.add(
      InviteSunburstSlice(
        label: g.title.trim().isEmpty ? l10n.housingPlanCategoryNone : g.title,
        totalMinor: basis,
        userMinor: userPart,
        baseColor: nextColor(),
        currency: displayCurrency,
      ),
    );
  }

  final unc = sorted.where((l) {
    final gid = l.groupId;
    return gid == null || !knownGroupIds.contains(gid);
  }).toList();
  for (final line in unc) {
    final b = PlanProjection.unitMinor(line);
    if (b <= 0) continue;
    final w = _weightLine(ratios, line.id, participantId);
    final userPart = (b * w / 10000).round();
    out.add(
      InviteSunburstSlice(
        label: line.title.trim().isEmpty ? l10n.housingPlanSplitNoCategory : line.title,
        totalMinor: b,
        userMinor: userPart,
        baseColor: nextColor(),
        currency: displayCurrency,
      ),
    );
  }

  return out;
}

void _addAnnulusSector(Path path, Offset c, double rInner, double rOuter, double start, double sweep) {
  const steps = 28;
  if (sweep <= 0 || rOuter <= rInner) return;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = start + sweep * t;
    final p = Offset(c.dx + rOuter * math.cos(a), c.dy + rOuter * math.sin(a));
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  for (var i = steps; i >= 0; i--) {
    final t = i / steps;
    final a = start + sweep * t;
    path.lineTo(c.dx + rInner * math.cos(a), c.dy + rInner * math.sin(a));
  }
  path.close();
}

class _InviteSunburstPainter extends CustomPainter {
  _InviteSunburstPainter({
    required this.slices,
    required this.grandTotalMinor,
    required this.holeColor,
  });

  final List<InviteSunburstSlice> slices;
  final int grandTotalMinor;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (grandTotalMinor <= 0 || slices.isEmpty) return;

    final c = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height);
    final rMax = minSide * 0.48;
    final ringThickness = minSide * 0.075;
    final ringGap = minSide * 0.035;
    final rOuter1 = rMax;
    final rOuter0 = rOuter1 - ringThickness;
    final rInner1 = rOuter0 - ringGap;
    final rInner0 = rInner1 - ringThickness;
    final rHole = (rInner0 - minSide * 0.02).clamp(0.0, rInner0);

    var angle = -math.pi / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.85);

    for (final s in slices) {
      final sweep = 2 * math.pi * (s.totalMinor / grandTotalMinor);
      if (sweep <= 0) continue;

      final innerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = s.baseColor;

      final innerPath = Path();
      _addAnnulusSector(innerPath, c, rInner0, rInner1, angle, sweep);
      canvas.drawPath(innerPath, innerPaint);
      canvas.drawPath(innerPath, stroke);

      final uf = s.userFraction;
      if (uf <= 0) {
        final othersPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Color.lerp(s.baseColor, Colors.white, 0.72)!;
        final p = Path();
        _addAnnulusSector(p, c, rOuter0, rOuter1, angle, sweep);
        canvas.drawPath(p, othersPaint);
        canvas.drawPath(p, stroke);
      } else if (uf >= 1) {
        final userPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = s.baseColor;
        final p = Path();
        _addAnnulusSector(p, c, rOuter0, rOuter1, angle, sweep);
        canvas.drawPath(p, userPaint);
        canvas.drawPath(p, stroke);
      } else {
        final sweepUser = sweep * uf;
        final sweepOthers = sweep - sweepUser;

        final userPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = s.baseColor;
        final pUser = Path();
        _addAnnulusSector(pUser, c, rOuter0, rOuter1, angle, sweepUser);
        canvas.drawPath(pUser, userPaint);
        canvas.drawPath(pUser, stroke);

        final othersPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Color.lerp(s.baseColor, Colors.white, 0.72)!;
        final pO = Path();
        _addAnnulusSector(pO, c, rOuter0, rOuter1, angle + sweepUser, sweepOthers);
        canvas.drawPath(pO, othersPaint);
        canvas.drawPath(pO, stroke);
      }

      angle += sweep;
    }

    final holePaint = Paint()..color = holeColor;
    canvas.drawCircle(c, rHole, holePaint);
  }

  @override
  bool shouldRepaint(covariant _InviteSunburstPainter oldDelegate) {
    if (oldDelegate.grandTotalMinor != grandTotalMinor ||
        oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (var i = 0; i < slices.length; i++) {
      final a = oldDelegate.slices[i];
      final b = slices[i];
      if (a.label != b.label ||
          a.totalMinor != b.totalMinor ||
          a.userMinor != b.userMinor ||
          a.baseColor != b.baseColor) {
        return true;
      }
    }
    return false;
  }
}

/// Nested ring chart: inner = category totals; outer = focused participant vs others (pale).
class HousingInviteSunburstChart extends StatelessWidget {
  const HousingInviteSunburstChart({
    super.key,
    required this.l10n,
    required this.slices,
  });

  final AppLocalizations l10n;
  final List<InviteSunburstSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grand = slices.fold<int>(0, (a, s) => a + s.totalMinor);
    final globalUserMinor = slices.fold<int>(0, (a, s) => a + s.userMinor);
    if (grand <= 0 || slices.isEmpty) {
      return Text(
        l10n.housingInviteSunburstEmptyHint,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, c) {
                  final minSide = math.min(c.maxWidth, c.maxHeight);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(minSide),
                        painter: _InviteSunburstPainter(
                          slices: slices,
                          grandTotalMinor: grand,
                          holeColor: theme.colorScheme.surface,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: minSide * 0.42),
                        child: Material(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Text(
                              l10n.housingInviteSunburstCenterParticipation(
                                ((globalUserMinor / grand) * 100).toStringAsFixed(0),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...slices.map((s) {
          final pctInner = (s.totalMinor / grand) * 100;
          final userPctOfCategory = s.userFraction * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3, right: 8),
                  decoration: BoxDecoration(
                    color: s.baseColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.housingInviteSunburstLegendAgreementShare(
                          s.label,
                          pctInner.toStringAsFixed(0),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.housingInviteSunburstLegendYouParticipation(
                          formatMinorAsMoney(context, s.userMinor, s.currency),
                          formatMinorAsMoney(context, s.totalMinor, s.currency),
                          userPctOfCategory.toStringAsFixed(0),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
