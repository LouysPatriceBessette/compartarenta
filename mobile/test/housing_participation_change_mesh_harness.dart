import 'dart:io';
import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/housing/participation/housing_inactive_participant_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/device_binding_test_support.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

final class _FakeContactNotificationSink implements ContactNotificationSink {
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

/// One simulated device in a three-participant relay mesh.
class ParticipationChangeMeshSide {
  ParticipationChangeMeshSide({
    required this.db,
    required this.dbFile,
    required this.orchestrator,
  });

  final AppDatabase db;
  final File dbFile;
  final HandshakeOrchestrator orchestrator;
}

/// Local contact ids after full mesh handshakes (Monica ↔ Louys ↔ Roberr).
class ParticipationChangeMeshContacts {
  const ParticipationChangeMeshContacts({
    required this.louysOnMonica,
    required this.roberrOnMonica,
    required this.monicaOnLouys,
    required this.roberrOnLouys,
    required this.monicaOnRoberr,
    required this.louysOnRoberr,
  });

  final String louysOnMonica;
  final String roberrOnMonica;
  final String monicaOnLouys;
  final String roberrOnLouys;
  final String monicaOnRoberr;
  final String louysOnRoberr;
}

/// Per-device plan ids for the same active three-participant agreement.
class ParticipationChangeMeshPlans {
  const ParticipationChangeMeshPlans({
    required this.authorPlanId,
    required this.louysPlanId,
    required this.roberrPlanId,
  });

  final String authorPlanId;
  final String louysPlanId;
  final String roberrPlanId;

  String planIdOn(ParticipationChangeMeshSide side, ParticipationChangeMeshContext ctx) {
    if (identical(side, ctx.monica)) return authorPlanId;
    if (identical(side, ctx.louys)) return louysPlanId;
    if (identical(side, ctx.roberr)) return roberrPlanId;
    throw ArgumentError('unknown side');
  }
}

/// Shared relay mesh for participation-change integration tests.
class ParticipationChangeMeshContext {
  ParticipationChangeMeshContext({
    required this.relay,
    required this.monica,
    required this.louys,
    required this.roberr,
    required this.contacts,
    required this.plans,
  });

  final FakeRelayClient relay;
  final ParticipationChangeMeshSide monica;
  final ParticipationChangeMeshSide louys;
  final ParticipationChangeMeshSide roberr;
  final ParticipationChangeMeshContacts contacts;
  final ParticipationChangeMeshPlans plans;

  Iterable<ParticipationChangeMeshSide> get allSides => [monica, louys, roberr];

  Future<void> pollAll() async {
    for (final side in allSides) {
      await side.orchestrator.pollSteadyStateInboxes();
    }
  }

  Future<void> dispose() async {
    for (final side in allSides) {
      side.orchestrator.stopPolling();
      await side.db.close();
      try {
        if (side.dbFile.existsSync()) side.dbFile.deleteSync();
      } catch (_) {}
    }
  }
}

int _relayDbFileSeq = 0;

Future<ParticipationChangeMeshSide> spawnParticipationChangeMeshSide({
  required FakeRelayClient relay,
  required Uint8List identitySeed,
}) async {
  final id = _relayDbFileSeq++;
  final dbFile = File(
    '${Directory.systemTemp.path}/housing_pc_mesh_$id.sqlite',
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
    deviceBinding: deviceBindingForTest(),
  );
  return ParticipationChangeMeshSide(
    db: db,
    dbFile: dbFile,
    orchestrator: orchestrator,
  );
}

Future<({String inviterContactId, String inviteeContactId})>
completeParticipationChangeMeshHandshake({
  required ParticipationChangeMeshSide inviter,
  required ParticipationChangeMeshSide invitee,
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

Future<ParticipationChangeMeshContext> setUpParticipationChangeMesh({
  String authorPlanId = 'housing:pc-mesh',
  String louysPlanId = 'received:pc-louys',
  String roberrPlanId = 'received:pc-roberr',
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final relay = FakeRelayClient();
  final monica = await spawnParticipationChangeMeshSide(
    relay: relay,
    identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 1 + i)),
  );
  final louys = await spawnParticipationChangeMeshSide(
    relay: relay,
    identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 51 + i)),
  );
  final roberr = await spawnParticipationChangeMeshSide(
    relay: relay,
    identitySeed: Uint8List.fromList(List<int>.generate(32, (i) => 101 + i)),
  );

  final monicaLouys = await completeParticipationChangeMeshHandshake(
    inviter: monica,
    invitee: louys,
    inviteeDisplayName: 'Louys',
    inviterDisplayName: 'Monica',
  );
  final monicaRoberr = await completeParticipationChangeMeshHandshake(
    inviter: monica,
    invitee: roberr,
    inviteeDisplayName: 'Roberr',
    inviterDisplayName: 'Monica',
  );
  final louysRoberr = await completeParticipationChangeMeshHandshake(
    inviter: louys,
    invitee: roberr,
    inviteeDisplayName: 'Roberr',
    inviterDisplayName: 'Louys',
  );

  final contacts = ParticipationChangeMeshContacts(
    louysOnMonica: monicaLouys.inviterContactId,
    roberrOnMonica: monicaRoberr.inviterContactId,
    monicaOnLouys: monicaLouys.inviteeContactId,
    roberrOnLouys: louysRoberr.inviterContactId,
    monicaOnRoberr: monicaRoberr.inviteeContactId,
    louysOnRoberr: louysRoberr.inviteeContactId,
  );

  final plans = ParticipationChangeMeshPlans(
    authorPlanId: authorPlanId,
    louysPlanId: louysPlanId,
    roberrPlanId: roberrPlanId,
  );

  await seedActiveThreeParticipantPlanOnAuthor(
    side: monica,
    planId: authorPlanId,
    louysContactId: contacts.louysOnMonica,
    roberrContactId: contacts.roberrOnMonica,
  );
  await seedActiveThreeParticipantReceivedPlan(
    side: louys,
    planId: louysPlanId,
    selfDisplayName: 'Louys',
    monicaContactId: contacts.monicaOnLouys,
    otherPeerDisplayName: 'Roberr',
    otherPeerContactId: contacts.roberrOnLouys,
  );
  await seedActiveThreeParticipantReceivedPlan(
    side: roberr,
    planId: roberrPlanId,
    selfDisplayName: 'Roberr',
    monicaContactId: contacts.monicaOnRoberr,
    otherPeerDisplayName: 'Louys',
    otherPeerContactId: contacts.louysOnRoberr,
  );

  return ParticipationChangeMeshContext(
    relay: relay,
    monica: monica,
    louys: louys,
    roberr: roberr,
    contacts: contacts,
    plans: plans,
  );
}

Future<void> seedActiveThreeParticipantPlanOnAuthor({
  required ParticipationChangeMeshSide side,
  required String planId,
  required String louysContactId,
  required String roberrContactId,
}) async {
  final now = DateTime.utc(2026, 6, 1);
  final db = side.db;
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
  await _seedSharedActiveAgreement(db: db, planId: planId, now: now);
  await HousingParticipationMembershipService(db).ensureMembershipsForPlan(planId);
}

Future<void> seedActiveThreeParticipantReceivedPlan({
  required ParticipationChangeMeshSide side,
  required String planId,
  required String selfDisplayName,
  required String monicaContactId,
  required String otherPeerDisplayName,
  required String otherPeerContactId,
}) async {
  final now = DateTime.utc(2026, 6, 1);
  final db = side.db;
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
      displayName: selfDisplayName,
      avatarId: 'mdi:self',
      createdAt: now,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p0',
      displayName: 'Monica',
      avatarId: 'mdi:monica',
      createdAt: now,
      contactId: drift.Value(monicaContactId),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p1',
      displayName: otherPeerDisplayName,
      avatarId: 'mdi:peer',
      createdAt: now,
      contactId: drift.Value(otherPeerContactId),
    ),
  );
  await _seedSharedActiveAgreement(db: db, planId: planId, now: now);
  await HousingParticipationMembershipService(db).ensureMembershipsForPlan(planId);
}

Future<void> _seedSharedActiveAgreement({
  required AppDatabase db,
  required String planId,
  required DateTime now,
}) async {
  const lineId = 'line:rent';
  const revisionId = 'rev:active';
  final packageId = 'pkg:$planId';

  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: now,
      periodEnd: now.add(const Duration(days: 180)),
      minNoticeDays: const drift.Value(0),
      penaltyMinor: const drift.Value(0),
      createdAt: now,
    ),
  );
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: lineId,
      planId: planId,
      isRecurring: true,
      title: 'Rent',
      currency: 'CAD',
      amountMinor: const drift.Value(90000),
      recurrenceDayOfMonth: const drift.Value(1),
      createdAt: now,
    ),
  );

  final participants = (await db.listParticipants())
      .where((p) => p.id.startsWith('$planId:'))
      .toList();
  final weights = [3333, 3333, 3334];
  for (var i = 0; i < participants.length; i++) {
    final p = participants[i];
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: '${lineId}_${p.id}',
        planId: planId,
        participantId: p.id,
        lineId: drift.Value(lineId),
        weight: weights[i],
        createdAt: now,
      ),
    );
  }

  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: packageId,
      planId: planId,
      activeRevisionId: const drift.Value(revisionId),
      createdAt: now,
    ),
  );
}

Future<String> lookupParticipantId({
  required AppDatabase db,
  required String planId,
  required String displayName,
}) async {
  final roster = (await db.listParticipants())
      .where((p) => p.id.startsWith('$planId:'))
      .toList();
  return roster.firstWhere((p) => p.displayName == displayName).id;
}

Future<void> expectChangeStatusOnAllSides({
  required ParticipationChangeMeshContext ctx,
  required String changeId,
  required HousingParticipationChangeStatus status,
}) async {
  for (final side in ctx.allSides) {
    final planId = ctx.plans.planIdOn(side, ctx);
    final row = await HousingParticipationChangeService(side.db).getById(changeId);
    expect(row, isNotNull, reason: 'change missing on $planId');
    expect(row!.status, status.wireValue, reason: 'status on $planId');
  }
}

Future<void> expectAllDeparted({
  required ParticipationChangeMeshContext ctx,
}) async {
  for (final side in ctx.allSides) {
    final planId = ctx.plans.planIdOn(side, ctx);
    final membership = HousingParticipationMembershipService(side.db);
    final roster = (await side.db.listParticipants())
        .where((p) => p.id.startsWith('$planId:'))
        .toList();
    for (final p in roster) {
      expect(
        await membership.isActiveMember(planId, p.id),
        isFalse,
        reason: '${p.displayName} still active on $planId',
      );
    }
  }
}

Future<void> expectParticipantDepartedOnAllSides({
  required ParticipationChangeMeshContext ctx,
  required String displayName,
  bool departed = true,
}) async {
  for (final side in ctx.allSides) {
    final planId = ctx.plans.planIdOn(side, ctx);
    final participantId = await lookupParticipantId(
      db: side.db,
      planId: planId,
      displayName: displayName,
    );
    final active = await HousingParticipationMembershipService(side.db)
        .isActiveMember(planId, participantId);
    expect(active, isNot(departed), reason: '$displayName on $planId');
  }
}

Future<void> expectInactiveParticipantOnAllSides({
  required ParticipationChangeMeshContext ctx,
  required String displayName,
}) async {
  for (final side in ctx.allSides) {
    final planId = ctx.plans.planIdOn(side, ctx);
    final sourceId = await lookupParticipantId(
      db: side.db,
      planId: planId,
      displayName: displayName,
    );
    final inactive = await HousingInactiveParticipantService(side.db).listUncleared(
      planId,
    );
    expect(
      inactive.any((row) => row.sourceParticipantId == sourceId),
      isTrue,
      reason: 'inactive row for $displayName on $planId',
    );
  }
}

Future<void> expectTwoWayRatioSplit({
  required ParticipationChangeMeshContext ctx,
  required String remainingA,
  required String remainingB,
}) async {
  for (final side in ctx.allSides) {
    final planId = ctx.plans.planIdOn(side, ctx);
    final idA = await lookupParticipantId(
      db: side.db,
      planId: planId,
      displayName: remainingA,
    );
    final idB = await lookupParticipantId(
      db: side.db,
      planId: planId,
      displayName: remainingB,
    );
    final ratios = await side.db.listPlanRatios(planId);
    expect(ratios.length, 2, reason: 'ratio count on $planId');
    final wA = ratios.firstWhere((r) => r.participantId == idA).weight;
    final wB = ratios.firstWhere((r) => r.participantId == idB).weight;
    expect(wA + wB, 10000, reason: 'weights on $planId');
    expect((wA - wB).abs(), lessThanOrEqualTo(1), reason: 'split on $planId');
  }
}
