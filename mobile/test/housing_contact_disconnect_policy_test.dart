import 'package:compartarenta/contacts/contact_module_anchor.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/contacts/housing_contact_disconnect_policy.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _planWithContact({
  required String planId,
  required DateTime periodEnd,
}) async {
  const contactId = 'contact:peer';
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  await db.upsertContact(
    ContactsCompanion.insert(
      id: contactId,
      kind: 'connected',
      displayName: 'Peer',
      avatarId: 'a01',
      peerPublicMaterial: const drift.Value('peer-key-material'),
      relayRoutingId: const drift.Value('route-id'),
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:self',
      displayName: 'Self',
      avatarId: 'a01',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p1',
      displayName: 'Peer',
      avatarId: 'a01',
      contactId: const drift.Value(contactId),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agr:$planId',
      planId: planId,
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: periodEnd,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$planId',
      planId: planId,
      activeRevisionId: const drift.Value('rev:active'),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: 'rev:active',
      packageId: 'pkg:$planId',
      contentHash: 'hash:active',
      proposerParticipantId: '$planId:self',
      payloadJson: '{"lifecycleState":"active"}',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  return db;
}

void main() {
  group('housingInForceAgreementBlocksContactDisconnect', () {
    test('blocks while agreement period is open', () async {
      final db = await _planWithContact(
        planId: 'plan:open',
        periodEnd: DateTime.utc(2026, 12, 31),
      );
      addTearDown(db.close);

      expect(
        await housingInForceAgreementBlocksContactDisconnect(
          db: db,
          planId: 'plan:open',
          contactId: 'contact:peer',
          now: DateTime.utc(2026, 6, 15),
        ),
        isTrue,
      );
    });

    test('allows after period end', () async {
      final db = await _planWithContact(
        planId: 'plan:ended',
        periodEnd: DateTime.utc(2026, 1, 31),
      );
      addTearDown(db.close);

      expect(
        await housingInForceAgreementBlocksContactDisconnect(
          db: db,
          planId: 'plan:ended',
          contactId: 'contact:peer',
          now: DateTime.utc(2026, 6, 15),
        ),
        isFalse,
      );
    });
  });

  group('housingUnpublishedExpenseBlocksContactDisconnect', () {
    test('blocks when contact is payer on draft expense', () async {
      final db = await _planWithContact(
        planId: 'plan:expense',
        periodEnd: DateTime.utc(2026, 1, 31),
      );
      addTearDown(db.close);

      await db.into(db.realizedExpenses).insert(
        RealizedExpensesCompanion.insert(
          id: 'exp:1',
          packageId: 'pkg:plan:expense',
          planId: 'plan:expense',
          planLineId: 'line:1',
          status: RealizedExpenseStatus.draft,
          amountMinor: 1000,
          currency: 'CAD',
          paymentDate: DateTime.utc(2026, 1, 15),
          payerParticipantId: 'plan:expense:p1',
          kind: RealizedExpenseKind.normal,
          createdAt: DateTime.utc(2026, 1, 15),
          updatedAt: DateTime.utc(2026, 1, 15),
        ),
      );

      expect(
        await housingUnpublishedExpenseBlocksContactDisconnect(
          db: db,
          planId: 'plan:expense',
          contactId: 'contact:peer',
        ),
        isTrue,
      );
    });

    test('allows when expenses are published', () async {
      final db = await _planWithContact(
        planId: 'plan:pub',
        periodEnd: DateTime.utc(2026, 1, 31),
      );
      addTearDown(db.close);

      await db.into(db.realizedExpenses).insert(
        RealizedExpensesCompanion.insert(
          id: 'exp:pub',
          packageId: 'pkg:plan:pub',
          planId: 'plan:pub',
          planLineId: 'line:1',
          status: RealizedExpenseStatus.published,
          amountMinor: 1000,
          currency: 'CAD',
          paymentDate: DateTime.utc(2026, 1, 15),
          payerParticipantId: 'plan:pub:p1',
          kind: RealizedExpenseKind.normal,
          createdAt: DateTime.utc(2026, 1, 15),
          updatedAt: DateTime.utc(2026, 1, 15),
        ),
      );

      expect(
        await housingUnpublishedExpenseBlocksContactDisconnect(
          db: db,
          planId: 'plan:pub',
          contactId: 'contact:peer',
        ),
        isFalse,
      );
    });
  });

  group('listContactDisconnectBlocks', () {
    test('blocks in-force agreement', () async {
      final db = await _planWithContact(
        planId: 'plan:inforce',
        periodEnd: DateTime.utc(2026, 12, 31),
      );
      addTearDown(db.close);

      final blocks = await listContactDisconnectBlocks(
        db,
        'contact:peer',
        now: DateTime.utc(2026, 6, 15),
      );
      expect(blocks, hasLength(1));
      expect(blocks.single.kind, ContactAnchorBlockKind.activeAgreement);
    });

    test('allows disconnect after period end with no open work', () async {
      final db = await _planWithContact(
        planId: 'plan:clear',
        periodEnd: DateTime.utc(2026, 1, 31),
      );
      addTearDown(db.close);

      final blocks = await listContactDisconnectBlocks(
        db,
        'contact:peer',
        now: DateTime.utc(2026, 6, 15),
      );
      expect(blocks, isEmpty);
    });

    test('blocks unpublished expense after period end', () async {
      final db = await _planWithContact(
        planId: 'plan:settle',
        periodEnd: DateTime.utc(2026, 1, 31),
      );
      addTearDown(db.close);

      await db.into(db.realizedExpenses).insert(
        RealizedExpensesCompanion.insert(
          id: 'exp:settle',
          packageId: 'pkg:plan:settle',
          planId: 'plan:settle',
          planLineId: 'line:1',
          status: RealizedExpenseStatus.proposed,
          amountMinor: 500,
          currency: 'CAD',
          paymentDate: DateTime.utc(2026, 2, 1),
          payerParticipantId: 'plan:settle:self',
          kind: RealizedExpenseKind.transfer,
          beneficiaryParticipantId: const drift.Value('plan:settle:p1'),
          createdAt: DateTime.utc(2026, 2, 1),
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      );

      final blocks = await listContactDisconnectBlocks(
        db,
        'contact:peer',
        now: DateTime.utc(2026, 6, 15),
      );
      expect(blocks, hasLength(1));
      expect(
        blocks.single.kind,
        ContactAnchorBlockKind.unpublishedRealizedExpense,
      );
    });
  });
}
