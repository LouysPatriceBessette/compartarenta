import 'dart:typed_data';

import 'package:compartarenta/contacts/contact_invitations_repository.dart';
import 'package:compartarenta/contacts/invitation_code.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/contacts_repository.dart';
import 'package:compartarenta/notifications/contact_notification_service.dart';
import 'package:compartarenta/notifications/push_notification_service.dart';
import 'package:compartarenta/relay/handshake_orchestrator.dart';
import 'package:compartarenta/relay/identity_keystore.dart';
import 'package:compartarenta/relay/testing/fake_relay_client.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/device_binding_test_support.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

final class _FakeContactNotificationSink implements ContactNotificationSink {
  final addRequests = <String>[];

  @override
  Future<void> contactAddRequestReceived({required String displayName}) async {
    addRequests.add(displayName);
  }

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

/// Task 10.4: wake poll path (same orchestrator calls as [runWakeInboxPollOnce])
/// surfaces the Contacts add-request notification when a hello is pending.
void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  test('wake poll path emits contact add request notification', () async {
    final relay = FakeRelayClient();
    final inviterDb = _DbForTesting(NativeDatabase.memory());
    final inviteeDb = _DbForTesting(NativeDatabase.memory());
    final notifications = _FakeContactNotificationSink();
    final inviter = HandshakeOrchestrator(
      db: inviterDb,
      identity: InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
      ),
      relay: relay,
      contacts: ContactsRepository(inviterDb),
      invitations: ContactInvitationsRepository(inviterDb),
      contactNotifications: notifications,
      pollInterval: const Duration(days: 1),
      deviceBinding: deviceBindingForTest('inviter'),
    );
    inviter.autoAcceptIncomingHandshakes = false;

    final invitee = HandshakeOrchestrator(
      db: inviteeDb,
      identity: InMemoryIdentityKeystore(
        seed: Uint8List.fromList(List<int>.generate(32, (i) => 100 + i)),
      ),
      relay: relay,
      contacts: ContactsRepository(inviteeDb),
      invitations: ContactInvitationsRepository(inviteeDb),
      pollInterval: const Duration(days: 1),
      deviceBinding: deviceBindingForTest('invitee'),
    );

    final invite = await inviter.generateInvitation(
      validFor: const Duration(hours: 1),
      stubDisplayName: 'pending peer',
      stubAvatarId: 'mdi:account',
    );
    final code =
        (parseInvitationCode(invite.shortCode) as InvitationCodeOk).code;
    await invitee.redeemInvitation(
      code: code,
      selfDisplayName: 'Invitee Name',
      selfAvatarId: 'mdi:invitee-avatar',
    );

    final wakeMsg = RemoteMessage(
      data: const {'kind': 'wake_for_inbox', 'v': '1'},
    );
    expect(PushNotificationService.isWakeForInboxRemoteMessage(wakeMsg), isTrue);

    await inviter.processAllPendingHandshakes();
    await inviter.pollSteadyStateInboxes();

    expect(notifications.addRequests, ['Invitee Name']);
    expect(inviter.incomingHandshakes.value, hasLength(1));

    await inviterDb.close();
    await inviteeDb.close();
  });
}
