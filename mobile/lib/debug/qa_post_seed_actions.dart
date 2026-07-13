import 'package:flutter/foundation.dart';

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
  const lineTitle = 'Loyer';
  await PushNotificationService.showLocalHousingPaymentReminderNotification(
    lineTitle: lineTitle,
    reminderKind: 'before_due',
    planId: planId,
  );
  debugPrint(
    'housingPaymentReminder: simulated kind=before_due qa=#10 '
    'line=$lineTitle planId=$planId',
  );
}
