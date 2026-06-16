import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_sync_service.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('import maps payer to sender contact', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:test';
    const packageId = 'pkg:1';
    const louysContact = 'contact:louys';

    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'Monica',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:p0',
            displayName: 'Louys',
            avatarId: '1',
            contactId: Value(louysContact),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: packageId,
            planId: planId,
            activeRevisionId: const Value('rev:active'),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.planLines).insert(
          PlanLinesCompanion.insert(
            id: 'line:rent',
            planId: planId,
            isRecurring: true,
            title: 'Loyer',
            currency: 'CAD',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final json = await RealizedExpenseSyncService(db).buildProposeJson(
      expense: RealizedExpense(
        id: 'realized:1',
        packageId: packageId,
        planId: planId,
        planLineId: 'line:rent',
        status: RealizedExpenseStatus.proposed,
        amountMinor: 5000,
        paymentChartCarryForwardMinor: 287,
        currency: 'CAD',
        paymentDate: DateTime.utc(2026, 5, 23),
        payerParticipantId: '$planId:p0',
        kind: RealizedExpenseKind.normal,
        beneficiaryParticipantId: null,
        priorExpenseId: null,
        planLineTitleSnapshot: null,
        splitRatiosJson: null,
        createdAt: DateTime.utc(2026, 5, 23),
        updatedAt: DateTime.utc(2026, 5, 23),
      ),
      attachments: const [],
    );

    final imported = await RealizedExpenseSyncService(db).importProposedFromPeer(
      expenseJson: json,
      senderContactId: louysContact,
    );
    expect(imported, isTrue);

    final row = await (db.select(db.realizedExpenses)
          ..where((t) => t.id.equals('realized:1')))
        .getSingle();
    expect(row.payerParticipantId, '$planId:p0');
    expect(row.planLineId, 'line:rent');
    expect(row.paymentChartCarryForwardMinor, 287);

    final acceptances = await (db.select(db.realizedExpenseAcceptances)
          ..where((t) => t.expenseId.equals('realized:1')))
        .get();
    final payerAcceptance = acceptances
        .where((a) => a.participantId == '$planId:p0')
        .single;
    expect(payerAcceptance.decision, RealizedExpenseDecision.accepted);
    expect(
      acceptances
          .where((a) => a.participantId == '$planId:self')
          .single
          .decision,
      RealizedExpenseDecision.pending,
    );
  });

  test('import uses local active plan when payload plan id is received:*', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const localPlanId = 'housing:default';
    const localPackageId = 'pkg:local';
    const remotePlanId = 'received:abc';
    const remotePackageId = 'pkg:received:abc';
    const louysContact = 'contact:louys';

    await db.into(db.plans).insert(
          PlansCompanion.insert(
            id: localPlanId,
            type: 'housing',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$localPlanId:self',
            displayName: 'Monica',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$localPlanId:p0',
            displayName: 'Louys',
            avatarId: '1',
            contactId: Value(louysContact),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: localPackageId,
            planId: localPlanId,
            activeRevisionId: const Value('rev:1'),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.planLines).insert(
          PlanLinesCompanion.insert(
            id: 'line:ute-local',
            planId: localPlanId,
            isRecurring: true,
            title: 'UTE',
            currency: 'CAD',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final payload = '''
{
  "expense_id": "realized:cross",
  "package_id": "$remotePackageId",
  "plan_id": "$remotePlanId",
  "plan_line_id": "line:other-device",
  "plan_line_title": "UTE",
  "amount_minor": 12500,
  "currency": "CAD",
  "payment_date": "2026-05-23T00:00:00.000Z",
  "kind": "normal",
  "participant_snapshots": [
    {"id": "$remotePlanId:self", "displayName": "Louys", "contactId": "$louysContact"}
  ],
  "attachments": []
}
''';

    final imported = await RealizedExpenseSyncService(db).importProposedFromPeer(
      expenseJson: payload,
      senderContactId: louysContact,
    );
    expect(imported, isTrue);

    final row = await (db.select(db.realizedExpenses)
          ..where((t) => t.id.equals('realized:cross')))
        .getSingle();
    expect(row.planId, localPlanId);
    expect(row.packageId, localPackageId);
    expect(row.planLineId, 'line:ute-local');
  });

  test('import maps payer by display name when roster lacks contactId link', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:roberr';
    const packageId = 'pkg:1';
    const louysContact = 'contact:louys';

    await db.into(db.plans).insert(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.participants).insert(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Roberr',
        avatarId: '0',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.participants).insert(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Louys',
        avatarId: '1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertContact(
      ContactsCompanion.insert(
        id: louysContact,
        kind: 'connected',
        displayName: 'Louys',
        avatarId: '1',
        peerPublicMaterial: const Value('peer-louys'),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: packageId,
        planId: planId,
        activeRevisionId: const Value('rev:active'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.planLines).insert(
      PlanLinesCompanion.insert(
        id: 'line:rent',
        planId: planId,
        isRecurring: true,
        title: 'Loyer',
        currency: 'CAD',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final payload = '''
{
  "expense_id": "realized:louys-from-roberr",
  "package_id": "$packageId",
  "plan_id": "$planId",
  "plan_line_id": "line:rent",
  "plan_line_title": "Loyer",
  "amount_minor": 5000,
  "currency": "CAD",
  "payment_date": "2026-05-23T00:00:00.000Z",
  "kind": "normal",
  "payer_participant_id": "$planId:self",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "$louysContact"}
  ],
  "attachments": []
}
''';

    final imported = await RealizedExpenseSyncService(db).importProposedFromPeer(
      expenseJson: payload,
      senderContactId: louysContact,
    );
    expect(imported, isTrue);

    final row = await (db.select(db.realizedExpenses)
          ..where((t) => t.id.equals('realized:louys-from-roberr')))
        .getSingle();
    expect(row.payerParticipantId, '$planId:p1');
  });

  test(
    'transfer import maps beneficiary to self when receiver is beneficiary',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'received:housing:default';
      const packageId = 'pkg:1';
      const louysPlanEstContact = 'contact:plan-est:received_housing_default_p1';

      await db.into(db.plans).insert(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:self',
          displayName: 'Roberr',
          avatarId: '0',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:p0',
          displayName: 'Monica',
          avatarId: '2',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:p1',
          displayName: 'Louys',
          avatarId: '1',
          contactId: Value(louysPlanEstContact),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertContact(
        ContactsCompanion.insert(
          id: louysPlanEstContact,
          kind: 'connected',
          displayName: 'Louys',
          avatarId: '1',
          peerPublicMaterial: const Value('peer-louys'),
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: packageId,
          planId: planId,
          activeRevisionId: const Value('rev:active'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final payload = '''
{
  "expense_id": "realized:transfer-roberr",
  "package_id": "$packageId",
  "plan_id": "$planId",
  "amount_minor": 10000,
  "currency": "CAD",
  "payment_date": "2026-06-16T00:00:00.000Z",
  "kind": "transfer",
  "payer_participant_id": "$planId:self",
  "beneficiary_participant_id": "$planId:p1",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "$louysPlanEstContact"},
    {"id": "$planId:p0", "displayName": "Monica"},
    {"id": "$planId:p1", "displayName": "Roberr", "contactId": "$louysPlanEstContact"}
  ],
  "attachments": []
}
''';

      final imported = await RealizedExpenseSyncService(db).importProposedFromPeer(
        expenseJson: payload,
        senderContactId: louysPlanEstContact,
      );
      expect(imported, isTrue);

      final row = await (db.select(db.realizedExpenses)
            ..where((t) => t.id.equals('realized:transfer-roberr')))
          .getSingle();
      expect(row.kind, RealizedExpenseKind.transfer);
      expect(row.payerParticipantId, '$planId:p1');
      expect(row.beneficiaryParticipantId, '$planId:self');

      final acceptances = await (db.select(db.realizedExpenseAcceptances)
            ..where((t) => t.expenseId.equals('realized:transfer-roberr')))
          .get();
      expect(acceptances, hasLength(2));
      expect(
        acceptances
            .singleWhere((a) => a.participantId == '$planId:p1')
            .decision,
        RealizedExpenseDecision.accepted,
      );
      expect(
        acceptances
            .singleWhere((a) => a.participantId == '$planId:self')
            .decision,
        RealizedExpenseDecision.pending,
      );
    },
  );

  test(
    'transfer import maps beneficiary to peer slot on third-party receiver',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'housing:default';
      const packageId = 'pkg:1';
      const louysHandshakeContact = 'contact:handshake:louys';

      await db.into(db.plans).insert(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:self',
          displayName: 'Monica',
          avatarId: '0',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:p0',
          displayName: 'Louys',
          avatarId: '1',
          contactId: Value(louysHandshakeContact),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.participants).insert(
        ParticipantsCompanion.insert(
          id: '$planId:p1',
          displayName: 'Roberr',
          avatarId: '2',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.upsertContact(
        ContactsCompanion.insert(
          id: louysHandshakeContact,
          kind: 'connected',
          displayName: 'Louys',
          avatarId: '1',
          peerPublicMaterial: const Value('peer-louys'),
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: packageId,
          planId: planId,
          activeRevisionId: const Value('rev:active'),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final payload = '''
{
  "expense_id": "realized:transfer-monica",
  "package_id": "$packageId",
  "plan_id": "$planId",
  "amount_minor": 10000,
  "currency": "CAD",
  "payment_date": "2026-06-16T00:00:00.000Z",
  "kind": "transfer",
  "payer_participant_id": "$planId:self",
  "beneficiary_participant_id": "$planId:p1",
  "participant_snapshots": [
    {"id": "$planId:self", "displayName": "Louys", "contactId": "$louysHandshakeContact"},
    {"id": "$planId:p0", "displayName": "Monica"},
    {"id": "$planId:p1", "displayName": "Roberr"}
  ],
  "attachments": []
}
''';

      final imported = await RealizedExpenseSyncService(db).importProposedFromPeer(
        expenseJson: payload,
        senderContactId: louysHandshakeContact,
      );
      expect(imported, isTrue);

      final row = await (db.select(db.realizedExpenses)
            ..where((t) => t.id.equals('realized:transfer-monica')))
          .getSingle();
      expect(row.payerParticipantId, '$planId:p0');
      expect(row.beneficiaryParticipantId, '$planId:p1');

      final acceptances = await (db.select(db.realizedExpenseAcceptances)
            ..where((t) => t.expenseId.equals('realized:transfer-monica')))
          .get();
      expect(acceptances, hasLength(2));
    },
  );
}
