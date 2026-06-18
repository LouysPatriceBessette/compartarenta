import 'dart:convert';

import 'package:compartarenta/entitlement/entitlement_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('EntitlementClient', () {
    test('registerInstallation posts participant_installation_id', () async {
      String? capturedBody;
      final client = EntitlementClient(
        baseUrl: Uri.parse('http://127.0.0.1:8081'),
        httpClient: MockClient((request) async {
          capturedBody = request.body;
          expect(request.url.path, '/v1/installations/register');
          return http.Response('', 204);
        }),
      );
      addTearDown(client.close);

      await client.registerInstallation('inst-test-device');

      final json = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(json['participant_installation_id'], 'inst-test-device');
    });

    test('reportPlanRoster posts roster payload', () async {
      String? capturedBody;
      final client = EntitlementClient(
        baseUrl: Uri.parse('http://127.0.0.1:8081'),
        httpClient: MockClient((request) async {
          capturedBody = request.body;
          expect(request.url.path, '/v1/housing/plan-roster');
          return http.Response('', 204);
        }),
      );
      addTearDown(client.close);

      await client.reportPlanRoster(
        planId: 'plan-1',
        revisionId: 'rev-1',
        participantInstallationIds: ['a', 'b'],
      );

      final json = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(json['plan_id'], 'plan-1');
      expect(json['revision_id'], 'rev-1');
      expect(json['participant_installation_ids'], ['a', 'b']);
    });
  });
}
