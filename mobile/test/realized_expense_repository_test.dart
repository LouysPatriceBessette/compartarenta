import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_repository.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RealizedExpenseRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RealizedExpenseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saveDraft persists expense and attachments', () async {
    final paymentDate = DateTime.utc(2026, 5, 20);
    final saved = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: 'housing:test',
      planLineId: 'line:1',
      amountMinor: 12000,
      currency: 'CAD',
      paymentDate: paymentDate,
      payerParticipantId: 'housing:test:self',
      kind: RealizedExpenseKind.normal,
      attachments: [
        RealizedExpenseAttachmentDraft(
          filePath: '/tmp/receipt.jpg',
          displayFileName: 'receipt.jpg',
        ),
      ],
    );

    expect(saved.status, RealizedExpenseStatus.draft);
    expect(saved.amountMinor, 12000);

    final again = await repo.getById(saved.id);
    expect(again?.planLineId, 'line:1');

    final attachments = await repo.attachmentsFor(saved.id);
    expect(attachments, hasLength(1));
    expect(attachments.single.displayFileName, 'receipt.jpg');
  });

  test('saveDraft updates existing draft', () async {
    final first = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: 'housing:test',
      planLineId: 'line:1',
      amountMinor: 10000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: 'housing:test:self',
      kind: RealizedExpenseKind.normal,
    );
    final second = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: 'housing:test',
      planLineId: 'line:1',
      amountMinor: 15000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 2),
      payerParticipantId: 'housing:test:self',
      kind: RealizedExpenseKind.normal,
      existingExpenseId: first.id,
    );
    expect(second.id, first.id);
    expect(second.amountMinor, 15000);
    expect(second.createdAt, first.createdAt);
  });

  test('deleteDraft removes row', () async {
    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: 'housing:test',
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: 'housing:test:self',
      kind: RealizedExpenseKind.normal,
    );
    await repo.deleteDraft(draft.id);
    expect(await repo.getById(draft.id), isNull);
  });

  test('listDraftsForPackage returns only drafts', () async {
    await repo.saveDraft(
      packageId: 'pkg-a',
      planId: 'housing:a',
      planLineId: 'line:1',
      amountMinor: 100,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: 'p:self',
      kind: RealizedExpenseKind.normal,
    );
    await db.into(db.realizedExpenses).insert(
          RealizedExpensesCompanion.insert(
            id: 'realized:published-1',
            packageId: 'pkg-a',
            planId: 'housing:a',
            planLineId: 'line:1',
            status: RealizedExpenseStatus.published,
            amountMinor: 200,
            currency: 'CAD',
            paymentDate: DateTime.utc(2026, 5, 2),
            payerParticipantId: 'p:self',
            kind: RealizedExpenseKind.normal,
            createdAt: DateTime.utc(2026, 5, 2),
            updatedAt: DateTime.utc(2026, 5, 2),
          ),
        );

    final drafts = await repo.listDraftsForPackage('pkg-a');
    expect(drafts, hasLength(1));
    expect(drafts.single.status, RealizedExpenseStatus.draft);
  });

  test('proposeLocally auto-accepts payer not only self slot', () async {
    const planId = 'housing:payer';
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'You',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:p1',
            displayName: 'Alex',
            avatarId: '1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: planId,
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: '$planId:p1',
      kind: RealizedExpenseKind.normal,
    );

    await repo.proposeLocally(draft.id);
    final acceptances = await repo.acceptancesFor(draft.id);
    expect(
      acceptances.where((a) => a.participantId == '$planId:p1').single.decision,
      RealizedExpenseDecision.accepted,
    );
    expect(
      acceptances.where((a) => a.participantId == '$planId:self').single.decision,
      RealizedExpenseDecision.pending,
    );
  });

  test('proposeLocally sets proposed and pending acceptances', () async {
    const planId = 'housing:test';
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'You',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:p1',
            displayName: 'Alex',
            avatarId: '1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: planId,
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: '$planId:self',
      kind: RealizedExpenseKind.normal,
    );

    final proposed = await repo.proposeLocally(draft.id);
    expect(proposed.status, RealizedExpenseStatus.proposed);

    final acceptances = await repo.acceptancesFor(draft.id);
    expect(acceptances, hasLength(2));
    final payer = acceptances
        .where((a) => a.participantId == '$planId:self')
        .single;
    expect(payer.decision, RealizedExpenseDecision.accepted);
    expect(
      acceptances
          .where((a) => a.participantId == '$planId:p1')
          .single
          .decision,
      RealizedExpenseDecision.pending,
    );
  });

  test('unanimous accept publishes expense', () async {
    const planId = 'housing:pub';
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'You',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:p1',
            displayName: 'Alex',
            avatarId: '1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: planId,
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: '$planId:self',
      kind: RealizedExpenseKind.normal,
    );
    await repo.proposeLocally(draft.id);
    await repo.recordLocalAccept(
      expenseId: draft.id,
      participantId: '$planId:p1',
    );

    final row = await repo.getById(draft.id);
    expect(row?.status, RealizedExpenseStatus.published);
  });

  test('reject blocks publish', () async {
    const planId = 'housing:rej';
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'You',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:p1',
            displayName: 'Alex',
            avatarId: '1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: planId,
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: '$planId:self',
      kind: RealizedExpenseKind.normal,
    );
    await repo.proposeLocally(draft.id);
    await repo.recordLocalReject(
      expenseId: draft.id,
      participantId: '$planId:p1',
      justification: 'Wrong amount',
    );

    final row = await repo.getById(draft.id);
    expect(row?.status, RealizedExpenseStatus.rejected);
  });

  test('resubmit creates new draft with prior link', () async {
    const planId = 'housing:resubmit';
    await db.into(db.participants).insert(
          ParticipantsCompanion.insert(
            id: '$planId:self',
            displayName: 'You',
            avatarId: '0',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final draft = await repo.saveDraft(
      packageId: 'pkg-1',
      planId: planId,
      planLineId: 'line:1',
      amountMinor: 5000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 5, 1),
      payerParticipantId: '$planId:self',
      kind: RealizedExpenseKind.normal,
    );
    await repo.proposeLocally(draft.id);
    await repo.recordLocalReject(
      expenseId: draft.id,
      participantId: '$planId:self',
      justification: 'Fix proof',
    );

    final resubmit = await repo.createResubmitDraftFromRejected(draft.id);
    expect(resubmit.status, RealizedExpenseStatus.draft);
    expect(resubmit.priorExpenseId, draft.id);
    expect(resubmit.id, isNot(draft.id));
  });
}
