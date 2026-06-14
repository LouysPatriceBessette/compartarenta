import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

class _FakeContactNotificationSink implements ContactNotificationSink {
  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {}

  @override
  Future<void> contactAddedViaInvitation({required String displayName}) async {}

  @override
  Future<void> contactAddRequestResolved({
    required String displayName,
    required bool accepted,
  }) async {}

  @override
  Future<void> contactAddRequestFailed({required String errorCode}) async {}

  @override
  Future<void> contactDisconnected({required String displayName}) async {}
}

class _Side {
  _Side({
    required this.db,
    required this.dbFile,
    required this.orchestrator,
  });

  final AppDatabase db;
  final File dbFile;
  final HandshakeOrchestrator orchestrator;
}

int _relayDbFileSeq = 0;

Future<_Side> _spawnSide({
  required FakeRelayClient relay,
  required Uint8List identitySeed,
}) async {
  final id = _relayDbFileSeq++;
  final dbFile = File(
    '${Directory.systemTemp.path}/relay_housing_mesh_test_$id.sqlite',
  );
  if (dbFile.existsSync()) dbFile.deleteSync();
  final db = _DbForTesting(NativeDatabase(dbFile));
  final identity = InMemoryIdentityKeystore(seed: identitySeed);
  final contacts = ContactsRepository(db);
  final invitations = ContactInvitationsRepository(db);
  final orchestrator = HandshakeOrchestrator(
    db: db,
    identity: identity,
    relay: relay,
    contacts: contacts,
    invitations: invitations,
    contactNotifications: _FakeContactNotificationSink(),
    pollInterval: const Duration(seconds: 60),
  );
  return _Side(db: db, dbFile: dbFile, orchestrator: orchestrator);
}

Future<({String inviterContactId, String inviteeContactId})> _completeHandshake({
  required _Side inviter,
  required _Side invitee,
  required String inviteeDisplayName,
  required String inviterDisplayName,
}) async {
  final invite = await inviter.orchestrator.generateInvitation(
    validFor: const Duration(hours: 1),
    stubDisplayName: 'pending',
    stubAvatarId: 'mdi:account',
  );
  final code =
      (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
  final redeem = await invitee.orchestrator.redeemInvitation(
    code: code,
    selfDisplayName: inviteeDisplayName,
    selfAvatarId: 'mdi:peer',
  );
  inviter.orchestrator.ackProfileForAutoAccept = () async => (
    displayName: inviterDisplayName,
    avatarId: 'mdi:host',
  );
  await inviter.orchestrator.processAllPendingHandshakes();
  await invitee.orchestrator.processAllPendingHandshakes();
  return (
    inviterContactId: invite.localContactId,
    inviteeContactId: redeem.localContactId,
  );
}

Future<String> _seedThreeParticipantPlan({
  required AppDatabase db,
  required String planId,
  required String louysContactId,
  required String roberrContactId,
}) async {
  final now = DateTime.utc(2026, 6, 4);
  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: now,
      title: const drift.Value('Three-way housing'),
      currency: const drift.Value('CAD'),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:self',
      displayName: 'Monica',
      avatarId: 'mdi:monica',
      createdAt: now,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p0',
      displayName: 'Louys',
      avatarId: 'mdi:louys',
      createdAt: now,
      contactId: drift.Value(louysContactId),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p1',
      displayName: 'Roberr',
      avatarId: 'mdi:roberr',
      createdAt: now,
      contactId: drift.Value(roberrContactId),
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: now,
      periodEnd: now.add(const Duration(days: 180)),
      createdAt: now,
    ),
  );
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: '$planId:line0',
      planId: planId,
      isRecurring: true,
      title: 'Rent',
      currency: 'CAD',
      amountMinor: const drift.Value(71500),
      recurrenceDayOfMonth: const drift.Value(1),
      createdAt: now,
    ),
  );
  return PlanAgreementProposalService(db).createRevisionFromCurrentDraft(
    planId: planId,
    proposerParticipantId: '$planId:self',
  );
}

Future<String?> _receivedPlanIdForPeer(_Side side, String proposerName) async {
  final plans = await side.db.select(side.db.plans).get();
  for (final plan in plans) {
    if (!plan.id.startsWith('received:')) continue;
    final roster = (await side.db.listParticipants())
        .where((p) => p.id.startsWith('${plan.id}:'))
        .toList();
    if (roster.any(
      (p) => p.displayName == proposerName && p.contactId != null,
    )) {
      return plan.id;
    }
  }
  return null;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  late FakeRelayClient relay;
  late _Side monica;
  late _Side louys;
  late _Side roberr;

  setUp(() async {
    relay = FakeRelayClient();
    monica = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 1 + i)),
    );
    louys = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 51 + i)),
    );
    roberr = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 101 + i)),
    );
  });

  tearDown(() async {
    for (final side in [monica, louys, roberr]) {
      side.orchestrator.stopPolling();
      await side.db.close();
      try {
        if (side.dbFile.existsSync()) side.dbFile.deleteSync();
      } catch (_) {}
    }
  });

  test(
    'co-participant acceptance reaches other invitees without roster contactId',
    () async {
      final monicaLouys = await _completeHandshake(
        inviter: monica,
        invitee: louys,
        inviteeDisplayName: 'Louys',
        inviterDisplayName: 'Monica',
      );
      final monicaRoberr = await _completeHandshake(
        inviter: monica,
        invitee: roberr,
        inviteeDisplayName: 'Roberr',
        inviterDisplayName: 'Monica',
      );
      await _completeHandshake(
        inviter: louys,
        invitee: roberr,
        inviteeDisplayName: 'Roberr',
        inviterDisplayName: 'Louys',
      );

      const planId = 'housing:mesh-three';
      final revisionId = await _seedThreeParticipantPlan(
        db: monica.db,
        planId: planId,
        louysContactId: monicaLouys.inviteeContactId,
        roberrContactId: monicaRoberr.inviteeContactId,
      );

      final send = await monica.orchestrator.sendHousingProposalToPlanParticipants(
        planId: planId,
        revisionId: revisionId,
      );
      expect(send.sentCount, 2);
      expect(send.failedParticipantIds, isEmpty);

      await louys.orchestrator.pollSteadyStateInboxes();
      await roberr.orchestrator.pollSteadyStateInboxes();

      final louysPlanId = await _receivedPlanIdForPeer(louys, 'Monica');
      final roberrPlanId = await _receivedPlanIdForPeer(roberr, 'Monica');
      expect(louysPlanId, isNotNull);
      expect(roberrPlanId, isNotNull);
      final louysPlan = louysPlanId!;
      final roberrPlan = roberrPlanId!;

      final louysRoberrRow = (await louys.db.listParticipants())
          .where((p) => p.id.startsWith('$louysPlan:') && p.displayName == 'Roberr')
          .single;
      expect(louysRoberrRow.contactId, isNull);

      final roberrRevision = await (roberr.db.select(roberr.db.proposalPackages)
            ..where((t) => t.planId.equals(roberrPlan)))
          .getSingle();
      final pendingRev = roberrRevision.pendingRevisionId!;

      final acceptResult = await roberr.orchestrator.sendHousingProposalResponse(
        planId: roberrPlan,
        status: ProposalResponseStatus.accepted,
        revisionId: pendingRev,
      );
      expect(acceptResult.sentCount, 2);
      expect(acceptResult.failedParticipantIds, isEmpty);
      expect(relay.envelopeCount, greaterThanOrEqualTo(2));

      await louys.orchestrator.pollSteadyStateInboxes();

      final louysPkg = await (louys.db.select(louys.db.proposalPackages)
            ..where((t) => t.planId.equals(louysPlan)))
          .getSingle();
      final louysRevId = louysPkg.pendingRevisionId!;
      final responses = await (louys.db.select(louys.db.proposalResponses)
            ..where((t) => t.revisionId.equals(louysRevId)))
          .get();
      final roberrResponse = responses
          .where((r) => r.participantId == louysRoberrRow.id)
          .map((r) => r.status)
          .firstOrNull;
      expect(roberrResponse, ProposalResponseStatus.accepted.name);
    },
  );
}
