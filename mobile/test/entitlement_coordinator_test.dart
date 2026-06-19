import 'package:compartarenta/config/app_config.dart';
import 'package:compartarenta/entitlement/entitlement_coordinator.dart';
import 'package:compartarenta/entitlement/participant_installation_store.dart';
import 'package:compartarenta/entitlement/plan_participant_installation_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolvePlanParticipantId', () {
    test('maps import tails to full participant ids', () {
      const planId = 'received:pkg-housing-default';
      expect(resolvePlanParticipantId(planId, 'self'),
          '$planId:self');
      expect(resolvePlanParticipantId(planId, 'p0'), '$planId:p0');
      expect(
        resolvePlanParticipantId(planId, '$planId:p1'),
        '$planId:p1',
      );
      expect(
        resolvePlanParticipantId(planId, 'housing:default:p0'),
        'housing:default:p0',
      );
    });
  });

  group('EntitlementCoordinator', () {
    late PlanParticipantInstallationRegistry registry;
    late EntitlementCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      registry = PlanParticipantInstallationRegistry(prefs);
      coordinator = EntitlementCoordinator(
        config: AppConfig(
          environment: AppEnvironment.dev,
          apiBaseUrl: Uri.parse('https://sync.incoherences.org'),
        ),
        installationStore: _FakeInstallationStore('inst-author'),
        registry: registry,
      );
    });

    test('ingestSnapshotsFromPayload stores full participant ids for roster', () async {
      const planId = 'received:pkg-housing-default';
      await coordinator.ingestSnapshotsFromPayload(
        planId: planId,
        payload: {
          'participantSnapshots': [
            {
              'id': 'housing:default:self',
              'participantInstallationId': 'inst-monica',
            },
            {
              'id': 'housing:default:p0',
              'participantInstallationId': 'inst-roberr',
            },
            {
              'id': 'housing:default:p1',
              'participantInstallationId': 'inst-louys',
            },
          ],
        },
        sourceToLocalParticipant: {
          'housing:default:p1': 'self',
          'housing:default:self': 'p0',
          'housing:default:p0': 'p1',
        },
      );

      expect(
        registry.rosterInstallationIds(
          planId: planId,
          participantIds: [
            '$planId:self',
            '$planId:p0',
            '$planId:p1',
          ],
        ),
        ['inst-louys', 'inst-monica', 'inst-roberr'],
      );
    });

    test('installationIdForSnapshot binds only self participant', () async {
      const planId = 'housing:default';
      final selfId = await coordinator.installationIdForSnapshot(
        planId: planId,
        participantId: '$planId:self',
      );
      expect(selfId, 'inst-author');

      final peerId = await coordinator.installationIdForSnapshot(
        planId: planId,
        participantId: '$planId:p0',
      );
      expect(peerId, isEmpty);

      await registry.setInstallationId(
        planId: planId,
        participantId: '$planId:p0',
        installationId: 'inst-peer-known',
      );
      expect(
        await coordinator.installationIdForSnapshot(
          planId: planId,
          participantId: '$planId:p0',
        ),
        'inst-peer-known',
      );
    });
  });
}

class _FakeInstallationStore implements ParticipantInstallationStore {
  _FakeInstallationStore(this.id);

  final String id;

  @override
  Future<String> loadOrCreateId() async => id;

  @override
  Future<void> deleteForTesting() async {}
}
