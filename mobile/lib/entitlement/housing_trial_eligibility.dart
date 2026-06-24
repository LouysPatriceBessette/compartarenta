import 'entitlement_coordinator.dart';
import 'housing_trial_consumption_store.dart';
import 'plan_participant_installation_registry.dart';

/// Whether a housing plan roster may start a new trial at first active use.
Future<bool> housingRosterMayReceiveTrial({
  required String planId,
  required List<String> participantIds,
  HousingTrialConsumptionStore? trialStore,
  PlanParticipantInstallationRegistry? registry,
}) async {
  if (participantIds.length < 2) return true;
  final store = trialStore ?? await HousingTrialConsumptionStore.load();
  final reg = registry ?? await PlanParticipantInstallationRegistry.load();
  final rosterIds = reg.rosterInstallationIds(
    planId: planId,
    participantIds: participantIds,
  );
  if (rosterIds != null && store.anyConsumed(rosterIds)) {
    return false;
  }
  final coordinator = EntitlementCoordinator.maybeInstance;
  if (coordinator != null) {
    final selfId = participantIds.firstWhere(
      (id) => id.endsWith(':self'),
      orElse: () => participantIds.first,
    );
    final selfInstallation = await coordinator.installationIdForSnapshot(
      planId: planId,
      participantId: selfId,
    );
    if (selfInstallation.isNotEmpty && store.isConsumed(selfInstallation)) {
      return false;
    }
  }
  return true;
}
