import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../housing/proposals/plan_agreement_proposal_service.dart';
import '../housing/realized_expense/realized_expense_ledger_service.dart';
import '../housing/realized_expense/realized_expense_status.dart';
import '../housing/settlement/housing_settlement_window.dart';
import 'web_dev_db_snapshot.dart';

/// File name under the app documents directory, written by [tool/seed_qa_scenario.sh].
const kQaAndroidSeedMarkerFileName = 'compartarenta_qa_seed';

/// Fixed plan id for the settlement-window-open POC scenario.
const kQaSettlementOpenPlanId = 'housing:qa-settlement-open';

/// Scenario ids supported by [applyQaScenario].
const kQaScenarioIds = <String>{
  'settlement_window_open',
};

/// Reads the adb-pushed marker on Android debug builds, seeds Drift + prefs, then
/// deletes the marker. Returns the scenario id when seeding ran.
Future<String?> maybeApplyQaAndroidSeed(AppDatabase db) async {
  if (!kDebugMode || kIsWeb || !Platform.isAndroid) return null;

  final marker = await _qaSeedMarkerFile();
  if (marker == null || !await marker.exists()) return null;

  final scenarioId = (await marker.readAsString()).trim();
  try {
    await marker.delete();
  } catch (e) {
    debugPrint('qa seed: could not delete marker file: $e');
  }
  if (scenarioId.isEmpty || !kQaScenarioIds.contains(scenarioId)) {
    debugPrint('qa seed: unknown scenario id "$scenarioId"');
    return null;
  }

  await clearDevOperationalTables(db);
  await applyQaScenario(db, scenarioId);
  await applyQaSharedPreferences(scenarioId);
  await db.syncWebStorageToDisk();
  debugPrint('qa seed: applied scenario $scenarioId');
  return scenarioId;
}

Future<File?> _qaSeedMarkerFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$kQaAndroidSeedMarkerFileName');
  } catch (e) {
    debugPrint('qa seed: could not resolve documents directory: $e');
    return null;
  }
}

Future<void> applyQaSharedPreferences(String scenarioId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding.complete', true);
  await prefs.setString('profile.displayName', 'Monica QA');
  await prefs.setString('profile.avatarId', 'mdi:0');
  await prefs.setString('prefs.currency', 'CAD');
  await prefs.setString('prefs.dateFormat', 'yyyy-MM-dd');
  await prefs.setString('prefs.distanceUnit', 'km');
  await prefs.setStringList('plans.enabled', const ['housing']);
  await prefs.setBool('notifications.enabled', false);
  await prefs.setBool('housing.defaultPlanSummaryReached', true);

  switch (scenarioId) {
    case 'settlement_window_open':
      await prefs.setString('prefs.languageCode', 'fr');
      break;
  }
}

Future<void> applyQaScenario(AppDatabase db, String scenarioId) async {
  switch (scenarioId) {
    case 'settlement_window_open':
      await _seedSettlementWindowOpen(db);
      break;
    case _:
      throw ArgumentError('Unknown QA scenario: $scenarioId');
  }
}

Future<void> _seedSettlementWindowOpen(AppDatabase db) async {
  const planId = kQaSettlementOpenPlanId;
  const packageId = 'pkg:qa-settlement-open';
  const revisionId = 'rev:qa-settlement-open:active';
  const lineId = 'line:qa-settlement-open:rent';
  const selfId = '$planId:self';
  const coId = '$planId:p0';
  final periodStart = DateTime.utc(2027, 1, 1, 12);
  final periodEnd = DateTime.utc(2027, 8, 10, 12);
  final createdAt = DateTime.utc(2027, 1, 1);

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: createdAt,
      title: const drift.Value('Entente QA règlement'),
      currency: const drift.Value('CAD'),
      notes: const drift.Value.absent(),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: selfId,
      displayName: 'Monica QA',
      avatarId: 'mdi:0',
      createdAt: createdAt,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: coId,
      displayName: 'Louys QA',
      avatarId: 'mdi:1',
      createdAt: createdAt,
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      minNoticeDays: const drift.Value(30),
      penaltyMinor: const drift.Value(0),
      clauses: const drift.Value(''),
      withdrawalSameForAll: const drift.Value('true'),
      withdrawalPerParticipantJson: const drift.Value('{}'),
      agreementRulesJson: const drift.Value('{}'),
      version: const drift.Value(1),
      createdAt: createdAt,
    ),
  );
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: lineId,
      planId: planId,
      isRecurring: true,
      title: 'Loyer',
      currency: 'CAD',
      amountMinor: const drift.Value(100000),
      recurrenceDayOfMonth: const drift.Value(1),
      sortOrder: const drift.Value(0),
      createdAt: createdAt,
    ),
  );
  for (final pid in [selfId, coId]) {
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$lineId:$pid',
        planId: planId,
        lineId: drift.Value(lineId),
        participantId: pid,
        weight: 5000,
        createdAt: createdAt,
      ),
    );
  }

  final payload = <String, Object?>{
    'kind': PlanAgreementProposalService.kind,
    'lifecycleState': 'archived',
    'agreement': {
      'periodStart': periodStart.toUtc().toIso8601String(),
      'periodEnd': periodEnd.toUtc().toIso8601String(),
    },
  };
  await db.into(db.proposalPackages).insertOnConflictUpdate(
    ProposalPackagesCompanion.insert(
      id: packageId,
      planId: planId,
      createdAt: createdAt,
      activeRevisionId: drift.Value(revisionId),
      pendingRevisionId: const drift.Value.absent(),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: revisionId,
      packageId: packageId,
      contentHash: 'qa:$revisionId',
      proposerParticipantId: selfId,
      payloadJson: jsonEncode(payload),
      createdAt: createdAt,
    ),
  );

  final expenseAt = DateTime.utc(2027, 7, 1);
  await db.into(db.realizedExpenses).insert(
    RealizedExpensesCompanion.insert(
      id: 'expense:qa-settlement-open:1',
      packageId: packageId,
      planId: planId,
      planLineId: lineId,
      amountMinor: 20000,
      currency: 'CAD',
      paymentDate: expenseAt,
      payerParticipantId: selfId,
      kind: RealizedExpenseKind.normal,
      status: RealizedExpenseStatus.published,
      createdAt: expenseAt,
      updatedAt: expenseAt,
    ),
  );
}

/// Validates that [scenarioId] produces the expected hub state for [now].
Future<void> assertQaScenarioPostconditions({
  required AppDatabase db,
  required String scenarioId,
  required DateTime now,
}) async {
  switch (scenarioId) {
    case 'settlement_window_open':
      final agreement = await db.getAgreementForPlan(kQaSettlementOpenPlanId);
      if (agreement == null) {
        throw StateError('missing agreement for $kQaSettlementOpenPlanId');
      }
      final ledger = RealizedExpenseLedgerService(db);
      final hasNonZero = await ledger.hasNonZeroOptimizedBalances(
        kQaSettlementOpenPlanId,
      );
      if (!isSettlementOpen(
        agreement: agreement,
        hasNonZeroOptimizedBalances: hasNonZero,
        now: now,
      )) {
        throw StateError(
          'settlement_window_open: expected settlement open at $now',
        );
      }
      break;
    case _:
      throw ArgumentError('Unknown QA scenario: $scenarioId');
  }
}
