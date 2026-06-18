import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../entitlement/entitlement_gate.dart';
import 'routing.dart';
import 'relay_scheduling.dart';

/// Interface implemented by every relay client (HTTP-backed in
/// production, in-memory fakes in tests).
///
/// Endpoints exposed (see `relay/internal/api/api.go`):
///   * `POST /v1/handshake/establish` — register a `(self, peer)` routing
///     relationship the relay will check before accepting envelopes.
///   * `POST /v1/envelopes`           — submit an opaque ciphertext from a
///     pre-established (sender, recipient) pair.
///   * `GET  /v1/inbox/<recipient>`   — fetch up to `limit` undelivered
///     envelopes addressed to a recipient.
///   * `POST /v1/envelopes/<id>/ack`  — delete an envelope after the local
///     receiver has fully processed it.
///   * `POST /v1/disconnect`          — mark a routing relationship as
///     disconnecting (no new envelopes accepted; existing in-flight ones
///     can still be ack'd).
///   * `POST /v1/routing/push/register`   — register a device token for
///     closed-app wake delivery to a recipient routing id (requires active
///     routing for that id on the relay).
///   * `POST /v1/routing/push/unregister` — remove one registration tuple.
///
/// All identities and ciphertexts are base64url-encoded (no padding). The
/// relay rejects identities outside `[8, 64]` bytes.
abstract class RelayClient {
  Future<void> establishRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  });

  Future<EnvelopeReceipt> postEnvelope({
    required Uint8List senderIdentity,
    required Uint8List recipientIdentity,
    required Uint8List idempotencyKey,
    required Uint8List ciphertext,
    required int kind,
    required Duration ttl,
    EntitlementGate? entitlementGate,
  });

  Future<List<RelayEnvelopeView>> fetchInbox({
    required Uint8List recipient,
    int limit = 32,
  });

  Future<void> ackEnvelope({
    required String envelopeId,
    required Uint8List recipient,
  });

  Future<bool> disconnectRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  });

  /// Registers [pushToken] for wake delivery to [recipientIdentity].
  ///
  /// [provider] is `fcm` or `apns`. [country] is a two-letter ISO code or
  /// `UNDISCLOSED` (relay normalizes invalid values).
  Future<DateTime> registerRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
    required String country,
  });

  Future<void> unregisterRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
  });

  Future<void> upsertSchedulingTimezone({
    required Uint8List recipientIdentity,
    required String ianaTimezone,
  });

  Future<void> reconcileHousingPaymentSchedule({
    required Uint8List senderIdentity,
    required Uint8List planIdBytes,
    required int generation,
    required List<HousingReminderScheduleTarget> targets,
  });

  Future<void> cancelHousingPaymentSchedule({
    required Uint8List senderIdentity,
    required List<Uint8List> scopeKeyBytes,
    required String reminderKind,
    required Uint8List periodKeyBytes,
  });

  Future<List<RelayPendingReminderDelivery>> fetchPendingReminderDeliveries({
    required Uint8List recipientIdentity,
    int limit = 32,
  });

  Future<void> ackReminderDelivery({
    required Uint8List recipientIdentity,
    required Uint8List fireId,
  });

  void close();
}

/// HTTP-backed implementation used in production.
class HttpRelayClient implements RelayClient {
  HttpRelayClient({
    required this.baseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = httpClient ?? http.Client(),
        _timeout = timeout;

  final Uri baseUrl;
  final http.Client _client;
  final Duration _timeout;

  @override
  void close() => _client.close();

  /// Pre-registers a `(self_identity -> peer_identity)` routing
  /// relationship. Idempotent: re-registering the same pair returns the
  /// same 204 No Content response.
  @override
  Future<void> establishRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  }) async {
    final uri = baseUrl.resolve('/v1/handshake/establish');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'self_identity': RelayRouting.b64(selfIdentity),
            'peer_identity': RelayRouting.b64(peerIdentity),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw RelayClientError._fromResponse('handshake_establish', res);
    }
  }

  /// Submits an opaque ciphertext envelope to the relay.
  @override
  Future<EnvelopeReceipt> postEnvelope({
    required Uint8List senderIdentity,
    required Uint8List recipientIdentity,
    required Uint8List idempotencyKey,
    required Uint8List ciphertext,
    required int kind,
    required Duration ttl,
    EntitlementGate? entitlementGate,
  }) async {
    final uri = baseUrl.resolve('/v1/envelopes');
    final payload = <String, dynamic>{
      'sender_identity': RelayRouting.b64(senderIdentity),
      'recipient_identity': RelayRouting.b64(recipientIdentity),
      'idempotency_key': RelayRouting.b64(idempotencyKey),
      'ciphertext': RelayRouting.b64(ciphertext),
      'kind': kind,
      'ttl_seconds': ttl.inSeconds,
    };
    if (entitlementGate != null) {
      payload['entitlement_gate'] = entitlementGate.toJson();
    }
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw RelayClientError._fromResponse('envelopes', res);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return EnvelopeReceipt(
      envelopeId: json['envelope_id'] as String,
      ttlExpiresAt: DateTime.parse(json['ttl_expires_at'] as String),
      replay: (json['replay'] as bool?) ?? false,
    );
  }

  /// Reads up to [limit] undelivered envelopes addressed to [recipient].
  /// The relay caps `limit` at 128 and rejects values below 1.
  @override
  Future<List<RelayEnvelopeView>> fetchInbox({
    required Uint8List recipient,
    int limit = 32,
  }) async {
    final uri = baseUrl.resolve(
      '/v1/inbox/${RelayRouting.b64(recipient)}?limit=$limit',
    );
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('inbox', res);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (json['envelopes'] as List<dynamic>? ?? const []);
    return raw
        .cast<Map<String, dynamic>>()
        .map(RelayEnvelopeView.fromJson)
        .toList(growable: false);
  }

  /// Acknowledges and deletes an envelope after the local receiver has
  /// fully processed it.
  @override
  Future<void> ackEnvelope({
    required String envelopeId,
    required Uint8List recipient,
  }) async {
    final uri = baseUrl.resolve('/v1/envelopes/$envelopeId/ack');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipient_identity': RelayRouting.b64(recipient),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 204) return;
    if (res.statusCode == 404) {
      // Envelope already deleted or never existed — treat as success so
      // re-running an idempotent flow does not spuriously fail.
      return;
    }
    throw RelayClientError._fromResponse('envelopes_ack', res);
  }

  /// Marks a routing relationship as disconnecting.
  @override
  Future<bool> disconnectRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  }) async {
    final uri = baseUrl.resolve('/v1/disconnect');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'self_identity': RelayRouting.b64(selfIdentity),
            'peer_identity': RelayRouting.b64(peerIdentity),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 204) return true;
    if (res.statusCode == 404) return false;
    throw RelayClientError._fromResponse('disconnect', res);
  }

  @override
  Future<DateTime> registerRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
    required String country,
  }) async {
    final uri = baseUrl.resolve('/v1/routing/push/register');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'provider': provider,
            'push_token': pushToken,
            'recipient_identity': RelayRouting.b64(recipientIdentity),
            'country': country,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('routing_push_register', res);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return DateTime.parse(json['expires_at'] as String);
  }

  @override
  Future<void> unregisterRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
  }) async {
    final uri = baseUrl.resolve('/v1/routing/push/unregister');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'provider': provider,
            'push_token': pushToken,
            'recipient_identity': RelayRouting.b64(recipientIdentity),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 204) return;
    throw RelayClientError._fromResponse('routing_push_unregister', res);
  }

  @override
  Future<void> upsertSchedulingTimezone({
    required Uint8List recipientIdentity,
    required String ianaTimezone,
  }) async {
    final uri = baseUrl.resolve('/v1/scheduling/timezone');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipient_identity': RelayRouting.b64(recipientIdentity),
            'iana_timezone': ianaTimezone,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('scheduling_timezone', res);
    }
  }

  @override
  Future<void> reconcileHousingPaymentSchedule({
    required Uint8List senderIdentity,
    required Uint8List planIdBytes,
    required int generation,
    required List<HousingReminderScheduleTarget> targets,
  }) async {
    final uri = baseUrl.resolve('/v1/scheduling/housing/reconcile');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_identity': RelayRouting.b64(senderIdentity),
            'plan_id': RelayRouting.b64(planIdBytes),
            'generation': generation,
            'targets': targets.map((t) => t.toJson()).toList(),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('scheduling_housing_reconcile', res);
    }
  }

  @override
  Future<void> cancelHousingPaymentSchedule({
    required Uint8List senderIdentity,
    required List<Uint8List> scopeKeyBytes,
    required String reminderKind,
    required Uint8List periodKeyBytes,
  }) async {
    final uri = baseUrl.resolve('/v1/scheduling/housing/cancel');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_identity': RelayRouting.b64(senderIdentity),
            'scope_keys': scopeKeyBytes.map(RelayRouting.b64).toList(),
            'reminder_kind': reminderKind,
            'period_key': RelayRouting.b64(periodKeyBytes),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('scheduling_housing_cancel', res);
    }
  }

  @override
  Future<List<RelayPendingReminderDelivery>> fetchPendingReminderDeliveries({
    required Uint8List recipientIdentity,
    int limit = 32,
  }) async {
    final uri = baseUrl.resolve(
      '/v1/scheduling/pending-deliveries?recipient_identity=${RelayRouting.b64(recipientIdentity)}&limit=$limit',
    );
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('scheduling_pending', res);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = json['deliveries'] as List<dynamic>? ?? const [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(RelayPendingReminderDelivery.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> ackReminderDelivery({
    required Uint8List recipientIdentity,
    required Uint8List fireId,
  }) async {
    final uri = baseUrl.resolve('/v1/scheduling/ack-delivery');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipient_identity': RelayRouting.b64(recipientIdentity),
            'fire_id': RelayRouting.b64(fireId),
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw RelayClientError._fromResponse('scheduling_ack', res);
    }
  }
}

class EnvelopeReceipt {
  EnvelopeReceipt({
    required this.envelopeId,
    required this.ttlExpiresAt,
    required this.replay,
  });

  final String envelopeId;
  final DateTime ttlExpiresAt;
  final bool replay;
}

class RelayEnvelopeView {
  RelayEnvelopeView({
    required this.envelopeId,
    required this.senderIdentity,
    required this.recipientIdentity,
    required this.ciphertext,
    required this.kind,
    required this.createdAt,
    required this.ttlExpiresAt,
  });

  final String envelopeId;
  final Uint8List senderIdentity;
  final Uint8List recipientIdentity;
  final Uint8List ciphertext;
  final int kind;
  final DateTime createdAt;
  final DateTime ttlExpiresAt;

  factory RelayEnvelopeView.fromJson(Map<String, dynamic> json) {
    return RelayEnvelopeView(
      envelopeId: json['envelope_id'] as String,
      senderIdentity: RelayRouting.unb64(json['sender_identity'] as String),
      recipientIdentity:
          RelayRouting.unb64(json['recipient_identity'] as String),
      ciphertext: RelayRouting.unb64(json['ciphertext'] as String),
      kind: json['kind'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      ttlExpiresAt: DateTime.parse(json['ttl_expires_at'] as String),
    );
  }
}

class RelayClientError implements Exception {
  RelayClientError({
    required this.endpoint,
    required this.statusCode,
    required this.code,
    required this.detail,
  });

  final String endpoint;
  final int statusCode;
  final String code;
  final String detail;

  factory RelayClientError._fromResponse(String endpoint, http.Response res) {
    String code = 'http_${res.statusCode}';
    String detail = res.reasonPhrase ?? '';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      code = (body['code'] as String?) ?? code;
      detail = (body['detail'] as String?) ?? detail;
    } catch (_) {
      // Body wasn't JSON; keep the HTTP status as the code.
    }
    return RelayClientError(
      endpoint: endpoint,
      statusCode: res.statusCode,
      code: code,
      detail: detail,
    );
  }

  bool get isRateLimited => code.startsWith('rate_limited');
  bool get isNoRouting => code == 'bad_envelope' && detail == 'no_routing_relationship';

  @override
  String toString() =>
      'RelayClientError($endpoint, status=$statusCode, code=$code, detail=$detail)';
}
