import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../housing/amendment/housing_active_agreement_service.dart';
import '../housing/participation/housing_participation_change_kind.dart';
import '../housing/participation/housing_participation_change_service.dart';
import '../housing/participation/housing_participation_hub_gates.dart';
import '../housing/participation/housing_participation_membership_service.dart';
import '../housing/participation/housing_voluntary_withdrawal_ack.dart';
import '../housing/proposals/housing_proposal_revision_state.dart';
import '../housing/proposals/housing_proposal_transport_service.dart';
import '../housing/settlement/housing_hub_expense_entry.dart';
import '../housing/settlement/housing_settlement_window.dart';
import 'qa_scenario_seed_helpers.dart';
import 'web_dev_db_snapshot.dart';

export 'qa_scenario_seed_helpers.dart' show kQaSettlementOpenPlanId;

/// File name under the app documents directory, written by [tool/seed_qa_scenario.sh].
const kQaAndroidSeedMarkerFileName = 'compartarenta_qa_seed';

/// Scenario ids supported by [applyQaScenario].
const kQaScenarioIds = <String>{
  'period_end_day',
  'settlement_open',
  'settlement_window_open',
  'settlement_last_day',
  'settlement_closed',
  'renewal_fork_visible',
  'voluntary_withdrawal_ack_j5',
  'voluntary_withdrawal_effective',
  'proposal_response_expired',
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
  await prefs.setString('prefs.languageCode', 'fr');
}

Future<void> applyQaScenario(AppDatabase db, String scenarioId) async {
  switch (scenarioId) {
    case 'period_end_day':
      await _seedPeriodEndDay(db);
    case 'settlement_open':
    case 'settlement_window_open':
      await _seedSettlementOpen(db);
    case 'settlement_last_day':
      await _seedSettlementLastDay(db);
    case 'settlement_closed':
      await _seedSettlementClosed(db);
    case 'renewal_fork_visible':
      await _seedRenewalForkVisible(db);
    case 'voluntary_withdrawal_ack_j5':
      await _seedVoluntaryWithdrawalAckJ5(db);
    case 'voluntary_withdrawal_effective':
      await _seedVoluntaryWithdrawalEffective(db);
    case 'proposal_response_expired':
      await _seedProposalResponseExpired(db);
    case _:
      throw ArgumentError('Unknown QA scenario: $scenarioId');
  }
}

Future<void> _seedPeriodEndDay(AppDatabase db) async {
  await seedQaInForceHousingPlan(
    db: db,
    planId: qaPlanIdForScenario('period_end_day'),
    title: 'Entente QA fin de période',
  );
}

Future<void> _seedSettlementOpen(AppDatabase db) async {
  await seedQaInForceHousingPlan(
    db: db,
    planId: kQaSettlementOpenPlanId,
    title: 'Entente QA règlement',
    withPublishedExpense: true,
  );
}

Future<void> _seedSettlementLastDay(AppDatabase db) async {
  await seedQaInForceHousingPlan(
    db: db,
    planId: qaPlanIdForScenario('settlement_last_day'),
    title: 'Entente QA dernier jour règlement',
    withPublishedExpense: true,
  );
}

Future<void> _seedSettlementClosed(AppDatabase db) async {
  await seedQaInForceHousingPlan(
    db: db,
    planId: qaPlanIdForScenario('settlement_closed'),
    title: 'Entente QA règlement fermé',
    withPublishedExpense: true,
  );
}

Future<void> _seedRenewalForkVisible(AppDatabase db) async {
  await seedQaInForceHousingPlan(
    db: db,
    planId: qaPlanIdForScenario('renewal_fork_visible'),
    title: 'Entente QA renouvellement',
  );
}

Future<void> _seedVoluntaryWithdrawalAckJ5(AppDatabase db) async {
  const scenarioId = 'voluntary_withdrawal_ack_j5';
  final planId = qaPlanIdForScenario(scenarioId);
  await seedQaInForceHousingPlan(
    db: db,
    planId: planId,
    title: 'Entente QA retrait ack',
  );
  await seedQaVoluntaryWithdrawal(
    db: db,
    planId: planId,
    changeId: 'pc:qa-withdraw-ack',
    noticeAt: DateTime.utc(2027, 8, 6, 12),
    departureDate: DateTime.utc(2027, 8, 25, 12),
    monicaAcknowledged: false,
  );
}

Future<void> _seedVoluntaryWithdrawalEffective(AppDatabase db) async {
  const scenarioId = 'voluntary_withdrawal_effective';
  final planId = qaPlanIdForScenario(scenarioId);
  await seedQaInForceHousingPlan(
    db: db,
    planId: planId,
    title: 'Entente QA retrait effectif',
  );
  await seedQaVoluntaryWithdrawal(
    db: db,
    planId: planId,
    changeId: 'pc:qa-withdraw-effective',
    noticeAt: DateTime.utc(2027, 8, 1, 12),
    departureDate: DateTime.utc(2027, 8, 11, 12),
    monicaAcknowledged: true,
  );
}

Future<void> _seedProposalResponseExpired(AppDatabase db) async {
  await seedQaExpiredPendingProposal(
    db: db,
    planId: qaPlanIdForScenario('proposal_response_expired'),
    title: 'Proposition QA expirée',
    responseExpiresAt: DateTime.utc(2027, 8, 10, 12),
  );
}

/// Validates that [scenarioId] produces the expected hub state for [now].
Future<void> assertQaScenarioPostconditions({
  required AppDatabase db,
  required String scenarioId,
  required DateTime now,
}) async {
  await _assertPastHubTitleWhenPeriodClosed(db, scenarioId, now);
  switch (scenarioId) {
    case 'period_end_day':
      await _assertPeriodEndDay(db, now);
    case 'settlement_open':
    case 'settlement_window_open':
      await _assertSettlementOpen(db, now);
    case 'settlement_last_day':
      await _assertSettlementLastDay(db, now);
    case 'settlement_closed':
      await _assertSettlementClosed(db, now);
    case 'renewal_fork_visible':
      await _assertRenewalForkVisible(db, now);
    case 'voluntary_withdrawal_ack_j5':
      await _assertVoluntaryWithdrawalAckJ5(db, now);
    case 'voluntary_withdrawal_effective':
      await _assertVoluntaryWithdrawalEffective(db, now);
    case 'proposal_response_expired':
      await _assertProposalResponseExpired(db, now);
    case _:
      throw ArgumentError('Unknown QA scenario: $scenarioId');
  }
}

/// Resolves hub expense mode using [now] (for QA postconditions; mirrors [resolveHubExpenseEntry]).
HousingHubExpenseEntryMode qaExpectedHubExpenseMode({
  required AppDatabase db,
  required Agreement agreement,
  required bool hasNonZeroOptimizedBalances,
  required DateTime now,
  bool participationEnterEnabled = true,
}) {
  if (!participationEnterEnabled) {
    return HousingHubExpenseEntryMode.disabled;
  }
  if (HousingActiveAgreementService(db).isAgreementPeriodOpen(
    agreement,
    now: now,
  )) {
    return HousingHubExpenseEntryMode.enterExpense;
  }
  if (isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZeroOptimizedBalances,
    now: now,
  )) {
    return HousingHubExpenseEntryMode.settlementDue;
  }
  return HousingHubExpenseEntryMode.disabled;
}

/// Whether renewal fork should show at [now] (mirrors [hubRenewalForkAvailable]).
Future<bool> qaRenewalForkAvailableAt(
  AppDatabase db,
  String planId,
  DateTime now,
) async {
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) return false;
  if (HousingActiveAgreementService(db).isAgreementPeriodOpen(
    agreement,
    now: now,
  )) {
    return false;
  }
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  return pkg?.activeRevisionId != null;
}

Future<void> _assertPastHubTitleWhenPeriodClosed(
  AppDatabase db,
  String scenarioId,
  DateTime now,
) async {
  if (scenarioId == 'proposal_response_expired') return;
  final planId = qaPlanIdForScenario(scenarioId);
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) return;
  if (HousingActiveAgreementService(db).isAgreementPeriodOpen(
    agreement,
    now: now,
  )) {
    return;
  }
  const activeTitle = 'ACTIVE';
  const pastTitle = 'PAST';
  final parts = await HousingParticipationMembershipService(db).hubTitleParts(
    planId: planId,
    selfParticipantId: '$planId:self',
    activeHubTitleL10n: activeTitle,
    pastHubTitleL10n: pastTitle,
    formatDate: (d) => d.toIso8601String().substring(0, 10),
    now: now,
  );
  if (parts.titlePrefix != pastTitle) {
    throw StateError(
      '$scenarioId: expected past hub title when period closed, got ${parts.titlePrefix}',
    );
  }
}

Future<void> _assertPeriodEndDay(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('period_end_day');
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) {
    throw StateError('missing agreement for $planId');
  }
  final hasNonZero = await qaPlanHasNonZeroBalances(db, planId);
  if (hasNonZero) {
    throw StateError('period_end_day: expected zero balances');
  }
  if (isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  )) {
    throw StateError('period_end_day: settlement must not be open at $now');
  }
  final mode = qaExpectedHubExpenseMode(
    db: db,
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  );
  if (mode != HousingHubExpenseEntryMode.disabled) {
    throw StateError(
      'period_end_day: expected disabled expense tile, got $mode',
    );
  }
}

Future<void> _assertSettlementOpen(AppDatabase db, DateTime now) async {
  final agreement = await db.getAgreementForPlan(kQaSettlementOpenPlanId);
  if (agreement == null) {
    throw StateError('missing agreement for $kQaSettlementOpenPlanId');
  }
  final hasNonZero = await qaPlanHasNonZeroBalances(db, kQaSettlementOpenPlanId);
  if (!isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  )) {
    throw StateError('settlement_open: expected settlement open at $now');
  }
}

Future<void> _assertSettlementLastDay(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('settlement_last_day');
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) {
    throw StateError('missing agreement for $planId');
  }
  final hasNonZero = await qaPlanHasNonZeroBalances(db, planId);
  if (!isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  )) {
    throw StateError('settlement_last_day: expected settlement open at $now');
  }
  final lastDay = settlementWindowLastDayInclusive(agreement.periodEnd);
  if (now.toLocal().day != lastDay.day ||
      now.toLocal().month != lastDay.month) {
    throw StateError(
      'settlement_last_day: expected last window day $lastDay at $now',
    );
  }
}

Future<void> _assertSettlementClosed(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('settlement_closed');
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) {
    throw StateError('missing agreement for $planId');
  }
  final hasNonZero = await qaPlanHasNonZeroBalances(db, planId);
  if (isSettlementOpen(
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  )) {
    throw StateError('settlement_closed: settlement must be closed at $now');
  }
  final mode = qaExpectedHubExpenseMode(
    db: db,
    agreement: agreement,
    hasNonZeroOptimizedBalances: hasNonZero,
    now: now,
  );
  if (mode != HousingHubExpenseEntryMode.disabled) {
    throw StateError(
      'settlement_closed: expected disabled expense tile, got $mode',
    );
  }
}

Future<void> _assertRenewalForkVisible(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('renewal_fork_visible');
  if (!await qaRenewalForkAvailableAt(db, planId, now)) {
    throw StateError('renewal_fork_visible: fork tile must be available at $now');
  }
}

Future<void> _assertVoluntaryWithdrawalAckJ5(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('voluntary_withdrawal_ack_j5');
  final change = await HousingParticipationChangeService(db).pendingForPlan(
    planId,
  );
  if (change == null) {
    throw StateError('voluntary_withdrawal_ack_j5: expected pending change');
  }
  final notice = voluntaryWithdrawalNoticeDateLocal(change.createdAt);
  final lastAckDay = voluntaryWithdrawalAckLastDayInclusive(notice);
  final today = DateTime(now.year, now.month, now.day);
  if (today != lastAckDay) {
    throw StateError(
      'voluntary_withdrawal_ack_j5: expected last ack day $lastAckDay at $now',
    );
  }
  final gates = await HousingParticipationHubGates.compute(
    db: db,
    planId: planId,
    selfParticipantId: '$planId:self',
    bannerTextBuilder:
        ({
          required String initiatorName,
          required String? targetName,
          required DateTime? departureDate,
        }) => 'banner',
    ejectionCandidateSubtitle: '',
  );
  if (!gates.gates.showParticipationBanner) {
    throw StateError('voluntary_withdrawal_ack_j5: expected participation banner');
  }
}

Future<void> _assertVoluntaryWithdrawalEffective(
  AppDatabase db,
  DateTime now,
) async {
  final planId = qaPlanIdForScenario('voluntary_withdrawal_effective');
  final changeSvc = HousingParticipationChangeService(db);
  final change = await changeSvc.getById('pc:qa-withdraw-effective');
  if (change == null) {
    throw StateError('voluntary_withdrawal_effective: missing change row');
  }
  if (change.planId != planId) {
    throw StateError(
      'voluntary_withdrawal_effective: change planId mismatch ($planId)',
    );
  }
  if (change.status != HousingParticipationChangeStatus.pending.wireValue) {
    throw StateError('voluntary_withdrawal_effective: expected pending before apply');
  }
  if (!await changeSvc.allDecidersHaveAccepted(change.id)) {
    throw StateError('voluntary_withdrawal_effective: all deciders must have accepted');
  }
  final departure = change.departureDate;
  if (departure == null) {
    throw StateError('voluntary_withdrawal_effective: missing departure date');
  }
  final today = DateTime(now.year, now.month, now.day);
  final depDay = DateTime(
    departure.toLocal().year,
    departure.toLocal().month,
    departure.toLocal().day,
  );
  if (today.isBefore(depDay)) {
    throw StateError(
      'voluntary_withdrawal_effective: departure $depDay must be reached at $now',
    );
  }
}

Future<void> _assertProposalResponseExpired(AppDatabase db, DateTime now) async {
  final planId = qaPlanIdForScenario('proposal_response_expired');
  final transport = HousingProposalTransportService(db);
  if (await transport.hasActiveRevision(planId)) {
    throw StateError('proposal_response_expired: must not have active revision');
  }
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final pendingId = pkg?.pendingRevisionId;
  if (pendingId == null) {
    throw StateError('proposal_response_expired: expected pending revision');
  }
  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(pendingId)))
      .getSingleOrNull();
  if (rev == null) {
    throw StateError('proposal_response_expired: missing revision row');
  }
  final state = HousingProposalRevisionState.fromJson(rev.payloadJson);
  final expires = state.responseExpiresAtUtc;
  if (expires == null || !now.toUtc().isAfter(expires)) {
    throw StateError(
      'proposal_response_expired: responseExpiresAt $expires must be before $now',
    );
  }
}
