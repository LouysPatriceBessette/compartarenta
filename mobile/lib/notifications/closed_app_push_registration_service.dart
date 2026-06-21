import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import '../relay/relay_client.dart';

typedef PushTokenProvider = Future<String?> Function();

/// Keeps relay `routing_push_tokens` rows in sync with this device's FCM token
/// and the set of recipient routing ids the app polls (steady state + pending
/// handshakes).
class ClosedAppPushRegistrationService {
  ClosedAppPushRegistrationService._(
    this._relay,
    this._prefs, {
    PushTokenProvider? tokenProvider,
    SharedPreferences? prefsStore,
  })  : _tokenProvider =
            tokenProvider ?? (() => FirebaseMessaging.instance.getToken()),
        _usesDefaultFcmTokenProvider = tokenProvider == null,
        _prefsStore = prefsStore;

  final RelayClient _relay;
  final AppPreferences _prefs;
  final PushTokenProvider _tokenProvider;
  final bool _usesDefaultFcmTokenProvider;
  final SharedPreferences? _prefsStore;

  static const _kLastRefreshMs = 'routing_push.last_refresh_ms';
  static const _kMinExpiresMs = 'routing_push.min_expires_ms';
  static const _kLastToken = 'routing_push.last_token';

  static ClosedAppPushRegistrationService? _instance;

  static ClosedAppPushRegistrationService? get maybeInstance => _instance;

  static void install({
    required RelayClient relay,
    required AppPreferences prefs,
    PushTokenProvider? tokenProvider,
    SharedPreferences? prefsStore,
  }) {
    _instance = ClosedAppPushRegistrationService._(
      relay,
      prefs,
      tokenProvider: tokenProvider,
      prefsStore: prefsStore,
    );
  }

  /// Registers when [force] is true or when more than half the relay TTL has
  /// elapsed since the last successful refresh.
  Future<void> syncIfNeeded({bool force = false}) => sync(force: force);

  /// Best-effort: registers or refreshes tokens, unregisters stale recipients.
  Future<void> sync({bool force = false}) async {
    if (kIsWeb) return;

    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;

    if (!_shouldRegister) {
      await _unregisterAllTracked();
      return;
    }

    if (!force && !await _needsRefresh()) {
      return;
    }

    if (!_canFetchFcmToken()) {
      return;
    }

    String? token;
    try {
      token = await _tokenProvider();
    } catch (e, st) {
      debugPrint('ClosedAppPushRegistrationService: getToken failed: $e\n$st');
      return;
    }
    if (token == null || token.isEmpty) return;

    final previousToken = await _readLastToken();
    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != token) {
      await _unregisterAllWithToken(previousToken);
    }

    const provider = 'fcm';
    final country = _prefs.countryCodeForRoutingPushRegistration;

    List<Uint8List> recipients;
    try {
      recipients = await orch.routingWakeRecipientIdentities();
    } catch (e, st) {
      debugPrint(
        'ClosedAppPushRegistrationService: recipient list failed: $e\n$st',
      );
      if (force) {
        final store = await _prefsStoreOrLoad();
        await store.setString(_kLastToken, token);
      }
      return;
    }

    for (final old in _lastRecipients) {
      if (!recipients.any((r) => _bytesEqual(r, old))) {
        await _safeUnregister(provider: provider, token: token, recipient: old);
      }
    }

    DateTime? minExpires;
    final refreshAt = DateTime.now().toUtc();
    for (final r in recipients) {
      final expires = await _safeRegister(
        provider: provider,
        token: token,
        recipient: r,
        country: country,
      );
      if (expires != null &&
          (minExpires == null || expires.isBefore(minExpires))) {
        minExpires = expires;
      }
    }

    _lastRecipients = recipients
        .map((e) => Uint8List.fromList(e))
        .toList(growable: false);

    if (minExpires != null) {
      await _persistRefreshState(
        refreshAt: refreshAt,
        minExpires: minExpires,
        token: token,
      );
    } else if (force) {
      final store = await _prefsStoreOrLoad();
      await store.setString(_kLastToken, token);
    }
  }

  /// Called when FCM rotates the device token.
  Future<void> onTokenRefreshed(String newToken) async {
    if (kIsWeb || newToken.isEmpty) return;
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;

    final previousToken = await _readLastToken();
    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != newToken) {
      for (final r in _lastRecipients) {
        await _safeUnregister(
          provider: 'fcm',
          token: previousToken,
          recipient: r,
        );
      }
      try {
        final recipients = await orch.routingWakeRecipientIdentities();
        for (final r in recipients) {
          if (_lastRecipients.any((e) => _bytesEqual(e, r))) continue;
          await _safeUnregister(
            provider: 'fcm',
            token: previousToken,
            recipient: r,
          );
        }
      } catch (e, st) {
        debugPrint(
          'ClosedAppPushRegistrationService: token rotation unregister: $e\n$st',
        );
      }
    }
    await sync(force: true);
  }

  bool get _shouldRegister =>
      _prefs.notificationsEnabled && _prefs.hasWakeEligibleCategoryEnabled;

  List<Uint8List> _lastRecipients = const [];

  Future<bool> _needsRefresh() async {
    final store = await _prefsStoreOrLoad();
    final lastMs = store.getInt(_kLastRefreshMs);
    final expiresMs = store.getInt(_kMinExpiresMs);
    if (lastMs == null || expiresMs == null) {
      return true;
    }
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
    final expires = DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true);
    final ttl = expires.difference(last);
    if (ttl <= Duration.zero) {
      return true;
    }
    final half = Duration(microseconds: ttl.inMicroseconds ~/ 2);
    return DateTime.now().toUtc().isAfter(last.add(half));
  }

  Future<void> _persistRefreshState({
    required DateTime refreshAt,
    required DateTime minExpires,
    required String token,
  }) async {
    final store = await _prefsStoreOrLoad();
    await store.setInt(_kLastRefreshMs, refreshAt.millisecondsSinceEpoch);
    await store.setInt(_kMinExpiresMs, minExpires.millisecondsSinceEpoch);
    await store.setString(_kLastToken, token);
  }

  Future<String?> _readLastToken() async {
    final store = await _prefsStoreOrLoad();
    return store.getString(_kLastToken);
  }

  Future<SharedPreferences> _prefsStoreOrLoad() async {
    final injected = _prefsStore;
    if (injected != null) return injected;
    return SharedPreferences.getInstance();
  }

  Future<void> _unregisterAllWithToken(String token) async {
    if (_lastRecipients.isEmpty) return;
    const provider = 'fcm';
    for (final r in _lastRecipients) {
      await _safeUnregister(provider: provider, token: token, recipient: r);
    }
  }

  Future<void> _unregisterAllTracked() async {
    if (_lastRecipients.isEmpty) return;
    String? token;
    try {
      token = await _tokenProvider();
    } catch (_) {
      _lastRecipients = const [];
      return;
    }
    if (token == null || token.isEmpty) {
      token = await _readLastToken();
    }
    if (token == null || token.isEmpty) {
      _lastRecipients = const [];
      return;
    }
    await _unregisterAllWithToken(token);
    _lastRecipients = const [];
    final store = await _prefsStoreOrLoad();
    await store.remove(_kLastRefreshMs);
    await store.remove(_kMinExpiresMs);
    await store.remove(_kLastToken);
  }

  Future<DateTime?> _safeRegister({
    required String provider,
    required String token,
    required Uint8List recipient,
    required String country,
  }) async {
    try {
      return await _relay.registerRoutingPush(
        provider: provider,
        pushToken: token,
        recipientIdentity: recipient,
        country: country,
      );
    } on RelayClientError catch (e) {
      if (e.code == 'bad_envelope' && e.detail == 'no_active_routing') {
        return null;
      }
      debugPrint('ClosedAppPushRegistrationService: register failed: $e');
    } catch (e, st) {
      debugPrint('ClosedAppPushRegistrationService: register failed: $e\n$st');
    }
    return null;
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

  /// Avoids FCM calls before [PushNotificationService.initialize] or while
  /// placeholder Firebase credentials are still in the repo.
  bool _canFetchFcmToken() {
    if (!_usesDefaultFcmTokenProvider) {
      return true;
    }
    if (Firebase.apps.isEmpty) {
      return false;
    }
    if (DefaultFirebaseOptions.isPlaceholder) {
      return false;
    }
    return true;
  }
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
