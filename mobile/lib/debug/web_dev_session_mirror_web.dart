// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../db/app_database.dart';
import '../prefs/app_preferences.dart';

const _mirrorKey = 'compartarenta.dev.sessionMirror.v1';

/// Debug-only mirror of prefs + contacts into [localStorage] (synchronous writes).
///
/// Survives some Chrome restarts better than relying on OPFS flush after Ctrl+C.
/// Pair with `melos run backup:web-chrome-profile` before `refresh.sh`.
Future<void> snapshotDevSessionMirror(
  AppDatabase db,
  AppPreferences prefs,
) async {
  if (!kDebugMode) return;

  final contacts = await db.select(db.contacts).get();
  final payload = <String, dynamic>{
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'onboardingComplete': prefs.onboardingComplete,
    'contacts': [
      for (final c in contacts)
        {
          'id': c.id,
          'kind': c.kind,
          'displayName': c.displayName,
          'avatarId': c.avatarId,
          'notes': c.notes,
          'isBlocked': c.isBlocked,
          'relayRoutingId': c.relayRoutingId,
          'peerPublicMaterial': c.peerPublicMaterial,
          'localDisplayLabel': c.localDisplayLabel,
          'theirLabelForMe': c.theirLabelForMe,
          'disconnectedAt': c.disconnectedAt?.toUtc().toIso8601String(),
          'createdAt': c.createdAt.toUtc().toIso8601String(),
          'updatedAt': c.updatedAt.toUtc().toIso8601String(),
          'deletedAt': c.deletedAt?.toUtc().toIso8601String(),
        },
    ],
  };
  web.window.localStorage.setItem(_mirrorKey, jsonEncode(payload));
  debugPrint(
    'web_dev_session_mirror: saved onboardingComplete=${prefs.onboardingComplete} '
    'contacts=${contacts.length}',
  );
}

Future<void> restoreDevSessionMirrorIfNeeded(AppDatabase db) async {
  if (!kDebugMode) return;

  final raw = web.window.localStorage.getItem(_mirrorKey);
  if (raw == null || raw.isEmpty) return;

  final existing = await db.select(db.contacts).get();
  if (existing.isNotEmpty) return;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;

    final contactsJson = decoded['contacts'];
    if (contactsJson is! List<dynamic>) return;

    for (final entry in contactsJson) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'];
      if (id is! String || id.isEmpty) continue;
      await db.into(db.contacts).insertOnConflictUpdate(
        ContactsCompanion.insert(
          id: id,
          kind: entry['kind'] as String? ?? 'local-only',
          displayName: entry['displayName'] as String? ?? '—',
          avatarId: entry['avatarId'] as String? ?? '',
          notes: drift.Value(entry['notes'] as String? ?? ''),
          isBlocked: drift.Value(entry['isBlocked'] as bool? ?? false),
          relayRoutingId: drift.Value(entry['relayRoutingId'] as String?),
          peerPublicMaterial: drift.Value(entry['peerPublicMaterial'] as String?),
          localDisplayLabel: drift.Value(entry['localDisplayLabel'] as String?),
          theirLabelForMe: drift.Value(entry['theirLabelForMe'] as String?),
          disconnectedAt: drift.Value(_parseUtc(entry['disconnectedAt'] as String?)),
          createdAt: _parseUtc(entry['createdAt'] as String?) ?? DateTime.now().toUtc(),
          updatedAt: _parseUtc(entry['updatedAt'] as String?) ?? DateTime.now().toUtc(),
          deletedAt: drift.Value(_parseUtc(entry['deletedAt'] as String?)),
        ),
      );
    }

    if (decoded['onboardingComplete'] == true) {
      final prefs = await AppPreferences.load();
      if (!prefs.onboardingComplete) {
        await prefs.completeOnboarding();
      }
    }

    final restored = await db.select(db.contacts).get();
    await db.syncWebStorageToDisk();
    debugPrint(
      'web_dev_session_mirror: restored ${restored.length} contact(s) from '
      'localStorage mirror',
    );
  } catch (error, stack) {
    debugPrint('web_dev_session_mirror: restore failed: $error\n$stack');
  }
}

DateTime? _parseUtc(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso)?.toUtc();
}
