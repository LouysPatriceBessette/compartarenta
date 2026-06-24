import 'package:compartarenta/contacts/contact_module_anchor.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/proposals/housing_agreement_expiration_vote_settlement.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _activePlanWithOpenAmendment() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  const planId = 'plan:expired';
  const contactId = 'contact:peer';

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
      periodEnd: DateTime.utc(2026, 1, 31),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  const revisionId = 'rev:pending';
  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$planId',
      planId: planId,
      activeRevisionId: const drift.Value('rev:active'),
      pendingRevisionId: const drift.Value(revisionId),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: 'rev:active',
      packageId: 'pkg:$planId',
      contentHash: 'hash:active',
      proposerParticipantId: '$planId:self',
      payloadJson: '{"lifecycleState":"archived"}',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: revisionId,
      packageId: 'pkg:$planId',
      contentHash: 'hash:pending',
      proposerParticipantId: '$planId:self',
      payloadJson: '''
{"lifecycleState":"open","agreement":{"periodStart":"2026-01-01T00:00:00.000Z","periodEnd":"2026-12-31T00:00:00.000Z"}}
''',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalResponses).insert(
    ProposalResponsesCompanion.insert(
      id: 'resp:$revisionId:$planId:p1',
      revisionId: revisionId,
      participantId: '$planId:p1',
      status: ProposalResponseStatus.pending.name,
    ),
  );
  await db.into(db.housingParticipationChanges).insert(
    HousingParticipationChangesCompanion.insert(
      id: 'pc:term',
      planId: planId,
      packageId: 'pkg:$planId',
      kind: HousingParticipationChangeKind.ejection.wireValue,
      initiatorParticipantId: '$planId:self',
      targetParticipantId: const drift.Value('$planId:p1'),
      status: HousingParticipationChangeStatus.pending.wireValue,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  return db;
}

void main() {
  test('listContactDisconnectBlocks active agreement and open votes', () async {
    final db = await _activePlanWithOpenAmendment();
    addTearDown(db.close);

    final blocks = await listContactDisconnectBlocks(db, 'contact:peer');
    expect(blocks, isNotEmpty);
    expect(
      blocks.any((b) => b.kind == ContactAnchorBlockKind.activeAgreement),
      isTrue,
    );
  });

  test('settleExpiredAgreementVotes archives open amendment after period end',
      () async {
    final db = await _activePlanWithOpenAmendment();
    addTearDown(db.close);

    final processed = await settleExpiredAgreementVotes(db);
    expect(processed, contains('plan:expired'));

    final rev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals('rev:pending')))
        .getSingle();
    expect(rev.payloadJson, contains(kAgreementExpiredInvalidationStatus));

    final change = await (db.select(db.housingParticipationChanges)
          ..where((t) => t.id.equals('pc:term')))
        .getSingle();
    expect(change.status, HousingParticipationChangeStatus.aborted.wireValue);
  });
}
