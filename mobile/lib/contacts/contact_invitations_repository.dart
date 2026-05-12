import 'package:drift/drift.dart' as drift;

import '../db/app_database.dart';
import 'invitation_code.dart';

/// Status values stored in `contact_invitations.status`.
class InvitationStatus {
  static const String pending = 'pending';
  static const String used = 'used';
  static const String expired = 'expired';
  static const String revoked = 'revoked';
}

/// Manages on-device persistence of outgoing invitation codes.
///
/// The relay is not contacted here; this layer is purely local. The
/// handshake (Wave B) will read pending rows from this repository when
/// validating an incoming `hello` envelope against a known nonce.
class ContactInvitationsRepository {
  ContactInvitationsRepository(this._db);

  final AppDatabase _db;

  /// Generates a new invitation, persists a `pending` row, and returns both
  /// the row metadata and the encoded code so the caller can present it for
  /// out-of-band sharing.
  Future<({ContactInvitation row, InvitationCode code, String shortCode, String deepLink})>
      generate({
    required Duration validFor,
    DateTime? now,
  }) async {
    final created = now ?? DateTime.now().toUtc();
    final code = InvitationCode.generate();
    final companion = ContactInvitationsCompanion.insert(
      id: code.invitationIdHex(),
      nonce: code.nonceHex(),
      status: InvitationStatus.pending,
      createdAt: created,
      expiresAt: created.add(validFor),
    );
    await _db.upsertContactInvitation(companion);
    final row = await (_db.select(_db.contactInvitations)
          ..where((t) => t.id.equals(code.invitationIdHex())))
        .getSingle();
    return (
      row: row,
      code: code,
      shortCode: code.renderShort(),
      deepLink: code.renderDeepLink(),
    );
  }

  /// Returns invitations sorted most-recent-first. Status is re-evaluated
  /// against `now` so a row reported as pending by the database is also
  /// not silently past its `expiresAt`.
  Future<List<ContactInvitation>> listWithFreshStatus({DateTime? now}) async {
    final all = await _db.listContactInvitations();
    final reference = now ?? DateTime.now().toUtc();
    final out = <ContactInvitation>[];
    for (final row in all) {
      if (row.status == InvitationStatus.pending &&
          row.expiresAt.isBefore(reference)) {
        await _markStatus(row.id, InvitationStatus.expired, consumedAt: reference);
        out.add(row.copyWith(
          status: InvitationStatus.expired,
          consumedAt: drift.Value(reference),
        ));
      } else {
        out.add(row);
      }
    }
    return out;
  }

  /// Marks the given invitation revoked. Returns true if the row was found
  /// and was in a state where revocation is allowed (pending only).
  Future<bool> revoke(String invitationId, {DateTime? now}) async {
    final row = await (_db.select(_db.contactInvitations)
          ..where((t) => t.id.equals(invitationId)))
        .getSingleOrNull();
    if (row == null || row.status != InvitationStatus.pending) return false;
    await _markStatus(
      invitationId,
      InvitationStatus.revoked,
      consumedAt: now ?? DateTime.now().toUtc(),
    );
    return true;
  }

  /// Marks the invitation consumed. Called by the Wave B handshake layer
  /// when a matching `hello` envelope has been validated, regardless of
  /// whether the local user ultimately accepts or rejects: the nonce is
  /// considered consumed on first validation per the spec.
  Future<bool> markUsed(String invitationId, {DateTime? now}) async {
    final row = await (_db.select(_db.contactInvitations)
          ..where((t) => t.id.equals(invitationId)))
        .getSingleOrNull();
    if (row == null || row.status != InvitationStatus.pending) return false;
    if (row.expiresAt.isBefore(now ?? DateTime.now().toUtc())) {
      await _markStatus(
        invitationId,
        InvitationStatus.expired,
        consumedAt: now ?? DateTime.now().toUtc(),
      );
      return false;
    }
    await _markStatus(
      invitationId,
      InvitationStatus.used,
      consumedAt: now ?? DateTime.now().toUtc(),
    );
    return true;
  }

  Future<void> _markStatus(
    String id,
    String status, {
    DateTime? consumedAt,
  }) async {
    await (_db.update(_db.contactInvitations)..where((t) => t.id.equals(id)))
        .write(
      ContactInvitationsCompanion(
        status: drift.Value(status),
        consumedAt: consumedAt == null
            ? const drift.Value.absent()
            : drift.Value(consumedAt),
      ),
    );
  }
}
