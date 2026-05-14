import 'package:drift/drift.dart' as drift;

import '../app_database.dart';

/// Public, on-device-only repository for Contacts.
///
/// Connected contacts and any handshake-related state mutations are deliberately
/// not handled here yet — they are introduced together with the relay
/// handshake protocol (Wave B of the contacts-module implementation).
class ContactsRepository {
  ContactsRepository(this._db);

  final AppDatabase _db;

  /// Lists contacts for the Contacts UI and pickers.
  ///
  /// Rows with ids under `contact:local:` were the legacy manual local-only
  /// path; they are hidden from the list so users add people through
  /// invitation and handshake instead, while handshake stubs and demoted
  /// contacts keep stable `contact:handshake:` ids.
  Future<List<Contact>> list({bool includeDeleted = false}) async {
    final rows = await _db.listContacts(includeDeleted: includeDeleted);
    return rows.where((c) => !c.id.startsWith('contact:local:')).toList();
  }

  Future<Contact?> get(String id) => _db.getContact(id);

  Future<void> upsertLocalOnly({
    required String id,
    required String displayName,
    required String avatarId,
    String notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return _db.upsertContact(
      ContactsCompanion.insert(
        id: id,
        kind: 'local-only',
        displayName: displayName,
        avatarId: avatarId,
        notes: drift.Value(notes),
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      ),
    );
  }

  Future<void> rename({
    required String id,
    required String displayName,
    required String avatarId,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        displayName: drift.Value(displayName),
        avatarId: drift.Value(avatarId),
        notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Returns the module plans currently referencing this contact as a
  /// participant. Used by the UI to block deletion of a contact that still
  /// anchors a plan; per `contact-privacy-and-deletion`, the user must
  /// remove the contact from each plan first.
  Future<List<Plan>> plansReferencing(String id) =>
      _db.listPlansContainingContact(id);

  /// Marks the contact as deleted locally. Module participant rows keep their
  /// historical snapshot via `Participants.displayName` / `avatarId`.
  Future<void> deleteLocally(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        deletedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Toggles the local block flag. Block enforcement is local-only: the
  /// relay is never informed of a block per the contact-privacy spec.
  Future<void> setBlocked({required String id, required bool blocked}) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        isBlocked: drift.Value(blocked),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Promotes a `local-only` Contact to `connected` after a successful
  /// handshake. Writes the relay routing identifier and the peer's
  /// long-term X25519 public key material (both base64url-encoded). The
  /// stable on-device `id` is preserved per `contacts-domain-model`.
  Future<void> promoteToConnected({
    required String id,
    required String relayRoutingIdB64,
    required String peerPublicMaterialB64,
    String? displayName,
    String? avatarId,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        kind: const drift.Value('connected'),
        relayRoutingId: drift.Value(relayRoutingIdB64),
        peerPublicMaterial: drift.Value(peerPublicMaterialB64),
        displayName: displayName == null
            ? const drift.Value.absent()
            : drift.Value(displayName),
        avatarId: avatarId == null
            ? const drift.Value.absent()
            : drift.Value(avatarId),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Demotes a `connected` Contact back to `local-only` after a peer
  /// disconnect or a locally-initiated disconnect. Clears routing
  /// material so the row no longer participates in steady-state envelope
  /// dispatch.
  Future<void> demoteToLocalOnly(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(
        kind: const drift.Value('local-only'),
        relayRoutingId: const drift.Value(null),
        peerPublicMaterial: const drift.Value(null),
        updatedAt: drift.Value(now),
      ),
    );
  }
}
