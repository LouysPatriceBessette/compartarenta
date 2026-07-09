import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../relay/identity_keystore.dart';
import '../relay/routing.dart';
import 'qa_scenario_seed_helpers.dart';

/// Stable plan id for the FCM wake manual QA scenario.
const kQaFcmWakePlanId = 'housing:qa-fcm-wake';

const kQaFcmWakeLouysContactId = 'contact:qa:fcm:louys';
const kQaFcmWakeMonicaContactId = 'contact:qa:fcm:monica';

/// Fixed X25519 seeds (debug QA only) so Monica-QA and Louys-QA emulators/phones
/// share predictable long-term keys after [pm clear] + seed.
final kQaFcmWakeMonicaPrivateKeySeed = Uint8List.fromList(
  List<int>.generate(32, (i) => 0x10 + i),
);
final kQaFcmWakeLouysPrivateKeySeed = Uint8List.fromList(
  List<int>.generate(32, (i) => 0x20 + i),
);

Future<String> qaFcmWakePublicKeyB64ForSeed(Uint8List seed) async {
  final algo = Cryptography.instance.x25519();
  final pair = await algo.newKeyPairFromSeed(seed);
  final pub = await pair.extractPublicKey();
  return RelayRouting.b64(Uint8List.fromList(pub.bytes));
}

Future<void> qaRestoreFcmWakeIdentity(Uint8List seed) async {
  final store = IdentityKeystore.secureStorage();
  await store.deleteForTesting();
  final b64 = base64Url.encode(seed).replaceAll('=', '');
  await store.restorePrivateKeyB64ForDev(b64);
}

Future<void> qaSeedFcmWakeConnectedContact({
  required AppDatabase db,
  required String contactId,
  required String displayName,
  required String avatarId,
  required String peerPublicMaterialB64,
  required DateTime now,
}) async {
  await db.upsertContact(
    ContactsCompanion.insert(
      id: contactId,
      kind: 'connected',
      displayName: displayName,
      avatarId: avatarId,
      peerPublicMaterial: drift.Value(peerPublicMaterialB64),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

/// Monica (proposer): connected Louys + housing draft ready to submit.
Future<void> seedQaFcmWakePushProposer(AppDatabase db) async {
  final now = kQaSeedCreatedAt;
  await qaRestoreFcmWakeIdentity(kQaFcmWakeMonicaPrivateKeySeed);
  final louysPubB64 = await qaFcmWakePublicKeyB64ForSeed(kQaFcmWakeLouysPrivateKeySeed);
  await qaSeedFcmWakeConnectedContact(
    db: db,
    contactId: kQaFcmWakeLouysContactId,
    displayName: 'Louys QA',
    avatarId: 'a02',
    peerPublicMaterialB64: louysPubB64,
    now: now,
  );
  await seedQaFcmWakeHousingDraft(
    db: db,
    planId: kQaFcmWakePlanId,
    coContactId: kQaFcmWakeLouysContactId,
  );
}

/// Louys (recipient): connected Monica only — wake delivery target.
Future<void> seedQaFcmWakePushRecipient(AppDatabase db) async {
  final now = kQaSeedCreatedAt;
  await qaRestoreFcmWakeIdentity(kQaFcmWakeLouysPrivateKeySeed);
  final monicaPubB64 = await qaFcmWakePublicKeyB64ForSeed(kQaFcmWakeMonicaPrivateKeySeed);
  await qaSeedFcmWakeConnectedContact(
    db: db,
    contactId: kQaFcmWakeMonicaContactId,
    displayName: 'Monica QA',
    avatarId: 'a01',
    peerPublicMaterialB64: monicaPubB64,
    now: now,
  );
}

/// Orphan draft with one expense and 50/50 split — wizard opens on summary.
Future<void> seedQaFcmWakeHousingDraft({
  required AppDatabase db,
  required String planId,
  required String coContactId,
}) async {
  final createdAt = kQaSeedCreatedAt;
  final periodStart = kQaAnchorPeriodStart;
  final periodEnd = kQaAnchorPeriodEnd;
  final selfId = '$planId:self';
  final coId = '$planId:p0';
  const lineId = 'line:qa-fcm-wake:rent';

  await db.upsertPlan(
    PlansCompanion.insert(
      id: planId,
      type: 'housing',
      createdAt: createdAt,
      title: const drift.Value('Plan QA FCM wake'),
      currency: const drift.Value('CAD'),
      notes: const drift.Value.absent(),
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: selfId,
      displayName: 'Monica QA',
      avatarId: 'a01',
      createdAt: createdAt,
    ),
  );
  await db.upsertParticipant(
    ParticipantsCompanion.insert(
      id: coId,
      displayName: 'Louys QA',
      avatarId: 'a02',
      contactId: drift.Value(coContactId),
      createdAt: createdAt,
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agreement:$planId',
      planId: planId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      minNoticeDays: const drift.Value(30),
      penaltyMinor: const drift.Value(0),
      clauses: const drift.Value(''),
      withdrawalSameForAll: const drift.Value('true'),
      withdrawalPerParticipantJson: const drift.Value('{}'),
      agreementRulesJson: const drift.Value('{}'),
      version: const drift.Value(1),
      createdAt: createdAt,
    ),
  );
  await db.upsertPlanLine(
    PlanLinesCompanion.insert(
      id: lineId,
      planId: planId,
      isRecurring: true,
      title: 'Loyer',
      currency: 'CAD',
      amountMinor: const drift.Value(100000),
      recurrenceDayOfMonth: const drift.Value(1),
      sortOrder: const drift.Value(0),
      createdAt: createdAt,
    ),
  );
  for (final pid in [selfId, coId]) {
    await db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$lineId:$pid',
        planId: planId,
        lineId: drift.Value(lineId),
        participantId: pid,
        weight: 5000,
        createdAt: createdAt,
      ),
    );
  }
}
