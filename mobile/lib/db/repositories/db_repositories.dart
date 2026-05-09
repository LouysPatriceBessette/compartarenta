import '../app_database.dart';
import 'package:drift/drift.dart' as drift;

class PlansRepository {
  PlansRepository(this._db);
  final AppDatabase _db;

  Future<void> upsert({
    required String id,
    required String type,
    required String title,
    required String currency,
    String? notes,
    required DateTime createdAt,
  }) {
    return _db.upsertPlan(
      PlansCompanion.insert(
        id: id,
        type: type,
        title: drift.Value(title),
        currency: drift.Value(currency),
        createdAt: createdAt,
        notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
      ),
    );
  }

  Future<List<Plan>> list() => _db.listPlans();
}

class ParticipantsRepository {
  ParticipantsRepository(this._db);
  final AppDatabase _db;

  Future<void> upsert({
    required String id,
    required String displayName,
    required String avatarId,
    required DateTime createdAt,
  }) {
    return _db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: id,
        displayName: displayName,
        avatarId: avatarId,
        createdAt: createdAt,
      ),
    );
  }

  Future<List<Participant>> list() => _db.listParticipants();
}

