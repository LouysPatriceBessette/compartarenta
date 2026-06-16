import 'package:compartarenta/contacts/profile_rename_policy.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _planWithOpenProposalVote() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  const planId = 'housing:vote';
  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      title: const drift.Value('Flat vote'),
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
  const revisionId = 'rev:open';
  await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:$planId',
          planId: planId,
          pendingRevisionId: const drift.Value(revisionId),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
  await db.into(db.proposalRevisions).insert(
        ProposalRevisionsCompanion.insert(
          id: revisionId,
          packageId: 'pkg:$planId',
          contentHash: 'hash',
          proposerParticipantId: '$planId:self',
          payloadJson: '{"lifecycleState":"open"}',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
  return db;
}

void main() {
  test('listProfileRenameBlocks includes open proposal vote for self roster', () async {
    final db = await _planWithOpenProposalVote();
    addTearDown(db.close);

    final blocks = await listProfileRenameBlocks(db);

    expect(blocks, hasLength(1));
    expect(blocks.single.kind, ProfileRenameBlockKind.openProposalVote);
    expect(blocks.single.planTitle, 'Flat vote');
  });

  test('listProfileRenameBlocks ignores plans without self participant', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'housing:other',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(await listProfileRenameBlocks(db), isEmpty);
  });

  test('listProfileRenameBlocks includes pending participation change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:pc';
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        title: const drift.Value('Participation vote'),
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
    await db.into(db.housingParticipationChanges).insert(
          HousingParticipationChangesCompanion.insert(
            id: 'pc:1',
            planId: planId,
            packageId: 'pkg:$planId',
            kind: HousingParticipationChangeKind.immediateTermination.wireValue,
            initiatorParticipantId: '$planId:self',
            status: HousingParticipationChangeStatus.pending.wireValue,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final blocks = await listProfileRenameBlocks(db);

    expect(blocks, hasLength(1));
    expect(blocks.single.kind, ProfileRenameBlockKind.pendingParticipationChange);
  });

  test('profileDisplayNameChangeBlocked is false without open vote', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:draft';
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

    expect(await profileDisplayNameChangeBlocked(db), isFalse);
  });
}
