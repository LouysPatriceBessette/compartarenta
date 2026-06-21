import 'package:workmanager/workmanager.dart';

import 'closed_app_push_background_sync.dart';

const _uniqueName = 'compartarenta.routingPushKeepAlive';

@pragma('vm:entry-point')
void closedAppPushWorkmanagerCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _uniqueName) {
      await runClosedAppPushRegistrationRefreshOnce();
    }
    return true;
  });
}

Future<void> scheduleClosedAppPushKeepAlive() async {
  await Workmanager().initialize(closedAppPushWorkmanagerCallback);
  await Workmanager().registerPeriodicTask(
    _uniqueName,
    _uniqueName,
    frequency: const Duration(hours: 12),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
