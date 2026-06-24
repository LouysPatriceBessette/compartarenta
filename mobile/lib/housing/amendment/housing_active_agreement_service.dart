import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';

/// In-force agreement helpers (period gate, period checks).
class HousingActiveAgreementService {
  HousingActiveAgreementService(this._db);

  final AppDatabase _db;

  /// Calendar-day semantics: agreement is open through [periodEnd] inclusive.
  bool isAgreementPeriodOpen(Agreement agreement, {DateTime? now}) {
    final today = DateUtils.dateOnly((now ?? DateTime.now()).toLocal());
    final end = DateUtils.dateOnly(agreement.periodEnd.toLocal());
    return !today.isAfter(end);
  }

  Future<bool> isPlanAgreementPeriodOpen(String planId) async {
    final agr = await _db.getAgreementForPlan(planId);
    if (agr == null) return false;
    return isAgreementPeriodOpen(agr);
  }

  Future<Agreement?> agreementForPlan(String planId) =>
      _db.getAgreementForPlan(planId);
}
