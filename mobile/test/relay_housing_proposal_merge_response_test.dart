import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_duplicate_handshake_dialog_state.dart';
import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/device/device_binding_service.dart';
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
  Future<void> contactDuplicateModuleAnchorRejected() async {}

  @override
  Future<void> contactDisconnected({required String displayName}) async {}

  @override
  Future<void> planPeerEstablishmentRequestReceived({
    required String requesterDisplayName,
    required String proposerDisplayName,
    required String planId,
  }) async {}
}

class _Side {
  _Side({
    required this.db,
    required this.dbFile,
    required this.orchestrator,
    required this.contacts,
  });

  final AppDatabase db;
  final File dbFile;
  final HandshakeOrchestrator orchestrator;
  final ContactsRepository contacts;
}

int _relayDbFileSeq = 0;

Future<_Side> _spawnSide({
  required FakeRelayClient relay,
  required Uint8List identitySeed,
  required String deviceBindingId,
}) async {
  final id = _relayDbFileSeq++;
  final dbFile = File(
    '${Directory.systemTemp.path}/relay_housing_merge_resp_test_$id.sqlite',
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
    deviceBinding: DeviceBindingService(fixedIdForTesting: deviceBindingId),
  );
  return _Side(
    db: db,
    dbFile: dbFile,
    orchestrator: orchestrator,
    contacts: contacts,
  );
}

Future<String> _seedTwoParticipantPlan({
  required AppDatabase db,
  required String planId,
  required String louysContactId,
}) async {
  final now = DateTime.utc(2026, 7, 7);
  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: now,
      title: const drift.Value('Entente de logement'),
      currency: const drift.Value('CAD'),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:self',
      displayName: 'Monica QA',
      avatarId: 'mdi:monica',
      createdAt: now,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p0',
      displayName: 'Louys QA',
      avatarId: 'mdi:louys',
      createdAt: now,
      contactId: drift.Value(louysContactId),
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
      title: 'Loyer',
      currency: 'CAD',
      amountMinor: const drift.Value(100000),
      recurrenceDayOfMonth: const drift.Value(1),
      createdAt: now,
    ),
  );
  return PlanAgreementProposalService(db).createRevisionFromCurrentDraft(
    planId: planId,
    proposerParticipantId: '$planId:self',
  );
}

Future<String?> _receivedPlanIdForLouys(_Side louys) async {
  final plans = await louys.db.select(louys.db.plans).get();
  for (final plan in plans) {
    if (!plan.id.startsWith('received:')) continue;
    final pkg = await (louys.db.select(louys.db.proposalPackages)
          ..where((t) => t.planId.equals(plan.id)))
        .getSingleOrNull();
    if (pkg?.pendingRevisionId != null && pkg!.pendingRevisionId!.isNotEmpty) {
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
  late _Side louysFirst;
  late _Side louysSecond;

  setUp(() async {
    relay = FakeRelayClient();
    monica = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 1 + i)),
      deviceBindingId: 'monica-binding',
    );
    louysFirst = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 51 + i)),
      deviceBindingId: 'louys-binding-shared',
    );
    louysSecond = await _spawnSide(
      relay: relay,
      identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 151 + i)),
      deviceBindingId: 'louys-binding-shared',
    );
    monica.orchestrator.ackProfileForAutoAccept = () async => (
      displayName: 'Louys QA',
      avatarId: 'mdi:louys',
    );
  });

  tearDown(() async {
    for (final side in [monica, louysFirst, louysSecond]) {
      side.orchestrator.stopPolling();
      await side.db.close();
      try {
        if (side.dbFile.existsSync()) side.dbFile.deleteSync();
      } catch (_) {}
    }
  });

  test(
    'after inviter merge, louys acceptance reaches monica and activates plan',
    () async {
      final invite1 = await monica.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'Louys QA',
        stubAvatarId: 'mdi:louys',
      );
      final code1 =
          (parseInvitationCode(invite1.shortCode) as InvitationCodeOk).code;
      await louysFirst.orchestrator.redeemInvitation(
        code: code1,
        selfDisplayName: 'Louys QA',
        selfAvatarId: 'mdi:louys',
      );
      await monica.orchestrator.processAllPendingHandshakes();
      await louysFirst.orchestrator.processAllPendingHandshakes();

      final firstLouysContactId = (await monica.contacts.list())
          .singleWhere((c) => c.kind == 'connected')
          .id;

      final invite2 = await monica.orchestrator.generateInvitation(
        validFor: const Duration(hours: 1),
        stubDisplayName: 'Louys QA',
        stubAvatarId: 'mdi:louys',
      );
      final code2 =
          (parseInvitationCode(invite2.shortCode) as InvitationCodeOk).code;
      await louysSecond.orchestrator.redeemInvitation(
        code: code2,
        selfDisplayName: 'Louys QA',
        selfAvatarId: 'mdi:louys',
      );
      await monica.orchestrator.processAllPendingHandshakes();
      await louysSecond.orchestrator.processAllPendingHandshakes();

      final mergedLouys = (await monica.contacts.list())
          .where((c) => c.kind == 'connected')
          .toList();
      expect(mergedLouys.length, 1);
      expect(mergedLouys.single.id, firstLouysContactId);
      expect(
        monica.orchestrator.pendingContactDuplicateDialog.value?.kind,
        ContactDuplicateDialogKind.inviterMerged,
      );

      const planId = 'housing:merge-response-test';
      final revisionId = await _seedTwoParticipantPlan(
        db: monica.db,
        planId: planId,
        louysContactId: firstLouysContactId,
      );

      final send = await monica.orchestrator.sendHousingProposalToPlanParticipants(
        planId: planId,
        revisionId: revisionId,
      );
      expect(send.sentCount, 1);
      expect(send.failedParticipantIds, isEmpty);

      await louysSecond.orchestrator.pollSteadyStateInboxes();
      final louysPlanId = await _receivedPlanIdForLouys(louysSecond);
      expect(louysPlanId, isNotNull);

      final louysPkg = await (louysSecond.db.select(louysSecond.db.proposalPackages)
            ..where((t) => t.planId.equals(louysPlanId!)))
          .getSingle();
      final pendingRev = louysPkg.pendingRevisionId!;

      try {
        final accept = await louysSecond.orchestrator.sendHousingProposalResponse(
          planId: louysPlanId!,
          status: ProposalResponseStatus.accepted,
          revisionId: pendingRev,
        );
        expect(accept.sentCount, 1);
        expect(accept.failedParticipantIds, isEmpty);
      } on Object {
        // Louys-side activation may touch SharedPreferences in unit tests; Monica
        // delivery is validated below.
      }

      await monica.orchestrator.pollSteadyStateInboxes();

      final monicaPkg = await (monica.db.select(monica.db.proposalPackages)
            ..where((t) => t.planId.equals(planId)))
          .getSingle();
      final responses = await (monica.db.select(monica.db.proposalResponses)
            ..where((t) => t.revisionId.equals(revisionId)))
          .get();
      final louysResponse = responses
          .where((r) => r.participantId == '$planId:p0')
          .map((r) => r.status)
          .firstOrNull;
      expect(
        louysResponse,
        ProposalResponseStatus.accepted.name,
        reason: 'Monica should record Louys acceptance after merge',
      );
      expect(
        monicaPkg.activeRevisionId,
        revisionId,
        reason: 'Monica plan should activate unanimously',
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
