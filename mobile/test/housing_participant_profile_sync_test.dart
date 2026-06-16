import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/housing_participant_profile_sync.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('syncParticipantRowsForContactProfile updates linked roster rows', () async {
    const contactId = 'contact:b';
    const planId = 'housing:draft';
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Old name',
        avatarId: 'a01',
        contactId: const drift.Value(contactId),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p1',
        displayName: 'Other',
        avatarId: 'a02',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await syncParticipantRowsForContactProfile(
      db: db,
      contactId: contactId,
      displayName: 'New name',
      avatarId: 'a03',
    );

    final updated = await (db.select(db.participants)
          ..where((t) => t.id.equals('$planId:p0')))
        .getSingle();
    expect(updated.displayName, 'New name');
    expect(updated.avatarId, 'a03');

    final untouched = await (db.select(db.participants)
          ..where((t) => t.id.equals('$planId:p1')))
        .getSingle();
    expect(untouched.displayName, 'Other');
  });

  test('syncSelfParticipantRowsForProfile updates every self row', () async {
    for (final planId in ['housing:a', 'received:xyz']) {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$planId:self',
          displayName: 'Before',
          avatarId: 'a01',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }

    await syncSelfParticipantRowsForProfile(
      db: db,
      displayName: 'After',
      avatarId: 'a09',
    );

    final rows = await db.listParticipants();
    for (final row in rows.where((p) => p.id.endsWith(':self'))) {
      expect(row.displayName, 'After');
      expect(row.avatarId, 'a09');
    }
  });
}
