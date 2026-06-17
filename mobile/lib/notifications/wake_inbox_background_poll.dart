import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../contacts/contact_invitations_repository.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../relay/handshake_orchestrator.dart';
import '../relay/identity_keystore.dart';
import '../relay/relay_client.dart';

/// Runs one relay poll pass using a short-lived [HandshakeOrchestrator] that is
/// **not** installed as [HandshakeOrchestrator.instance].
///
/// Intended for the FCM background isolate when the main isolate may be
/// stopped. Opens its own [AppDatabase] against the on-disk file used by the
/// app (same path as the foreground binding).
Future<void> runWakeInboxPollOnce() async {
  if (kIsWeb) return;

  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromDartDefines();
  if (config.apiBaseUrl.host == 'example.invalid') return;

  final appDb = AppDatabase();
  try {
    final identity = IdentityKeystore.secureStorage();
    final relay = HttpRelayClient(baseUrl: config.apiBaseUrl);
    final orchestrator = HandshakeOrchestrator(
      db: appDb,
      identity: identity,
      relay: relay,
      contacts: ContactsRepository(appDb),
      invitations: ContactInvitationsRepository(appDb),
    );
    await orchestrator.processAllPendingHandshakes();
    await orchestrator.pollSteadyStateInboxes();
    await orchestrator.pollHousingPaymentReminders();
    relay.close();
  } catch (e, st) {
    debugPrint('runWakeInboxPollOnce failed: $e\n$st');
  } finally {
    await appDb.close();
  }
}
