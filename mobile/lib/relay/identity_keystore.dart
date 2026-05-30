import 'dart:async';
import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the local user's long-term X25519 keypair.
///
/// The private key is generated on first use, persisted to platform-secure
/// storage (Android Keystore-backed, iOS Keychain, browser sessionStorage
/// for the web testing flavor), and re-read on every subsequent app start.
///
/// The public key is exposed in base64url form and is shared with peers
/// during the handshake (carried in `hello` / `ack` envelopes). The
/// private key never leaves this class outside the relay envelope crypto.
///
/// On the web platform `flutter_secure_storage` falls back to an
/// unencrypted JS-side store; that is acceptable for the current testing
/// flavor (PC browser + Android phone) but MUST NOT be used for a public
/// release. The privacy note in `docs/contacts-module-relay-payload.md`
/// tracks the constraint.
abstract class IdentityKeystore {
  Future<Uint8List> loadOrCreatePrivateKey();
  Future<Uint8List> publicKey();
  Future<String> publicKeyB64();
  Future<void> deleteForTesting();

  /// Debug web host session: export/import the persisted private key.
  Future<String?> exportPrivateKeyB64ForDev();
  Future<void> restorePrivateKeyB64ForDev(String b64);

  /// Default platform-backed implementation. Override in tests with
  /// [InMemoryIdentityKeystore].
  factory IdentityKeystore.secureStorage({String slot = defaultSlot}) {
    return _SecureStorageIdentityKeystore(slot: slot);
  }

  static const String defaultSlot = 'relay.identity.x25519.v1';
}

class _SecureStorageIdentityKeystore implements IdentityKeystore {
  _SecureStorageIdentityKeystore({this.slot = IdentityKeystore.defaultSlot});

  final String slot;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Uint8List? _cachedPrivate;
  Uint8List? _cachedPublic;
  final _lock = _AsyncLock();

  @override
  Future<Uint8List> loadOrCreatePrivateKey() async {
    final cached = _cachedPrivate;
    if (cached != null) return cached;
    return _lock.synchronized(() async {
      final hit = _cachedPrivate;
      if (hit != null) return hit;
      final stored = await _storage.read(key: slot);
      if (stored != null && stored.isNotEmpty) {
        try {
          final bytes = Uint8List.fromList(base64Url.decode(_pad(stored)));
          if (bytes.length == 32) {
            _cachedPrivate = bytes;
            return bytes;
          }
        } on FormatException {
          // Fall through: regenerate.
        }
      }
      final fresh = await _generateRandom32();
      await _storage.write(
        key: slot,
        value: base64Url.encode(fresh).replaceAll('=', ''),
      );
      _cachedPrivate = fresh;
      return fresh;
    });
  }

  @override
  Future<Uint8List> publicKey() async {
    final cached = _cachedPublic;
    if (cached != null) return cached;
    final priv = await loadOrCreatePrivateKey();
    final algo = Cryptography.instance.x25519();
    final pair = await algo.newKeyPairFromSeed(priv);
    final pub = await pair.extractPublicKey();
    final bytes = Uint8List.fromList(pub.bytes);
    _cachedPublic = bytes;
    return bytes;
  }

  @override
  Future<String> publicKeyB64() async {
    final bytes = await publicKey();
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<void> deleteForTesting() async {
    _cachedPrivate = null;
    _cachedPublic = null;
    await _storage.delete(key: slot);
  }

  @override
  Future<String?> exportPrivateKeyB64ForDev() async {
    if (!kDebugMode) return null;
    final priv = await loadOrCreatePrivateKey();
    return base64Url.encode(priv).replaceAll('=', '');
  }

  @override
  Future<void> restorePrivateKeyB64ForDev(String b64) async {
    if (!kDebugMode) return;
    final bytes = Uint8List.fromList(base64Url.decode(_pad(b64)));
    if (bytes.length != 32) {
      throw FormatException('identity key must be 32 bytes');
    }
    await _storage.write(
      key: slot,
      value: base64Url.encode(bytes).replaceAll('=', ''),
    );
    _cachedPrivate = bytes;
    _cachedPublic = null;
  }
}

String _pad(String b64) {
  final padding = (4 - b64.length % 4) % 4;
  return b64 + '=' * padding;
}

/// Generates 32 cryptographically secure random bytes for use as the
/// X25519 scalar. We delegate to `cryptography_plus`'s X25519 algorithm
/// to keep the random source paired with the algorithm's expectations.
Future<Uint8List> _generateRandom32() async {
  final algo = Cryptography.instance.x25519();
  final pair = await algo.newKeyPair();
  final priv = await pair.extractPrivateKeyBytes();
  return Uint8List.fromList(priv);
}

/// In-memory implementation suitable for unit tests. Seed it with a
/// deterministic 32-byte scalar to obtain reproducible derivations.
class InMemoryIdentityKeystore implements IdentityKeystore {
  InMemoryIdentityKeystore({Uint8List? seed}) : _privateKey = seed;

  Uint8List? _privateKey;
  Uint8List? _publicKey;

  @override
  Future<Uint8List> loadOrCreatePrivateKey() async {
    final cached = _privateKey;
    if (cached != null) return cached;
    final fresh = await _generateRandom32();
    _privateKey = fresh;
    return fresh;
  }

  @override
  Future<Uint8List> publicKey() async {
    final cached = _publicKey;
    if (cached != null) return cached;
    final priv = await loadOrCreatePrivateKey();
    final algo = Cryptography.instance.x25519();
    final pair = await algo.newKeyPairFromSeed(priv);
    final pub = await pair.extractPublicKey();
    final bytes = Uint8List.fromList(pub.bytes);
    _publicKey = bytes;
    return bytes;
  }

  @override
  Future<String> publicKeyB64() async {
    final bytes = await publicKey();
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<void> deleteForTesting() async {
    _privateKey = null;
    _publicKey = null;
  }

  @override
  Future<String?> exportPrivateKeyB64ForDev() async {
    if (!kDebugMode) return null;
    final priv = await loadOrCreatePrivateKey();
    return base64Url.encode(priv).replaceAll('=', '');
  }

  @override
  Future<void> restorePrivateKeyB64ForDev(String b64) async {
    if (!kDebugMode) return;
    _privateKey = Uint8List.fromList(base64Url.decode(_pad(b64)));
    _publicKey = null;
  }
}

class _AsyncLock {
  Future<void> _last = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final previous = _last;
    _last = completer.future;
    return previous.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }
}

/// Silences the unused_element warning for the debug-only kDebugMode
/// reference path that some test runners exercise.
// ignore: unused_element
void _touchKDebug() => kDebugMode.toString();
