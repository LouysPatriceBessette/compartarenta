import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/renewal/housing_renewal_fork_availability.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hubRenewalForkAvailable', () {
    test('is false while agreement period is open', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      const planId = 'housing:open';
      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026),
        ),
      );
      await db.upsertAgreement(
        AgreementsCompanion.insert(
          id: 'agr:open',
          planId: planId,
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 12, 31),
          minNoticeDays: const drift.Value(0),
          penaltyMinor: const drift.Value(0),
          clauses: const drift.Value(''),
          withdrawalSameForAll: const drift.Value('true'),
          withdrawalPerParticipantJson: const drift.Value('{}'),
          agreementRulesJson: const drift.Value('{}'),
          version: const drift.Value(1),
          createdAt: DateTime.utc(2026),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:open',
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026),
        ),
      );

      expect(await hubRenewalForkAvailable(db, planId), isFalse);
    });

    test('is true after period end with active revision', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      const planId = 'housing:ended';
      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026),
        ),
      );
      await db.upsertAgreement(
        AgreementsCompanion.insert(
          id: 'agr:ended',
          planId: planId,
          periodStart: DateTime.utc(2025, 1, 1),
          periodEnd: DateTime.utc(2025, 12, 31),
          minNoticeDays: const drift.Value(0),
          penaltyMinor: const drift.Value(0),
          clauses: const drift.Value(''),
          withdrawalSameForAll: const drift.Value('true'),
          withdrawalPerParticipantJson: const drift.Value('{}'),
          agreementRulesJson: const drift.Value('{}'),
          version: const drift.Value(1),
          createdAt: DateTime.utc(2025),
        ),
      );
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:ended',
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2025),
        ),
      );

      expect(await hubRenewalForkAvailable(db, planId), isTrue);
    });
  });
}
