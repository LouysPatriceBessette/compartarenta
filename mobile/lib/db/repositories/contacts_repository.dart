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

  Future<List<Contact>> list({bool includeDeleted = false}) =>
      _db.listContacts(includeDeleted: includeDeleted);

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
}
