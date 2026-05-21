import 'dart:convert';

import '../../db/app_database.dart';

/// Plan-scoped ratio templates for the "Like" selector.
class ExpenseRatioTemplateRepository {
  ExpenseRatioTemplateRepository(this._db);

  final AppDatabase _db;

  static const int weightScale = 10000;

  Future<List<PlanRatioTemplate>> listForPlan(String planId) =>
      _db.listPlanRatioTemplates(planId);

  /// Maps participant id -> weight bps (sum must be [weightScale]).
  static Map<String, int> decodeWeights(String weightsJson) {
    final decoded = jsonDecode(weightsJson);
    if (decoded is! Map<String, dynamic>) return {};
    return {
      for (final e in decoded.entries)
        if (e.value is num) e.key: (e.value as num).toInt(),
    };
  }

  static String encodeWeights(Map<String, int> weights) =>
      jsonEncode(weights);

  static String weightsSignature(Map<String, int> weights) {
    final keys = weights.keys.toList()..sort();
    return keys.map((k) => '$k:${weights[k]}').join('|');
  }

  Future<PlanRatioTemplate?> findByWeights(
    String planId,
    Map<String, int> weights,
  ) async {
    final sig = weightsSignature(weights);
    for (final t in await listForPlan(planId)) {
      if (weightsSignature(decodeWeights(t.weightsJson)) == sig) {
        return t;
      }
    }
    return null;
  }

  /// Registers a template when [weights] are not already present. Returns id.
  Future<String> registerIfNew({
    required String planId,
    required String displayTitle,
    required Map<String, int> weights,
    required DateTime createdAt,
  }) async {
    final existing = await findByWeights(planId, weights);
    if (existing != null) return existing.id;

    final id = 'ratioTpl:${createdAt.microsecondsSinceEpoch}';
    await _db.upsertPlanRatioTemplate(
      PlanRatioTemplatesCompanion.insert(
        id: id,
        planId: planId,
        displayTitle: displayTitle.trim().isEmpty ? '—' : displayTitle.trim(),
        weightsJson: encodeWeights(weights),
        createdAt: createdAt,
      ),
    );
    return id;
  }
}
