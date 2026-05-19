import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import '../relay/relay_client.dart';

/// Keeps relay `routing_push_tokens` rows in sync with this device's FCM token
/// and the set of recipient routing ids the app polls (steady state + pending
/// handshakes).
class ClosedAppPushRegistrationService {
  ClosedAppPushRegistrationService._(this._relay, this._prefs);

  final RelayClient _relay;
  final AppPreferences _prefs;

  static ClosedAppPushRegistrationService? _instance;

  static ClosedAppPushRegistrationService? get maybeInstance => _instance;

  static void install({
    required RelayClient relay,
    required AppPreferences prefs,
  }) {
    _instance = ClosedAppPushRegistrationService._(relay, prefs);
  }

  /// Best-effort: registers or refreshes tokens, unregisters stale recipients.
  Future<void> sync() async {
    if (kIsWeb) return;

    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;

    if (!_prefs.notificationsEnabled) {
      await _unregisterAllTracked();
      return;
    }

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e, st) {
      debugPrint('ClosedAppPushRegistrationService: getToken failed: $e\n$st');
      return;
    }
    if (token == null || token.isEmpty) return;

    const provider = 'fcm';
    final country = _prefs.countryCodeForRoutingPushRegistration;

    List<Uint8List> recipients;
    try {
      recipients = await orch.routingWakeRecipientIdentities();
    } catch (e, st) {
      debugPrint(
        'ClosedAppPushRegistrationService: recipient list failed: $e\n$st',
      );
      return;
    }

    for (final old in _lastRecipients) {
      if (!recipients.any((r) => _bytesEqual(r, old))) {
        await _safeUnregister(provider: provider, token: token, recipient: old);
      }
    }

    for (final r in recipients) {
      await _safeRegister(
        provider: provider,
        token: token,
        recipient: r,
        country: country,
      );
    }

    _lastRecipients = recipients
        .map((e) => Uint8List.fromList(e))
        .toList(growable: false);
  }

  List<Uint8List> _lastRecipients = const [];

  Future<void> _unregisterAllTracked() async {
    if (_lastRecipients.isEmpty) return;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      _lastRecipients = const [];
      return;
    }
    if (token == null || token.isEmpty) {
      _lastRecipients = const [];
      return;
    }
    const provider = 'fcm';
    for (final r in _lastRecipients) {
      await _safeUnregister(provider: provider, token: token, recipient: r);
    }
    _lastRecipients = const [];
  }

  Future<void> _safeRegister({
    required String provider,
    required String token,
    required Uint8List recipient,
    required String country,
  }) async {
    try {
      await _relay.registerRoutingPush(
        provider: provider,
        pushToken: token,
        recipientIdentity: recipient,
        country: country,
      );
    } on RelayClientError catch (e) {
      if (e.code == 'bad_envelope' && e.detail == 'no_active_routing') {
        return;
      }
      debugPrint('ClosedAppPushRegistrationService: register failed: $e');
    } catch (e, st) {
      debugPrint('ClosedAppPushRegistrationService: register failed: $e\n$st');
    }
  }

  Future<void> _safeUnregister({
    required String provider,
    required String token,
    required Uint8List recipient,
  }) async {
    try {
      await _relay.unregisterRoutingPush(
        provider: provider,
        pushToken: token,
        recipientIdentity: recipient,
      );
    } on RelayClientError catch (e) {
      debugPrint('ClosedAppPushRegistrationService: unregister: $e');
    } catch (e, st) {
      debugPrint('ClosedAppPushRegistrationService: unregister: $e\n$st');
    }
  }
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
