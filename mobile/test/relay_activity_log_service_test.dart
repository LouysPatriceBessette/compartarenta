import 'package:compartarenta/activity/relay_activity_log_service.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('matchesEmitterFilter distinguishes system, self, and contact', () async {
    final service = RelayActivityLogService(db);
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorSystem,
    );
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorSelf,
      initiatorDisplayName: 'Alice',
    );
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorContact,
      initiatorContactId: 'c1',
      initiatorDisplayName: 'Bob',
    );

    final rows = await db.select(db.relayActivityLogEntries).get();
    final system = rows.firstWhere(
      (r) => r.initiatorKind == RelayActivityLogService.initiatorSystem,
    );
    final self = rows.firstWhere(
      (r) => r.initiatorKind == RelayActivityLogService.initiatorSelf,
    );
    final contact = rows.firstWhere((r) => r.initiatorContactId == 'c1');

    expect(
      RelayActivityLogService.matchesEmitterFilter(
        system,
        RelayActivityLogService.emitterFilterSystem,
      ),
      isTrue,
    );
    expect(
      RelayActivityLogService.matchesEmitterFilter(
        self,
        RelayActivityLogService.emitterFilterSelf,
      ),
      isTrue,
    );
    expect(
      RelayActivityLogService.matchesEmitterFilter(
        contact,
        RelayActivityLogService.emitterFilterContact('c1'),
      ),
      isTrue,
    );
    expect(
      RelayActivityLogService.matchesEmitterFilter(
        contact,
        RelayActivityLogService.emitterFilterSystem,
      ),
      isFalse,
    );
  });

  test('emitterFilterOptions lists system, self name, and contacts', () async {
    final service = RelayActivityLogService(db);
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorSystem,
    );
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorSelf,
      initiatorDisplayName: 'Alice',
    );
    await service.append(
      kind: 'test',
      initiatorKind: RelayActivityLogService.initiatorContact,
      initiatorContactId: 'c1',
      initiatorDisplayName: 'Bob',
    );

    final options = await service.emitterFilterOptions(
      selfDisplayName: 'Alice',
      allLabel: 'All',
      systemLabel: 'System',
      selfFallbackLabel: 'Me',
    );

    expect(options.first.key, RelayActivityLogService.emitterFilterAll);
    expect(
      options.map((o) => o.label),
      containsAll(['All', 'System', 'Alice', 'Bob']),
    );
  });
}
