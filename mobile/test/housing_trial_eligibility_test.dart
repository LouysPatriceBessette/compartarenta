import 'package:compartarenta/entitlement/housing_trial_consumption_store.dart';
import 'package:compartarenta/entitlement/housing_trial_eligibility.dart';
import 'package:compartarenta/entitlement/plan_participant_installation_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HousingTrialConsumptionStore', () {
    test('marks and reads consumed installation ids', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await HousingTrialConsumptionStore.load();
      await store.clearForTesting();

      expect(store.isConsumed('inst-a'), isFalse);
      await store.markConsumed('inst-a');
      expect(store.isConsumed('inst-a'), isTrue);
      expect(store.anyConsumed(['inst-b', 'inst-a']), isTrue);
    });

    test('persists plan trial eligibility flag', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await HousingTrialConsumptionStore.load();
      await store.clearForTesting();

      await store.setPlanTrialEligible('housing:plan', false);
      expect(store.planTrialEligible('housing:plan'), isFalse);
    });
  });

  group('housingRosterMayReceiveTrial', () {
    test('returns false when roster installation already consumed trial', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await HousingTrialConsumptionStore.load();
      await store.clearForTesting();
      await store.markConsumed('inst-peer');

      final registry = await PlanParticipantInstallationRegistry.load();
      const planId = 'housing:trial';
      await registry.setInstallationId(
        planId: planId,
        participantId: '$planId:self',
        installationId: 'inst-self',
      );
      await registry.setInstallationId(
        planId: planId,
        participantId: '$planId:p1',
        installationId: 'inst-peer',
      );

      final eligible = await housingRosterMayReceiveTrial(
        planId: planId,
        participantIds: ['$planId:self', '$planId:p1'],
        trialStore: store,
        registry: registry,
      );

      expect(eligible, isFalse);
    });
  });
}
