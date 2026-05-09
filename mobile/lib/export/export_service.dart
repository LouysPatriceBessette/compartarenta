import '../db/app_database.dart';
import 'export_bundle.dart';

class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  static const int currentFormatVersion = 1;

  Future<ExportBundle> export() async {
    final plans = await _db.listPlans();
    final participants = await _db.listParticipants();

    // Deterministic ordering (already ordered by id in queries, but keep explicit).
    plans.sort((a, b) => a.id.compareTo(b.id));
    participants.sort((a, b) => a.id.compareTo(b.id));

    return ExportBundle(
      formatVersion: currentFormatVersion,
      plans: plans
          .map(
            (p) => <String, Object?>{
              'id': p.id,
              'type': p.type,
              'title': p.title,
              'notes': p.notes,
              'createdAt': p.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      participants: participants
          .map(
            (u) => <String, Object?>{
              'id': u.id,
              'displayName': u.displayName,
              'avatarId': u.avatarId,
              'createdAt': u.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    );
  }
}

