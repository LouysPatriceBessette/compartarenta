import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show OrderingTerm;

import '../db/app_database.dart';

/// Append-only relay-related activity on this device (Settings audit trail).
class RelayActivityLogService {
  RelayActivityLogService(this._db);

  final AppDatabase _db;

  static const initiatorSelf = 'self';
  static const initiatorContact = 'contact';
  static const initiatorSystem = 'system';

  Future<void> append({
    required String kind,
    required String initiatorKind,
    String? initiatorContactId,
    String? initiatorDisplayName,
    String? planId,
    String? packageId,
    String? revisionId,
    Map<String, Object?> details = const {},
    DateTime? occurredAt,
  }) async {
    final at = (occurredAt ?? DateTime.now()).toUtc();
    final id = 'log:${at.microsecondsSinceEpoch}';
    await _db.into(_db.relayActivityLogEntries).insert(
          RelayActivityLogEntriesCompanion.insert(
            id: id,
            occurredAt: at,
            kind: kind,
            initiatorKind: initiatorKind,
            initiatorContactId: drift.Value(initiatorContactId),
            initiatorDisplayName: drift.Value(initiatorDisplayName ?? ''),
            planId: drift.Value(planId),
            packageId: drift.Value(packageId),
            revisionId: drift.Value(revisionId),
            detailsJson: drift.Value(jsonEncode(details)),
          ),
        );
  }

  Future<List<RelayActivityLogEntry>> listFiltered({
    DateTime? fromUtc,
    DateTime? toUtc,
    String? initiatorKind,
    String? initiatorContactId,
    int limit = 500,
  }) async {
    final q = _db.select(_db.relayActivityLogEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.where((row) {
      if (fromUtc != null && row.occurredAt.isBefore(fromUtc)) return false;
      if (toUtc != null && row.occurredAt.isAfter(toUtc)) return false;
      if (initiatorKind != null && row.initiatorKind != initiatorKind) {
        return false;
      }
      if (initiatorContactId != null &&
          row.initiatorContactId != initiatorContactId) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }
}

/// Stable event kind strings for [RelayActivityLogService.append].
abstract final class RelayActivityLogKinds {
  static const contactHandshakeReceived = 'contact_handshake_received';
  static const contactDisconnected = 'contact_disconnected';
  static const contactDeleted = 'contact_deleted';
  static const housingProposalSent = 'housing_proposal_sent';
  static const housingProposalReceived = 'housing_proposal_received';
  static const housingProposalResponse = 'housing_proposal_response';
  static const housingProposalInvalidated = 'housing_proposal_invalidated';
  static const housingProposalExpired = 'housing_proposal_expired';
  static const housingProposalForkCreated = 'housing_proposal_fork_created';
}
