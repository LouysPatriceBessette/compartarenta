import 'dart:async';
import 'dart:typed_data';

import '../relay_client.dart';

/// In-memory implementation of [RelayClient] used by orchestrator tests
/// and by the future end-to-end widget tests.
///
/// Mirrors the relay's actual semantics:
///   * `establishRouting(a, b)` creates a directional admission record
///     `(a -> b)`. `postEnvelope` rejects pairs without one.
///   * Envelopes are stored by recipient; `fetchInbox` returns the rows
///     and `ackEnvelope` removes them.
///   * `disconnectRouting(a, b)` removes the `(a -> b)` admission so any
///     subsequent post is rejected. Already-stored envelopes can still
///     be ack'd by the receiver.
///   * Optional [networkErrorOnce] / [timeoutOnce] toggles let tests
///     exercise retry paths.
class FakeRelayClient implements RelayClient {
  FakeRelayClient();

  final List<FakeRelayRoutingPair> _routings = <FakeRelayRoutingPair>[];
  final List<FakeRelayStoredEnvelope> _envelopes = <FakeRelayStoredEnvelope>[];

  int _envelopeCounter = 0;

  /// One-shot error to inject on the next call to any endpoint.
  RelayClientError? networkErrorOnce;

  /// One-shot timeout to inject on the next call to any endpoint.
  bool timeoutOnce = false;

  /// One-shot: store the envelope, then throw [TimeoutException] (simulates
  /// the relay accepting POST while the HTTP client times out).
  bool timeoutAfterPostOnce = false;

  /// Inspection helpers used by tests.
  int get envelopeCount => _envelopes.length;
  List<FakeRelayStoredEnvelope> get storedEnvelopes =>
      List.unmodifiable(_envelopes);
  List<FakeRelayRoutingPair> get routings => List.unmodifiable(_routings);

  final List<FakeRoutingPushRegistration> routingPushRegistrations =
      <FakeRoutingPushRegistration>[];

  void _maybeThrowOnce() {
    if (timeoutOnce) {
      timeoutOnce = false;
      throw TimeoutException('injected');
    }
    final err = networkErrorOnce;
    if (err != null) {
      networkErrorOnce = null;
      throw err;
    }
  }

  bool _hasRouting(Uint8List sender, Uint8List recipient) {
    for (final p in _routings) {
      if (_eq(p.self, sender) && _eq(p.peer, recipient)) return true;
    }
    return false;
  }

  @override
  Future<void> establishRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  }) async {
    _maybeThrowOnce();
    if (!_hasRouting(selfIdentity, peerIdentity)) {
      _routings.add(FakeRelayRoutingPair(selfIdentity, peerIdentity));
    }
  }

  @override
  Future<EnvelopeReceipt> postEnvelope({
    required Uint8List senderIdentity,
    required Uint8List recipientIdentity,
    required Uint8List idempotencyKey,
    required Uint8List ciphertext,
    required int kind,
    required Duration ttl,
  }) async {
    _maybeThrowOnce();
    if (!_hasRouting(senderIdentity, recipientIdentity)) {
      throw RelayClientError(
        endpoint: 'envelopes',
        statusCode: 400,
        code: 'bad_envelope',
        detail: 'no_routing_relationship',
      );
    }
    final id = 'env-${_envelopeCounter++}';
    final now = DateTime.now().toUtc();
    _envelopes.add(FakeRelayStoredEnvelope(
      envelopeId: id,
      sender: senderIdentity,
      recipient: recipientIdentity,
      ciphertext: ciphertext,
      kind: kind,
      createdAt: now,
      ttlExpiresAt: now.add(ttl),
    ));
    if (timeoutAfterPostOnce) {
      timeoutAfterPostOnce = false;
      throw TimeoutException('injected after post');
    }
    return EnvelopeReceipt(
      envelopeId: id,
      ttlExpiresAt: now.add(ttl),
      replay: false,
    );
  }

  @override
  Future<List<RelayEnvelopeView>> fetchInbox({
    required Uint8List recipient,
    int limit = 32,
  }) async {
    _maybeThrowOnce();
    final out = <RelayEnvelopeView>[];
    for (final env in _envelopes) {
      if (_eq(env.recipient, recipient)) {
        out.add(
          RelayEnvelopeView(
            envelopeId: env.envelopeId,
            senderIdentity: env.sender,
            recipientIdentity: env.recipient,
            ciphertext: env.ciphertext,
            kind: env.kind,
            createdAt: env.createdAt,
            ttlExpiresAt: env.ttlExpiresAt,
          ),
        );
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<void> ackEnvelope({
    required String envelopeId,
    required Uint8List recipient,
  }) async {
    _maybeThrowOnce();
    _envelopes.removeWhere(
      (e) => e.envelopeId == envelopeId && _eq(e.recipient, recipient),
    );
  }

  @override
  Future<bool> disconnectRouting({
    required Uint8List selfIdentity,
    required Uint8List peerIdentity,
  }) async {
    _maybeThrowOnce();
    final before = _routings.length;
    _routings.removeWhere(
      (p) => _eq(p.self, selfIdentity) && _eq(p.peer, peerIdentity),
    );
    return _routings.length != before;
  }

  @override
  Future<DateTime> registerRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
    required String country,
  }) async {
    _maybeThrowOnce();
    routingPushRegistrations.removeWhere(
      (r) =>
          r.provider == provider &&
          r.pushToken == pushToken &&
          _eq(r.recipient, recipientIdentity),
    );
    routingPushRegistrations.add(
      FakeRoutingPushRegistration(
        provider: provider,
        pushToken: pushToken,
        recipient: Uint8List.fromList(recipientIdentity),
        country: country,
      ),
    );
    return DateTime.now().toUtc().add(const Duration(days: 14));
  }

  @override
  Future<void> unregisterRoutingPush({
    required String provider,
    required String pushToken,
    required Uint8List recipientIdentity,
  }) async {
    _maybeThrowOnce();
    routingPushRegistrations.removeWhere(
      (r) =>
          r.provider == provider &&
          r.pushToken == pushToken &&
          _eq(r.recipient, recipientIdentity),
    );
  }

  @override
  void close() {}
}

class FakeRoutingPushRegistration {
  FakeRoutingPushRegistration({
    required this.provider,
    required this.pushToken,
    required this.recipient,
    required this.country,
  });

  final String provider;
  final String pushToken;
  final Uint8List recipient;
  final String country;
}

/// One directional routing tuple held by [FakeRelayClient].
class FakeRelayRoutingPair {
  FakeRelayRoutingPair(this.self, this.peer);
  final Uint8List self;
  final Uint8List peer;
}

/// One stored envelope row held by [FakeRelayClient].
class FakeRelayStoredEnvelope {
  FakeRelayStoredEnvelope({
    required this.envelopeId,
    required this.sender,
    required this.recipient,
    required this.ciphertext,
    required this.kind,
    required this.createdAt,
    required this.ttlExpiresAt,
  });
  final String envelopeId;
  final Uint8List sender;
  final Uint8List recipient;
  final Uint8List ciphertext;
  final int kind;
  final DateTime createdAt;
  final DateTime ttlExpiresAt;
}

bool _eq(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
