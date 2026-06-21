import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_repository.dart';

/// Device-specific housing agreement export (tasks 5.1 / 5.4).
class HousingAgreementExportService {
  HousingAgreementExportService(this._db);

  static const formatVersion = 1;

  final AppDatabase _db;

  Future<Map<String, Object?>> buildExportBundle({
    required String packageId,
    required String planId,
  }) async {
    final pkg = await (_db.select(_db.proposalPackages)
          ..where((t) => t.id.equals(packageId)))
        .getSingleOrNull();
    if (pkg == null) {
      throw StateError('package not found: $packageId');
    }

    final revisions = await (_db.select(_db.proposalRevisions)
          ..where((t) => t.packageId.equals(packageId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    final expenseRepo = RealizedExpenseRepository(_db);
    final expenses = await (_db.select(_db.realizedExpenses)
          ..where((t) => t.packageId.equals(packageId))
          ..orderBy([(t) => OrderingTerm.asc(t.paymentDate)]))
        .get();

    final expenseRows = <Map<String, Object?>>[];
    for (final e in expenses) {
      final attachments = await expenseRepo.attachmentsFor(e.id);
      final acceptances = await expenseRepo.acceptancesFor(e.id);
      expenseRows.add({
        'id': e.id,
        'planId': e.planId,
        'planLineId': e.planLineId,
        'status': e.status,
        'kind': e.kind,
        'amountMinor': e.amountMinor,
        'currency': e.currency,
        'paymentDate': e.paymentDate.toIso8601String(),
        'payerParticipantId': e.payerParticipantId,
        'beneficiaryParticipantId': e.beneficiaryParticipantId,
        'description': e.description,
        'paymentChartCarryForwardMinor': e.paymentChartCarryForwardMinor,
        'attachments': [
          for (final a in attachments)
            {
              'id': a.id,
              'filePath': a.filePath,
              'displayFileName': a.displayFileName,
              'contentHash': a.contentHash,
            },
        ],
        'acceptances': [
          for (final a in acceptances)
            {
              'participantId': a.participantId,
              'decision': a.decision,
              'decidedAt': a.decidedAt?.toIso8601String(),
              'rejectionJustification': a.rejectionJustification,
            },
        ],
      });
    }

    final pendingResponses = await (_db.select(_db.proposalResponses)
          ..where(
            (t) => t.revisionId.isIn(revisions.map((r) => r.id).toList()),
          ))
        .get();

    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'packageId': packageId,
      'planId': planId,
      'package': {
        'id': pkg.id,
        'planId': pkg.planId,
        'activeRevisionId': pkg.activeRevisionId,
        'pendingRevisionId': pkg.pendingRevisionId,
      },
      'revisions': [
        for (final r in revisions)
          {
            'id': r.id,
            'packageId': r.packageId,
            'contentHash': r.contentHash,
            'proposerParticipantId': r.proposerParticipantId,
            'createdAt': r.createdAt.toIso8601String(),
            'payloadJson': r.payloadJson,
          },
      ],
      'realizedExpenses': expenseRows,
      'proposalResponses': [
        for (final r in pendingResponses)
          {
            'id': r.id,
            'revisionId': r.revisionId,
            'participantId': r.participantId,
            'status': r.status,
            'respondedAt': r.respondedAt?.toIso8601String(),
          },
      ],
    };

    final checksum = await _checksumForPayload(payload);
    return {...payload, 'checksum': checksum};
  }

  Future<String> exportJsonString({
    required String packageId,
    required String planId,
  }) async {
    final bundle = await buildExportBundle(
      packageId: packageId,
      planId: planId,
    );
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  static Future<String> _checksumForPayload(Map<String, Object?> payload) async {
    final canonical = jsonEncode(payload);
    final hash = await Sha256().hash(utf8.encode(canonical));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<bool> verifyChecksum(Map<String, Object?> bundle) async {
    final expected = bundle.remove('checksum');
    if (expected is! String || expected.isEmpty) return false;
    final actual = await _checksumForPayload(bundle);
    bundle['checksum'] = expected;
    return actual == expected;
  }
}
