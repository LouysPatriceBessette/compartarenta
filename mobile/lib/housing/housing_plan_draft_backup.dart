import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';
import 'housing_plan_draft_backup_persist.dart';

/// Secondary persistence for housing draft plans on web (and elsewhere).
///
/// Drift's web storage (`sharedIndexedDb` without OPFS) can drop rows when the
/// dev server stops Chrome abruptly. This mirror writes each saved expense from
/// the save payload into synchronous **localStorage** on web (and
/// [SharedPreferences] elsewhere), keyed by [planId].
class HousingPlanDraftBackup {
  HousingPlanDraftBackup._();

  static const _backupVersion = 1;
  static final _rng = Random();

  static bool appliesToPlan(String planId) => planId.startsWith('housing:');

  /// Stable id for a new expense line (avoids web DateTime collisions).
  static String newLineId(DateTime createdAt) {
    final utc = createdAt.toUtc();
    return 'line:${utc.millisecondsSinceEpoch}-${_rng.nextInt(0x7fffffff)}';
  }

  /// Merges one saved line + ratios into the mirror (also seeds from Drift).
  static Future<void> recordExpenseSave({
    required AppDatabase db,
    required AppPreferences prefs,
    required PlanLine line,
    required List<PlanRatio> ratiosForLine,
  }) async {
    if (!appliesToPlan(line.planId)) return;

    final payload = _readPayload(prefs, line.planId) ?? _emptyPayload(line.planId);
    final lineMaps = await _mergeLineMaps(
      payload: payload,
      db: db,
      planId: line.planId,
      savedLine: line,
    );
    final ratioMaps = await _mergeRatioMaps(
      payload: payload,
      db: db,
      planId: line.planId,
      lineId: line.id,
      ratiosForLine: ratiosForLine,
    );

    payload['planId'] = line.planId;
    payload['lines'] = lineMaps;
    payload['ratios'] = ratioMaps;
    payload['savedAt'] = DateTime.now().toUtc().toIso8601String();
    await _writePayload(prefs, line.planId, jsonEncode(payload));

    if (kDebugMode) {
      debugPrint(
        'housing_plan_draft_backup: mirror planId=${line.planId} now has '
        '${lineMaps.length} expense(s) (last id=${line.id}, title=${line.title})',
      );
    }
  }

  static Future<void> removeLine(
    AppPreferences prefs,
    String planId,
    String lineId,
  ) async {
    if (!appliesToPlan(planId)) return;

    final payload = _readPayload(prefs, planId);
    if (payload == null) return;

    final lines = _lineMapsFromPayload(payload)
      ..removeWhere((m) => m['id'] == lineId);
    final ratios = _ratioMapsFromPayload(payload)
      ..removeWhere((m) => m['lineId'] == lineId);

    if (lines.isEmpty) {
      await _writePayload(prefs, planId, null);
      return;
    }
    payload['lines'] = lines;
    payload['ratios'] = ratios;
    payload['savedAt'] = DateTime.now().toUtc().toIso8601String();
    await _writePayload(prefs, planId, jsonEncode(payload));
  }

  static Future<void> replaceAllLines({
    required AppPreferences prefs,
    required List<PlanLine> lines,
    required List<PlanRatio> lineRatios,
  }) async {
    if (lines.isEmpty) return;
    final planId = lines.first.planId;
    if (!appliesToPlan(planId)) return;

    final payload = _emptyPayload(planId);
    payload['lines'] = [for (final l in lines) l.toJson()];
    payload['ratios'] = [for (final r in lineRatios) r.toJson()];
    payload['savedAt'] = DateTime.now().toUtc().toIso8601String();
    await _writePayload(prefs, planId, jsonEncode(payload));
  }

  static Future<void> snapshot(
    AppDatabase db,
    AppPreferences prefs,
    String planId,
  ) async {
    if (!appliesToPlan(planId)) return;

    final dbLines = await db.listPlanLines(planId);
    final backupLines = _linesFromPayload(_readPayload(prefs, planId));
    final merged = _mergeLines(backupLines, dbLines);

    if (merged.isEmpty) {
      await _writePayload(prefs, planId, null);
      return;
    }

    final dbRatios = (await db.listPlanRatios(planId))
        .where((r) => r.lineId != null)
        .toList();
    final backupRatios = _ratiosFromPayload(_readPayload(prefs, planId));
    final mergedIds = merged.map((l) => l.id).toSet();
    final ratios = <PlanRatio>[
      for (final r in backupRatios)
        if (mergedIds.contains(r.lineId)) r,
    ];
    final ratioKeys = ratios.map((r) => r.id).toSet();
    for (final r in dbRatios) {
      if (mergedIds.contains(r.lineId) && !ratioKeys.contains(r.id)) {
        ratios.add(r);
      }
    }

    await replaceAllLines(prefs: prefs, lines: merged, lineRatios: ratios);
    await db.syncWebStorageToDisk();
  }

  static Future<bool> restoreIfNeeded(
    AppDatabase db,
    AppPreferences prefs,
    String planId,
  ) async {
    if (!appliesToPlan(planId)) return false;

    final backupLines = _linesFromPayload(_readPayload(prefs, planId));
    final dbLines = await db.listPlanLines(planId);

    if (kDebugMode) {
      debugPrint(
        'housing_plan_draft_backup: on load planId=$planId '
        'drift=${dbLines.length} mirror=${backupLines.length}',
      );
    }

    if (backupLines.isEmpty) return false;
    if (!_shouldRestore(dbLines, backupLines)) return false;

    final backupRatios = _ratiosFromPayload(_readPayload(prefs, planId));
    final mergedIds = backupLines.map((l) => l.id).toSet();
    final ratios = backupRatios
        .where((r) => r.lineId != null && mergedIds.contains(r.lineId))
        .toList();

    await db.transaction(() async {
      await (db.delete(db.planRatios)
            ..where((t) => t.planId.equals(planId))
            ..where((t) => t.lineId.isNotNull()))
          .go();
      await (db.delete(db.planLines)..where((t) => t.planId.equals(planId)))
          .go();
      for (final line in backupLines) {
        await db.upsertPlanLine(
          PlanLinesCompanion.insert(
            id: line.id,
            planId: line.planId,
            isRecurring: line.isRecurring,
            title: line.title,
            currency: line.currency,
            amountUsesRange: drift.Value(line.amountUsesRange),
            amountMinor: drift.Value(line.amountMinor),
            minAmountMinor: drift.Value(line.minAmountMinor),
            maxAmountMinor: drift.Value(line.maxAmountMinor),
            description: drift.Value(line.description),
            cadence: drift.Value(line.cadence),
            recurrenceDayOfMonth: drift.Value(line.recurrenceDayOfMonth),
            sortOrder: drift.Value(line.sortOrder),
            groupId: drift.Value(line.groupId),
            amountIsBudgetCap: drift.Value(line.amountIsBudgetCap),
            paymentResponsibleParticipantId: drift.Value(
              line.paymentResponsibleParticipantId,
            ),
            recurrenceSpecJson: drift.Value(line.recurrenceSpecJson),
            ratioTemplateId: drift.Value(line.ratioTemplateId),
            createdAt: line.createdAt,
          ),
        );
      }
      for (final ratio in ratios) {
        await db.upsertPlanRatio(
          PlanRatiosCompanion.insert(
            id: ratio.id,
            planId: ratio.planId,
            participantId: ratio.participantId,
            lineId: drift.Value(ratio.lineId),
            groupId: drift.Value(ratio.groupId),
            weight: ratio.weight,
            createdAt: ratio.createdAt,
          ),
        );
      }
    });

    if (kDebugMode) {
      debugPrint(
        'housing_plan_draft_backup: restored ${backupLines.length} expense(s) '
        'for $planId (had ${dbLines.length} in Drift)',
      );
    }
    await db.syncWebStorageToDisk();
    return true;
  }

  static Future<List<Map<String, dynamic>>> _mergeLineMaps({
    required Map<String, dynamic> payload,
    required AppDatabase db,
    required String planId,
    required PlanLine savedLine,
  }) async {
    final byId = <String, Map<String, dynamic>>{};
    for (final m in _lineMapsFromPayload(payload)) {
      final id = m['id'] as String?;
      if (id != null) byId[id] = m;
    }
    for (final l in await db.listPlanLines(planId)) {
      byId.putIfAbsent(l.id, () => l.toJson());
    }
    byId[savedLine.id] = savedLine.toJson();
    final sorted = byId.values.toList()
      ..sort((a, b) {
        final ao = (a['sortOrder'] as num?)?.toInt() ?? 0;
        final bo = (b['sortOrder'] as num?)?.toInt() ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        final at = a['createdAt'] as String? ?? '';
        final bt = b['createdAt'] as String? ?? '';
        return at.compareTo(bt);
      });
    return sorted;
  }

  static Future<List<Map<String, dynamic>>> _mergeRatioMaps({
    required Map<String, dynamic> payload,
    required AppDatabase db,
    required String planId,
    required String lineId,
    required List<PlanRatio> ratiosForLine,
  }) async {
    final byId = <String, Map<String, dynamic>>{};
    for (final m in _ratioMapsFromPayload(payload)) {
      if (m['lineId'] == lineId) continue;
      final id = m['id'] as String?;
      if (id != null) byId[id] = m;
    }
    for (final r in await db.listPlanRatios(planId)) {
      if (r.lineId == lineId) continue;
      byId.putIfAbsent(r.id, () => r.toJson());
    }
    for (final r in ratiosForLine) {
      byId[r.id] = r.toJson();
    }
    return byId.values.toList();
  }

  static bool _shouldRestore(List<PlanLine> dbLines, List<PlanLine> backupLines) {
    if (backupLines.length > dbLines.length) return true;
    final dbIds = dbLines.map((l) => l.id).toSet();
    final backupIds = backupLines.map((l) => l.id).toSet();
    if (!backupIds.every(dbIds.contains)) return true;
    return false;
  }

  static List<PlanLine> _mergeLines(List<PlanLine> backup, List<PlanLine> db) {
    final byId = <String, PlanLine>{for (final l in backup) l.id: l};
    for (final l in db) {
      byId[l.id] = l;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        if (o != 0) return o;
        return a.createdAt.compareTo(b.createdAt);
      });
    return merged;
  }

  static Map<String, Object?> _emptyPayload(String planId) => {
    'version': _backupVersion,
    'planId': planId,
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'lines': <Map<String, dynamic>>[],
    'ratios': <Map<String, dynamic>>[],
  };

  static Future<void> _writePayload(
    AppPreferences prefs,
    String planId,
    String? json,
  ) =>
      HousingPlanDraftBackupPersist.write(planId, json, prefs);

  static Map<String, dynamic>? _readPayload(
    AppPreferences prefs,
    String planId,
  ) {
    final raw = HousingPlanDraftBackupPersist.read(planId, prefs);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    if ((decoded['version'] as num?)?.toInt() != _backupVersion) return null;
    final storedPlanId = decoded['planId'] as String?;
    if (storedPlanId != null && storedPlanId != planId) return null;
    if (storedPlanId == null) {
      decoded['planId'] = planId;
    }
    return decoded;
  }

  static List<Map<String, dynamic>> _lineMapsFromPayload(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['lines'];
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static List<Map<String, dynamic>> _ratioMapsFromPayload(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['ratios'];
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static List<PlanLine> _linesFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return [];
    return [
      for (final m in _lineMapsFromPayload(payload)) PlanLine.fromJson(m),
    ];
  }

  static List<PlanRatio> _ratiosFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return [];
    return [
      for (final m in _ratioMapsFromPayload(payload)) PlanRatio.fromJson(m),
    ];
  }

  static Future<void> clear(AppPreferences prefs, String planId) async {
    if (!appliesToPlan(planId)) return;
    await _writePayload(prefs, planId, null);
  }
}
