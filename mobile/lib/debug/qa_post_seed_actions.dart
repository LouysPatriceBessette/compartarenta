import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import '../housing/reminders/payment_period_coverage.dart';
import '../notifications/push_notification_service.dart';
import 'qa_e2e_environment.dart';
import 'qa_payment_reminder_seed.dart';

/// One-shot marker written by adb (no `pm clear`) before a Maestro cold start.
///
/// Format (two lines):
/// ```
/// before_due|overdue
/// <periodDueAtUtcMilliseconds>
/// ```
const kQaPostActionFileName = 'compartarenta_qa_post_action';

/// Runs debug-only one-shot hooks after bootstrap (no relay).
///
/// Prefers [kQaPostActionFileName] so later scenario phases can schedule a
/// simulate without wiping local journal rows. Legacy [postSeedAction] in the
/// E2E env file is consumed once and cleared.
Future<void> runQaPostSeedActionsIfNeeded() async {
  if (!kDebugMode || kIsWeb) return;

  final fromMarker = await _consumeQaPostActionMarker();
  if (fromMarker != null) {
    await _qaSimulatePaymentReminder(
      kind: fromMarker.kind,
      planId: fromMarker.planId,
      periodDueAt: fromMarker.periodDueAt,
    );
    return;
  }

  final snapshot = await readQaE2eEnvironmentSnapshot();
  if (snapshot == null || snapshot.postSeedAction == null) return;

  final action = snapshot.postSeedAction!;
  await _clearPostSeedAction(snapshot);

  switch (action) {
    case 'payment_reminder_simulate_before_due':
      await _qaSimulatePaymentReminder(
        kind: 'before_due',
        planId: snapshot.paymentReminderPlanId ?? kQaPaymentReminderPlanId,
        periodDueAt: null,
      );
    case 'payment_reminder_simulate_overdue':
      await _qaSimulatePaymentReminder(
        kind: 'overdue',
        planId: snapshot.paymentReminderPlanId ?? kQaPaymentReminderPlanId,
        periodDueAt: null,
      );
    default:
      debugPrint('qa post-seed: unknown action $action');
  }
}

Future<void> _clearPostSeedAction(QaE2eEnvironmentSnapshot snapshot) async {
  await persistQaE2eEnvironment(
    scenarioId: snapshot.scenarioId,
    languageCode: snapshot.languageCode,
    meterPhotoOptional: snapshot.meterPhotoOptional,
    paymentReminderPlanId: snapshot.paymentReminderPlanId,
  );
}

Future<({String kind, String planId, DateTime periodDueAt})?>
    _consumeQaPostActionMarker() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$kQaPostActionFileName');
    if (!await file.exists()) return null;
    final raw = (await file.readAsString()).trim();
    try {
      await file.delete();
    } catch (e) {
      debugPrint('qa post-action: could not delete marker: $e');
    }
    final lines =
        raw.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty);
    final parts = lines.toList();
    if (parts.length < 2) {
      debugPrint('qa post-action: invalid marker body');
      return null;
    }
    final kind = parts[0];
    if (kind != 'before_due' && kind != 'overdue') {
      debugPrint('qa post-action: unknown kind $kind');
      return null;
    }
    final dueMs = int.tryParse(parts[1]);
    if (dueMs == null) {
      debugPrint('qa post-action: invalid due ms ${parts[1]}');
      return null;
    }
    final planId = parts.length >= 3 && parts[2].isNotEmpty
        ? parts[2]
        : kQaPaymentReminderPlanId;
    return (
      kind: kind,
      planId: planId,
      periodDueAt: DateTime.fromMillisecondsSinceEpoch(dueMs, isUtc: true),
    );
  } catch (e) {
    debugPrint('qa post-action: read failed: $e');
    return null;
  }
}

Future<void> _qaSimulatePaymentReminder({
  required String kind,
  required String planId,
  required DateTime? periodDueAt,
}) async {
  if (kIsWeb) return;
  final db = AppDatabase.processScope;
  final lines = await db.listPlanLines(planId);
  PlanLine? line;
  for (final l in lines) {
    if (l.id == kQaPaymentReminderLineId || l.title == 'Loyer') {
      line = l;
      break;
    }
  }
  line ??= () {
    for (final l in lines) {
      if (l.isRecurring) return l;
    }
    return null;
  }();
  if (line == null) {
    debugPrint('qa post-seed: no recurring line for payment reminder');
    return;
  }

  final due = periodDueAt ??
      () {
        // Fallback for legacy env postSeedAction without due ms.
        final period = slidingPeriodContaining(
          line: line!,
          atUtc: DateTime.now().toUtc(),
        );
        return period?.dueAtUtc ?? DateTime.now().toUtc();
      }();

  await PushNotificationService.showLocalHousingPaymentReminderNotification(
    lineTitle: line.title,
    reminderKind: kind,
    planId: planId,
    planLineId: line.id,
    periodDueAt: due,
  );
  final qaNumber = kind == 'overdue' ? 11 : 10;
  debugPrint(
    'housingPaymentReminder: simulated kind=$kind qa=#$qaNumber '
    'line=${line.title} planId=$planId due=${due.toUtc().toIso8601String()}',
  );
}
