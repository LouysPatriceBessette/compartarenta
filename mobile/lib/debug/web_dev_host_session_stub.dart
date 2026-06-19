import '../db/app_database.dart';
import 'web_dev_db_write_observer.dart' show devHostSessionSaveDeferDepth;

Future<void> restoreDevSessionFromHostIfNeeded(AppDatabase db) async {}

Future<void> saveDevHostSessionNow(AppDatabase db) async {}

void scheduleDevHostSessionSave(AppDatabase db) {}

Future<void> flushDevHostSessionSave(AppDatabase db) async {}

Future<T> runWithDeferredDevHostSessionSave<T>(
  AppDatabase db,
  Future<T> Function() action,
) async {
  devHostSessionSaveDeferDepth++;
  try {
    return await action();
  } finally {
    devHostSessionSaveDeferDepth--;
  }
}

Future<void> clearDevHostSessionAfterWipe() async {}

Future<void> wipeWebDevBrowserStorageOnLaunchIfRequested({
  required bool clearRelayIdentity,
}) async {}
