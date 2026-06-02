import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import 'realized_expense_participants.dart';
import 'realized_expense_status.dart';

/// Per-expense plan-line context frozen for the realized-expense ledger.
///
/// Each [RealizedExpense] that uses a plan line stores:
/// - [RealizedExpense.splitRatiosJson] — basis-point weights used for dues
/// - [RealizedExpense.planLineTitleSnapshot] — label shown in expense history
///
/// Snapshots are captured at proposal (and again at publish if still missing).
/// Once an expense is **published**, these fields are never overwritten: a later
/// plan-line edit (title / budget amount) or line removal must not change how
/// past expenses split or read in the archive.
///
/// [ArchivedPlanLineSnapshots] is a fallback when the line was **removed** from
/// the live plan and legacy rows have no per-expense snapshot yet.
///
/// `lineEdit` amendments may change line fields on the plan (including recurrence
/// and ratios); new expenses capture the then-current title and ratios, while
/// older published expenses keep their own snapshots.
typedef SplitRatiosJson = String;

/// Ledger rows whose plan-line context must not track live plan tables.
bool expenseSplitContextIsFrozen(RealizedExpense expense) {
  return expense.status == RealizedExpenseStatus.published ||
      expense.status == RealizedExpenseStatus.rejected;
}

List<PlanRatio> planRatiosFromSplitJson({
  required String? splitRatiosJson,
  required String planId,
  required String lineId,
}) {
  if (splitRatiosJson == null || splitRatiosJson.trim().isEmpty) {
    return const [];
  }
  try {
    final decoded = jsonDecode(splitRatiosJson);
    if (decoded is! List) return const [];
    final out = <PlanRatio>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final participantId = raw['participantId']?.toString() ?? '';
      final weight = raw['weight'];
      if (participantId.isEmpty || weight is! num) continue;
      out.add(
        PlanRatio(
          id: 'snapshot:$planId:$lineId:$participantId',
          planId: planId,
          participantId: participantId,
          lineId: lineId,
          groupId: null,
          weight: weight.toInt(),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }
    return out;
  } catch (_) {
    return const [];
  }
}

SplitRatiosJson encodeSplitRatiosJson(List<PlanRatio> ratios) {
  return jsonEncode([
    for (final ratio in ratios)
      {
        'participantId': ratio.participantId,
        'weight': ratio.weight,
      },
  ]);
}

/// Maps a peer/source participant id to this device's roster slot (`:self`, `:p0`, …).
String? localParticipantIdFromSource({
  required String planId,
  required String sourceParticipantId,
  required Iterable<String> localParticipantIds,
  Map<String, String>? sourceToLocal,
}) {
  if (sourceParticipantId.isEmpty) return null;
  if (localParticipantIds.contains(sourceParticipantId)) {
    return sourceParticipantId;
  }
  if (sourceToLocal != null) {
    final direct = sourceToLocal[sourceParticipantId];
    if (direct != null && localParticipantIds.contains(direct)) {
      return direct;
    }
  }

  final tail = sourceParticipantId.contains(':')
      ? sourceParticipantId.split(':').last
      : sourceParticipantId;
  final byTail = '$planId:$tail';
  if (localParticipantIds.contains(byTail)) return byTail;
  if (tail == 'self' && localParticipantIds.contains('$planId:self')) {
    return '$planId:self';
  }
  for (final localId in localParticipantIds) {
    if (localId.endsWith(':$tail')) return localId;
  }
  if (sourceToLocal != null) {
    for (final entry in sourceToLocal.entries) {
      if (!localParticipantIds.contains(entry.value)) continue;
      final sourceTail = entry.key.contains(':')
          ? entry.key.split(':').last
          : entry.key;
      if (sourceTail == tail) return entry.value;
    }
  }
  return null;
}

List<PlanRatio> normalizePlanRatiosToLocalRoster({
  required String planId,
  required String lineId,
  required List<PlanRatio> ratios,
  required List<Participant> roster,
  Map<String, String>? sourceToLocal,
}) {
  final localIds = roster.map((participant) => participant.id).toList();
  final out = <PlanRatio>[];
  for (final ratio in ratios) {
    final localId = localParticipantIdFromSource(
      planId: planId,
      sourceParticipantId: ratio.participantId,
      localParticipantIds: localIds,
      sourceToLocal: sourceToLocal,
    );
    if (localId == null) continue;
    out.add(
      PlanRatio(
        id: 'snapshot:$planId:$lineId:$localId',
        planId: planId,
        participantId: localId,
        lineId: lineId,
        groupId: null,
        weight: ratio.weight,
        createdAt: ratio.createdAt,
      ),
    );
  }
  return out;
}

bool planRatiosAlignWithRoster(
  List<PlanRatio> ratios,
  List<Participant> roster,
) {
  if (ratios.isEmpty || roster.isEmpty) return false;
  final rosterIds = roster.map((participant) => participant.id).toSet();
  for (final ratio in ratios) {
    if (!rosterIds.contains(ratio.participantId)) return false;
  }
  return true;
}

String? remapSplitRatiosJsonForLocalPlan({
  required String planId,
  required String lineId,
  required String? splitRatiosJson,
  required List<Participant> roster,
  Map<String, String>? sourceToLocal,
}) {
  final parsed = planRatiosFromSplitJson(
    splitRatiosJson: splitRatiosJson,
    planId: planId,
    lineId: lineId,
  );
  if (parsed.isEmpty) return null;
  if (planRatiosAlignWithRoster(parsed, roster)) return splitRatiosJson;

  final normalized = normalizePlanRatiosToLocalRoster(
    planId: planId,
    lineId: lineId,
    ratios: parsed,
    roster: roster,
    sourceToLocal: sourceToLocal,
  );
  if (!planRatiosAlignWithRoster(normalized, roster)) return null;
  return encodeSplitRatiosJson(normalized);
}

Future<List<PlanRatio>> currentRatiosForPlanLine(
  AppDatabase db,
  String planId,
  String lineId,
) async {
  return (await db.listPlanRatios(planId))
      .where((ratio) => ratio.lineId == lineId)
      .toList(growable: false);
}

Future<String?> titleForPlanLine(
  AppDatabase db,
  String planId,
  String lineId,
) async {
  for (final line in await db.listPlanLines(planId)) {
    if (!_lineIdMatches(lineId, planId, line.id)) continue;
    final title = line.title.trim();
    if (title.isNotEmpty) return title;
  }
  return null;
}

/// Persists missing split ratios and/or line title on the expense row.
///
/// Fills each field independently. Never overwrites values already stored on
/// published (or rejected) expenses.
Future<void> captureLineSnapshotForExpense(
  AppDatabase db,
  RealizedExpense expense,
) async {
  if (!RealizedExpenseKind.usesPlanLine(expense.kind)) return;
  if (expense.planLineId.isEmpty) return;

  final frozen = expenseSplitContextIsFrozen(expense);
  final roster = await participantsForPlan(db, expense.planId);
  var hasRatios = (expense.splitRatiosJson ?? '').trim().isNotEmpty;
  if (hasRatios) {
    final parsed = planRatiosFromSplitJson(
      splitRatiosJson: expense.splitRatiosJson,
      planId: expense.planId,
      lineId: expense.planLineId,
    );
    hasRatios = planRatiosAlignWithRoster(parsed, roster);
  }
  final hasTitle = (expense.planLineTitleSnapshot ?? '').trim().isNotEmpty;
  if (frozen && hasRatios && hasTitle) return;
  if (hasRatios && hasTitle) return;

  SplitRatiosJson? splitJson;
  if (!hasRatios) {
    final ratios = await currentRatiosForPlanLine(
      db,
      expense.planId,
      expense.planLineId,
    );
    if (ratios.isNotEmpty) {
      splitJson = encodeSplitRatiosJson(ratios);
    } else {
      final archived = await db.getArchivedPlanLineSnapshot(
        planId: expense.planId,
        lineId: expense.planLineId,
      );
      if (archived != null && archived.splitRatiosJson.trim().isNotEmpty) {
        splitJson = archived.splitRatiosJson;
      } else {
        final historical = await _ratiosFromRevisionHistory(
          db,
          expense.planId,
          expense.planLineId,
        );
        if (historical.isNotEmpty) {
          splitJson = encodeSplitRatiosJson(historical);
        }
      }
    }
  }

  String? resolvedTitle;
  if (!hasTitle) {
    resolvedTitle =
        await titleForPlanLine(db, expense.planId, expense.planLineId) ??
        expense.planLineTitleSnapshot ??
        (await db.getArchivedPlanLineSnapshot(
          planId: expense.planId,
          lineId: expense.planLineId,
        ))
            ?.title
            .trim();
  }

  if (splitJson == null && (resolvedTitle == null || resolvedTitle.isEmpty)) {
    return;
  }

  await (db.update(db.realizedExpenses)..where((t) => t.id.equals(expense.id)))
      .write(
    RealizedExpensesCompanion(
      splitRatiosJson: splitJson == null
          ? const drift.Value.absent()
          : drift.Value(splitJson),
      planLineTitleSnapshot: resolvedTitle == null || resolvedTitle.isEmpty
          ? const drift.Value.absent()
          : drift.Value(resolvedTitle),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    ),
  );
}

Future<void> archivePlanLineBeforeRemoval(
  AppDatabase db, {
  required String planId,
  required PlanLine line,
}) async {
  final ratios = await currentRatiosForPlanLine(db, planId, line.id);
  if (ratios.isEmpty) return;

  final now = DateTime.now().toUtc();
  await db.upsertArchivedPlanLineSnapshot(
    ArchivedPlanLineSnapshotsCompanion.insert(
      planId: planId,
      lineId: line.id,
      title: line.title.trim().isEmpty ? line.id : line.title.trim(),
      splitRatiosJson: encodeSplitRatiosJson(ratios),
      archivedAt: now,
    ),
  );
}

Future<Map<String, List<PlanRatio>>> resolveRatiosByExpenseId({
  required AppDatabase db,
  required String planId,
  required List<RealizedExpense> expenses,
  required List<PlanRatio> currentRatios,
}) async {
  final out = <String, List<PlanRatio>>{};
  final lineCache = <String, List<PlanRatio>>{};
  final roster = await participantsForPlan(db, planId);

  Future<List<PlanRatio>> ratiosForLine(String lineId) async {
    final cached = lineCache[lineId];
    if (cached != null) return cached;

    final live = currentRatios
        .where((ratio) => ratio.lineId == lineId)
        .toList(growable: false);
    if (live.isNotEmpty) {
      final normalized = normalizePlanRatiosToLocalRoster(
        planId: planId,
        lineId: lineId,
        ratios: live,
        roster: roster,
      );
      if (normalized.isNotEmpty) {
        lineCache[lineId] = normalized;
        return normalized;
      }
    }

    final archived = await db.getArchivedPlanLineSnapshot(
      planId: planId,
      lineId: lineId,
    );
    if (archived != null) {
      final fromArchive = planRatiosFromSplitJson(
        splitRatiosJson: archived.splitRatiosJson,
        planId: planId,
        lineId: lineId,
      );
      if (fromArchive.isNotEmpty) {
        final normalized = normalizePlanRatiosToLocalRoster(
          planId: planId,
          lineId: lineId,
          ratios: fromArchive,
          roster: roster,
        );
        if (normalized.isNotEmpty) {
          lineCache[lineId] = normalized;
          return normalized;
        }
      }
    }

    final historical = await _ratiosFromRevisionHistory(db, planId, lineId);
    final normalizedHistorical = normalizePlanRatiosToLocalRoster(
      planId: planId,
      lineId: lineId,
      ratios: historical,
      roster: roster,
    );
    lineCache[lineId] = normalizedHistorical;
    return normalizedHistorical;
  }

  for (final expense in expenses) {
    if (!RealizedExpenseKind.usesPlanLine(expense.kind)) continue;
    if (expense.planLineId.isEmpty) continue;

    final fromExpense = normalizePlanRatiosToLocalRoster(
      planId: planId,
      lineId: expense.planLineId,
      ratios: planRatiosFromSplitJson(
        splitRatiosJson: expense.splitRatiosJson,
        planId: planId,
        lineId: expense.planLineId,
      ),
      roster: roster,
    );
    if (fromExpense.isNotEmpty &&
        planRatiosAlignWithRoster(fromExpense, roster)) {
      out[expense.id] = fromExpense;
      await _persistRemappedExpenseSnapshotIfNeeded(
        db,
        expense,
        fromExpense,
      );
      continue;
    }

    final resolved = await ratiosForLine(expense.planLineId);
    if (resolved.isNotEmpty) {
      out[expense.id] = resolved;
      await _persistExpenseSnapshotIfMissing(db, expense, resolved);
    }
  }

  return out;
}

Future<void> _persistRemappedExpenseSnapshotIfNeeded(
  AppDatabase db,
  RealizedExpense expense,
  List<PlanRatio> normalizedRatios,
) async {
  final roster = await participantsForPlan(db, expense.planId);
  if (!planRatiosAlignWithRoster(normalizedRatios, roster)) return;

  final remappedJson = encodeSplitRatiosJson(normalizedRatios);
  if ((expense.splitRatiosJson ?? '').trim() == remappedJson) return;

  await (db.update(db.realizedExpenses)..where((t) => t.id.equals(expense.id)))
      .write(
    RealizedExpensesCompanion(
      splitRatiosJson: drift.Value(remappedJson),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    ),
  );
}

Future<void> _persistExpenseSnapshotIfMissing(
  AppDatabase db,
  RealizedExpense expense,
  List<PlanRatio> ratios,
) async {
  if ((expense.splitRatiosJson ?? '').trim().isNotEmpty &&
      (expense.planLineTitleSnapshot ?? '').trim().isNotEmpty) {
    return;
  }

  final splitJson = (expense.splitRatiosJson ?? '').trim().isNotEmpty
      ? null
      : encodeSplitRatiosJson(ratios);

  String? title;
  if ((expense.planLineTitleSnapshot ?? '').trim().isEmpty) {
    title = await titleForPlanLine(db, expense.planId, expense.planLineId) ??
        (await db.getArchivedPlanLineSnapshot(
          planId: expense.planId,
          lineId: expense.planLineId,
        ))
            ?.title;
  }

  if (splitJson == null && (title == null || title.trim().isEmpty)) return;

  await (db.update(db.realizedExpenses)..where((t) => t.id.equals(expense.id)))
      .write(
    RealizedExpensesCompanion(
      splitRatiosJson: splitJson == null
          ? const drift.Value.absent()
          : drift.Value(splitJson),
      planLineTitleSnapshot: title == null || title.trim().isEmpty
          ? const drift.Value.absent()
          : drift.Value(title.trim()),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    ),
  );
}

Future<String?> resolvePlanLineTitleForExpense({
  required AppDatabase db,
  required RealizedExpense expense,
}) async {
  if (!RealizedExpenseKind.usesPlanLine(expense.kind)) return null;

  final snapshotTitle = expense.planLineTitleSnapshot?.trim();
  if (snapshotTitle != null && snapshotTitle.isNotEmpty) {
    return snapshotTitle;
  }

  if (expenseSplitContextIsFrozen(expense)) {
    final archived = await db.getArchivedPlanLineSnapshot(
      planId: expense.planId,
      lineId: expense.planLineId,
    );
    final archivedTitle = archived?.title.trim();
    if (archivedTitle != null && archivedTitle.isNotEmpty) {
      return archivedTitle;
    }
    return null;
  }

  final liveTitle = await titleForPlanLine(
    db,
    expense.planId,
    expense.planLineId,
  );
  if (liveTitle != null && liveTitle.isNotEmpty) return liveTitle;

  final archived = await db.getArchivedPlanLineSnapshot(
    planId: expense.planId,
    lineId: expense.planLineId,
  );
  final archivedTitle = archived?.title.trim();
  if (archivedTitle != null && archivedTitle.isNotEmpty) {
    return archivedTitle;
  }

  return null;
}

Future<List<PlanRatio>> _ratiosFromRevisionHistory(
  AppDatabase db,
  String planId,
  String lineId,
) async {
  final packages = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .get();
  if (packages.isEmpty) return const [];

  final revisions = <ProposalRevision>[];
  for (final pkg in packages) {
    revisions.addAll(
      await (db.select(db.proposalRevisions)
            ..where((t) => t.packageId.equals(pkg.id)))
          .get(),
    );
  }
  revisions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  for (final revision in revisions) {
    try {
      final payload = jsonDecode(revision.payloadJson) as Map<String, dynamic>;
      final plan = payload['plan'];
      if (plan is! Map) continue;
      final planMap = plan.cast<String, dynamic>();
      final lines = planMap['lines'];
      if (lines is! List) continue;

      var lineFound = false;
      for (final entry in lines) {
        if (entry is! Map) continue;
        if (_lineIdMatches(lineId, planId, entry['id']?.toString() ?? '')) {
          lineFound = true;
          break;
        }
      }
      if (!lineFound) continue;

      final ratios = planMap['ratios'];
      if (ratios is! List) continue;

      final out = <PlanRatio>[];
      for (final entry in ratios) {
        if (entry is! Map) continue;
        final payloadLineId = entry['lineId']?.toString() ?? '';
        if (!_lineIdMatches(lineId, planId, payloadLineId)) continue;
        final participant = entry['participantId']?.toString() ?? '';
        final weight = entry['weight'];
        if (participant.isEmpty || weight is! num) continue;
        final participantId = participant.contains(':')
            ? participant
            : '$planId:$participant';
        out.add(
          PlanRatio(
            id: 'history:$planId:$lineId:$participantId',
            planId: planId,
            participantId: participantId,
            lineId: lineId,
            groupId: null,
            weight: weight.toInt(),
            createdAt: revision.createdAt,
          ),
        );
      }
      if (out.isNotEmpty) return out;
    } catch (_) {
      continue;
    }
  }
  return const [];
}

bool _lineIdMatches(String targetLineId, String planId, String payloadLineId) {
  if (payloadLineId.isEmpty) return false;
  if (payloadLineId == targetLineId) return true;
  if (payloadLineId.endsWith(':$targetLineId')) return true;
  if (targetLineId.endsWith(':$payloadLineId')) return true;
  final resolved = payloadLineId.contains(':')
      ? payloadLineId
      : '$planId:$payloadLineId';
  return resolved == targetLineId;
}
