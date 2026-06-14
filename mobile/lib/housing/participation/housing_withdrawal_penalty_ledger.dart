import 'dart:convert';

import 'package:flutter/material.dart' show DateUtils;

import '../../db/app_database.dart';
import '../agreement_rules_json.dart';
import '../realized_expense/realized_expense_description_display.dart';
import '../realized_expense/realized_expense_repository.dart';
import '../split_minor_by_weights.dart';
import 'housing_participation_change_service.dart';

/// Computes and records early-withdrawal penalty as system ledger entries.
class HousingWithdrawalPenaltyLedger {
  HousingWithdrawalPenaltyLedger(this._db);

  final AppDatabase _db;

  Future<bool> shouldApplyPenalty({
    required String planId,
    required String participantId,
    required DateTime departureDate,
  }) async {
    final agr = await _db.getAgreementForPlan(planId);
    if (agr == null) return false;

    final rules = AgreementRulesDraft.parseStored(
      agreementRulesJson: agr.agreementRulesJson,
      clausesFallback: agr.clauses,
    );
    if (!rules.earlyWithdrawalEnabled) return false;

    final minNotice = await _minNoticeFor(planId, participantId, agr);
    final earliest =
        DateUtils.dateOnly(
          DateTime.now(),
        ).add(Duration(days: minNotice));
    final dep = DateUtils.dateOnly(departureDate.toLocal());
    if (!dep.isBefore(earliest)) return false;

    final penaltyMinor = await _penaltyMinorFor(planId, participantId, agr);
    return penaltyMinor > 0;
  }

  Future<int> penaltyMinorFor({
    required String planId,
    required String participantId,
  }) async {
    final agr = await _db.getAgreementForPlan(planId);
    if (agr == null) return 0;
    return _penaltyMinorFor(planId, participantId, agr);
  }

  Future<void> applyPenaltyIfDue({
    required String planId,
    required String changeId,
    required String leaverParticipantId,
    required DateTime departureDate,
    required List<String> remainingParticipantIds,
  }) async {
    if (remainingParticipantIds.isEmpty) return;
    if (!await shouldApplyPenalty(
      planId: planId,
      participantId: leaverParticipantId,
      departureDate: departureDate,
    )) {
      return;
    }
    final amount = await penaltyMinorFor(
      planId: planId,
      participantId: leaverParticipantId,
    );
    if (amount <= 0) return;

    final packageId =
        await HousingParticipationChangeService(_db).packageIdForPlan(planId);
    if (packageId == null) return;

    final lines = await _db.listPlanLines(planId);
    final currency = lines.isEmpty ? '' : lines.first.currency;
    final splits = splitPenaltyMinorEquallyFloored(
      amount,
      remainingParticipantIds.length,
    );
    final repo = RealizedExpenseRepository(_db);
    final paymentDate = DateUtils.dateOnly(departureDate.toLocal()).toUtc();

    for (var i = 0; i < remainingParticipantIds.length; i++) {
      final share = splits[i];
      if (share <= 0) continue;
      final beneficiaryId = remainingParticipantIds[i];
      final expenseId = 'penalty:$changeId:$beneficiaryId';
      if (await repo.getById(expenseId) != null) continue;
      await repo.publishSystemTransfer(
        packageId: packageId,
        planId: planId,
        amountMinor: -share,
        currency: currency,
        paymentDate: paymentDate,
        payerParticipantId: leaverParticipantId,
        beneficiaryParticipantId: beneficiaryId,
        description: kEarlyWithdrawalPenaltyDescriptionKey,
        expenseId: expenseId,
      );
    }
  }

  Future<int> _minNoticeFor(
    String planId,
    String participantId,
    Agreement agr,
  ) async {
    if (agr.withdrawalSameForAll == 'true') return agr.minNoticeDays;
    try {
      final map =
          jsonDecode(agr.withdrawalPerParticipantJson) as Map<String, dynamic>;
      final entry = map[participantId];
      if (entry is Map) {
        return (entry['minNoticeDays'] as num?)?.toInt() ?? agr.minNoticeDays;
      }
    } catch (_) {}
    return agr.minNoticeDays;
  }

  Future<int> _penaltyMinorFor(
    String planId,
    String participantId,
    Agreement agr,
  ) async {
    if (agr.withdrawalSameForAll == 'true') return agr.penaltyMinor;
    try {
      final map =
          jsonDecode(agr.withdrawalPerParticipantJson) as Map<String, dynamic>;
      final entry = map[participantId];
      if (entry is Map) {
        return (entry['penaltyMinor'] as num?)?.toInt() ?? agr.penaltyMinor;
      }
    } catch (_) {}
    return agr.penaltyMinor;
  }
}
