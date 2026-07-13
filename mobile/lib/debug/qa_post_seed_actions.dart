import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../housing/reminders/payment_period_coverage.dart';
import '../notifications/push_notification_service.dart';
import 'qa_e2e_environment.dart';
import 'qa_payment_reminder_seed.dart';

/// Runs debug-only post-seed hooks after bootstrap (no relay).
Future<void> runQaPostSeedActionsIfNeeded() async {
  if (!kDebugMode) return;
  final snapshot = await readQaE2eEnvironmentSnapshot();
  if (snapshot == null || snapshot.postSeedAction == null) return;

  switch (snapshot.postSeedAction) {
    case 'payment_reminder_simulate_before_due':
      final planId =
          snapshot.paymentReminderPlanId ?? kQaPaymentReminderPlanId;
      await _qaSimulatePaymentReminderBeforeDue(planId: planId);
    default:
      debugPrint('qa post-seed: unknown action ${snapshot.postSeedAction}');
  }
}

Future<void> _qaSimulatePaymentReminderBeforeDue({
  required String planId,
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
  final period = slidingPeriodContaining(line: line, atUtc: DateTime.now().toUtc());
  final periodDueAt = period?.dueAtUtc ?? DateTime.now().toUtc();
  await PushNotificationService.showLocalHousingPaymentReminderNotification(
    lineTitle: line.title,
    reminderKind: 'before_due',
    planId: planId,
    planLineId: line.id,
    periodDueAt: periodDueAt,
  );
  debugPrint(
    'housingPaymentReminder: simulated kind=before_due qa=#10 '
    'line=${line.title} planId=$planId',
  );
}
