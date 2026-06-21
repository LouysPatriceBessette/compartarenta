import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../contacts/contact_invitations_repository.dart';
import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import '../relay/identity_keystore.dart';
import '../relay/relay_client.dart';
import 'closed_app_push_registration_service.dart';

/// Background isolate: refresh routing push registration after a wake poll.
@pragma('vm:entry-point')
Future<void> runClosedAppPushRegistrationRefreshOnce() async {
  if (kIsWeb) return;
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromDartDefines();
  if (config.apiBaseUrl.host == 'example.invalid') return;

  final prefs = await AppPreferences.load();
  if (!prefs.notificationsEnabled || !prefs.hasWakeEligibleCategoryEnabled) {
    return;
  }

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
    HandshakeOrchestrator.install(orchestrator);
    ClosedAppPushRegistrationService.install(relay: relay, prefs: prefs);
    await ClosedAppPushRegistrationService.maybeInstance?.sync(force: true);
    relay.close();
  } catch (e, st) {
    debugPrint('runClosedAppPushRegistrationRefreshOnce failed: $e\n$st');
  } finally {
    await appDb.close();
  }
}
