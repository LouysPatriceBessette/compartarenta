import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/export/export_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export is deterministic for same dataset', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final service = ExportService(db);

    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'p2',
        type: 'car',
        title: drift.Value('B'),
        currency: drift.Value('CAD'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );
    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'p1',
        type: 'housing',
        title: drift.Value('A'),
        currency: drift.Value('CAD'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'u1',
        displayName: 'User',
        avatarId: 'mdi:0',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );

    final a = await service.export();
    final b = await service.export();

    expect(a.toJson(), b.toJson());

    await db.close();
  });
}

