import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable opaque installation identity for entitlement (`participant_installation_id`).
///
/// Generated once per app install, persisted in secure storage, and exchanged
/// with co-participants via housing proposal snapshots.
abstract class ParticipantInstallationStore {
  Future<String> loadOrCreateId();

  /// FOR TESTS ONLY.
  Future<void> deleteForTesting();

  factory ParticipantInstallationStore.secureStorage({
    String slot = defaultSlot,
  }) {
    return _SecureStorageParticipantInstallationStore(slot: slot);
  }

  static const String defaultSlot = 'entitlement.participant_installation.v1';
}

class _SecureStorageParticipantInstallationStore
    implements ParticipantInstallationStore {
  _SecureStorageParticipantInstallationStore({this.slot = ParticipantInstallationStore.defaultSlot});

  final String slot;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cached;
  final _lock = _AsyncLock();

  @override
  Future<String> loadOrCreateId() async {
    final hit = _cached;
    if (hit != null) return hit;
    return _lock.synchronized(() async {
      final again = _cached;
      if (again != null) return again;
      final stored = await _storage.read(key: slot);
      if (stored != null && stored.isNotEmpty && _isValidId(stored)) {
        _cached = stored;
        return stored;
      }
      final fresh = _generateId();
      await _storage.write(key: slot, value: fresh);
      _cached = fresh;
      return fresh;
    });
  }

  @override
  Future<void> deleteForTesting() async {
    await _storage.delete(key: slot);
    _cached = null;
  }

  static bool _isValidId(String id) {
    return id.length >= 8 && id.length <= 64;
  }

  static String _generateId() {
    final bytes = Uint8List(16);
    final r = Random.secure();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = r.nextInt(256);
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

class _AsyncLock {
  Future<void>? _tail;

  Future<T> synchronized<T>(Future<T> Function() action) {
    final previous = _tail ?? Future<void>.value();
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) completer.complete();
    });
  }
}
