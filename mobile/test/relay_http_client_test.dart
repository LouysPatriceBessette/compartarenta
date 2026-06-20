import 'dart:convert';
import 'dart:typed_data';

import 'package:compartarenta/relay/relay_client.dart';
import 'package:compartarenta/relay/relay_http_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final recipient = Uint8List.fromList(List<int>.filled(32, 7));

  test('HttpRelayClient succeeds after transient timeouts', () async {
    var calls = 0;
    final client = HttpRelayClient(
      baseUrl: Uri.https('relay.test', ''),
      httpClient: MockClient((_) async {
        calls++;
        if (calls < 3) {
          await Future<void>.delayed(const Duration(seconds: 5));
        }
        return http.Response(jsonEncode({'envelopes': []}), 200);
      }),
      timeout: const Duration(milliseconds: 20),
    );
    addTearDown(client.close);

    final envs = await client.fetchInbox(recipient: recipient);
    expect(envs, isEmpty);
    expect(calls, 3);
  });

  test('HttpRelayClient throws RelayUnreachableException after max attempts',
      () async {
    final client = HttpRelayClient(
      baseUrl: Uri.https('relay.test', ''),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response(jsonEncode({'envelopes': []}), 200);
      }),
      timeout: const Duration(milliseconds: 20),
    );
    addTearDown(client.close);

    expect(
      client.fetchInbox(recipient: recipient),
      throwsA(isA<RelayUnreachableException>()),
    );
  });

  test('HttpRelayClient does not retry relay application errors', () async {
    var calls = 0;
    final client = HttpRelayClient(
      baseUrl: Uri.https('relay.test', ''),
      httpClient: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({'code': 'bad_envelope', 'detail': 'no_routing_relationship'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
      timeout: const Duration(milliseconds: 20),
    );
    addTearDown(client.close);

    await expectLater(
      client.fetchInbox(recipient: recipient),
      throwsA(isA<RelayClientError>()),
    );
    expect(calls, 1);
  });

  test('RelayHttpPolicy max unreachable duration is two minutes', () {
    expect(RelayHttpPolicy.maxUnreachableDuration, const Duration(minutes: 2));
    expect(RelayHttpPolicy.pollInterval, const Duration(seconds: 31));
  });
}
