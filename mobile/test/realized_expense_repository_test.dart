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
}
