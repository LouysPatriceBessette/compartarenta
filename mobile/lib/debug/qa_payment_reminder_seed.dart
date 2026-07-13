import '../db/app_database.dart';
import 'qa_scenario_seed_helpers.dart';

/// Stable plan id for housing payment reminder QA (Monica emulator).
const kQaPaymentReminderPlanId = 'housing:qa-payment-reminder';

const kQaPaymentReminderLineId = 'line:qa-payment-reminder:rent';

/// In-force active plan with monthly recurring [Loyer]; agreement period wraps [DateTime.now].
Future<void> seedQaPaymentReminderActivePlan(AppDatabase db) async {
  final local = DateTime.now().toLocal();
  final periodStart = DateTime.utc(local.year, local.month, 1, 12);
  final periodEnd = DateTime.utc(local.year + 1, local.month, 1, 12);

  await seedQaInForceHousingPlan(
    db: db,
    planId: kQaPaymentReminderPlanId,
    title: 'Plan QA rappel paiement',
    periodStart: periodStart,
    periodEnd: periodEnd,
  );
}
