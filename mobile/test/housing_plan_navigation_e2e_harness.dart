import 'dart:typed_data';

import 'package:compartarenta/config/app_config.dart';
import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/app_root_navigator.dart';
import 'package:compartarenta/housing/housing_navigation_intent.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/device_binding_test_support.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/routing.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared DB + relay stack for housing navigation widget E2E tests.
class HousingPlanNavigationE2EContext {
  HousingPlanNavigationE2EContext({
    required this.db,
    required this.orchestrator,
    required this.config,
    required this.planId,
    required this.coContactId,
  });

  final AppDatabase db;
  final HandshakeOrchestrator orchestrator;
  final AppConfig config;
  final String planId;
  final String coContactId;
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
  Future<void> contactDisconnected({required String displayName}) async {}

  @override
  Future<void> planPeerEstablishmentRequestReceived({
    required String requesterDisplayName,
    required String proposerDisplayName,
    required String planId,
  }) async {}
}

/// Seeds [planId] with two participants, one recurring expense (100% split),
/// and a connected co-participant contact so proposal send can reach the relay.
Future<HousingPlanNavigationE2EContext> setUpHousingPlanNavigationE2E({
  String planId = 'housing:default',
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  SharedPreferences.setMockInitialValues({
    'onboarding.complete': true,
    'profile.displayName': 'Tester',
    'profile.avatarId': 'mdi:0',
    'prefs.currency': 'CAD',
    'prefs.dateFormat': 'yyyy-MM-dd',
    'prefs.distanceUnit': 'km',
    'plans.enabled': <String>['housing'],
    'prefs.languageCode': 'en',
    'notifications.enabled': true,
    'notifications.housing.decisionChange': true,
    'notifications.housing.offerExpiration': true,
    'housing.defaultPlanSummaryReached': true,
  });

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  AppDatabase.bindProcessScope(db);

  const coContactId = 'contact:e2e:co';
  final peerIdentity = InMemoryIdentityKeystore(
    seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 2)),
  );
  final peerPubB64 = RelayRouting.b64(await peerIdentity.publicKey());
  final now = DateTime.utc(2026, 5, 1);

  await db.upsertContact(
    ContactsCompanion.insert(
      id: coContactId,
      kind: 'connected',
      displayName: 'Co participant',
      avatarId: 'mdi:1',
      relayRoutingId: const drift.Value('contact:e2e:co:route'),
      peerPublicMaterial: drift.Value(peerPubB64),
      createdAt: now,
      updatedAt: now,
    ),
  );

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: now,
      title: const drift.Value('Housing E2E'),
      currency: const drift.Value('CAD'),
      notes: const drift.Value.absent(),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:self',
      displayName: 'Tester',
      avatarId: 'mdi:0',
      createdAt: now,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: '$planId:p0',
      displayName: 'Co participant',
      avatarId: 'mdi:1',
      createdAt: now,
      contactId: const drift.Value(coContactId),
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: now,
      periodEnd: now.add(const Duration(days: 180)),
      minNoticeDays: const drift.Value(30),
      penaltyMinor: const drift.Value(0),
      createdAt: now,
    ),
  );
  const lineId = 'line:e2e:rent';
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: lineId,
      planId: planId,
      isRecurring: true,
      title: 'Rent',
      currency: 'CAD',
      amountMinor: const drift.Value(100000),
      recurrenceDayOfMonth: const drift.Value(1),
      sortOrder: const drift.Value(0),
      createdAt: now,
    ),
  );
  for (final pid in ['$planId:self', '$planId:p0']) {
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$lineId:$pid',
        planId: planId,
        lineId: drift.Value(lineId),
        participantId: pid,
        weight: 5000,
        createdAt: now,
      ),
    );
  }

  final relay = FakeRelayClient();
  final identity = InMemoryIdentityKeystore(
    seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
  );
  final selfPub = await identity.publicKey();
  final peerPub = await peerIdentity.publicKey();
  final selfAddr = await RelayRouting.steadyStateAddress(
    firstPub: selfPub,
    secondPub: peerPub,
  );
  final peerAddr = await RelayRouting.steadyStateAddress(
    firstPub: peerPub,
    secondPub: selfPub,
  );
  await relay.establishRouting(
    selfIdentity: selfAddr,
    peerIdentity: peerAddr,
  );
  await relay.establishRouting(
    selfIdentity: peerAddr,
    peerIdentity: selfAddr,
  );
  final orchestrator = HandshakeOrchestrator(
    db: db,
    identity: identity,
    relay: relay,
    contacts: ContactsRepository(db),
    invitations: ContactInvitationsRepository(db),
    contactNotifications: _FakeContactNotificationSink(),
    pollInterval: const Duration(days: 1),
    deviceBinding: deviceBindingForTest(),
  );
  HandshakeOrchestrator.installForTesting(orchestrator);

  final config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: Uri.parse('https://example.invalid'),
  );

  return HousingPlanNavigationE2EContext(
    db: db,
    orchestrator: orchestrator,
    config: config,
    planId: planId,
    coContactId: coContactId,
  );
}

Future<void> tearDownHousingPlanNavigationE2E(
  HousingPlanNavigationE2EContext ctx,
) async {
  ctx.orchestrator.stopPolling();
  ctx.orchestrator.dispose();
  HandshakeOrchestrator.clearInstalledInstanceAfterDevDatabaseReset();
  await ctx.db.close();
  AppDatabase.clearProcessScopeIfReferencing(ctx.db);
}

Future<String> pendingRevisionIdForPlan(
  HousingPlanNavigationE2EContext ctx,
) async {
  final id = await HousingProposalTransportService(
    ctx.db,
  ).pendingRevisionIdForPlan(ctx.planId);
  if (id == null || id.isEmpty) {
    throw StateError('Expected pending revision on ${ctx.planId}');
  }
  return id;
}

Future<void> simulateProposalAccepted(
  HousingPlanNavigationE2EContext ctx,
) async {
  final revisionId = await pendingRevisionIdForPlan(ctx);
  final svc = PlanAgreementProposalService(ctx.db);
  await svc.recordResponse(
    revisionId: revisionId,
    participantId: '${ctx.planId}:p0',
    status: ProposalResponseStatus.accepted,
  );
  final outcome = await svc.tryActivateIfUnanimous(
    planId: ctx.planId,
    revisionId: revisionId,
    participantIds: ['${ctx.planId}:self', '${ctx.planId}:p0'],
  );
  expect(outcome, ProposalActivationOutcome.activated);
}

Future<void> simulateProposalRejected(
  HousingPlanNavigationE2EContext ctx,
) async {
  final revisionId = await pendingRevisionIdForPlan(ctx);
  await HousingProposalTransportService(ctx.db).archiveInvalidatedProposal(
    planId: ctx.planId,
    revisionId: revisionId,
    status: ProposalResponseStatus.rejected,
    responderParticipantId: '${ctx.planId}:p0',
  );
}

void notifySteadyInboxTick(HousingPlanNavigationE2EContext ctx) {
  ctx.orchestrator.steadyStateInboxTick.value =
      ctx.orchestrator.steadyStateInboxTick.value + 1;
}

/// Creates a pending revision (when needed) and posts it through the fake relay,
/// matching a successful **Submit my plan** from the summary screen.
Future<void> ensurePendingProposalSubmitted(
  HousingPlanNavigationE2EContext ctx,
) async {
  var revisionId = await HousingProposalTransportService(
    ctx.db,
  ).pendingRevisionIdForPlan(ctx.planId);
  revisionId ??= await PlanAgreementProposalService(ctx.db)
      .createRevisionFromCurrentDraft(
        planId: ctx.planId,
        proposerParticipantId: '${ctx.planId}:self',
        responseExpiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      );
  final send = await ctx.orchestrator.sendHousingProposalToPlanParticipants(
    planId: ctx.planId,
    revisionId: revisionId,
  );
  expect(send.sentCount, greaterThan(0));
  final pending = await HousingProposalTransportService(
    ctx.db,
  ).pendingRevisionIdForPlan(ctx.planId);
  expect(pending, isNotNull);
}

/// Drives the same post-settlement navigation as [_SummaryView]: inbox reload
/// then remount [/housing] (hub or archive).
Future<void> applyProposalSettlementToUi(
  WidgetTester tester,
  HousingPlanNavigationE2EContext ctx,
) async {
  notifySteadyInboxTick(ctx);
  await tester.pumpAndSettle();
  final navContext = appRootNavigatorKey.currentContext;
  expect(navContext, isNotNull);
  HousingNavigationIntent.onProposalSettled(navContext!);
  await tester.pumpAndSettle();
}
