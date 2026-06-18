import 'package:compartarenta/entitlement/plan_participant_installation_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanParticipantInstallationRegistry', () {
    test('rosterInstallationIds returns ordered ids when complete', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final registry = PlanParticipantInstallationRegistry(prefs);

      await registry.setInstallationId(
        planId: 'plan-1',
        participantId: 'plan-1:self',
        installationId: 'inst-self',
      );
      await registry.setInstallationId(
        planId: 'plan-1',
        participantId: 'plan-1:p1',
        installationId: 'inst-peer',
      );

      expect(
        registry.rosterInstallationIds(
          planId: 'plan-1',
          participantIds: ['plan-1:self', 'plan-1:p1'],
        ),
        ['inst-self', 'inst-peer'],
      );
      expect(
        registry.rosterInstallationIds(
          planId: 'plan-1',
          participantIds: ['plan-1:self', 'plan-1:p2'],
        ),
        isNull,
      );
    });
  });
}
