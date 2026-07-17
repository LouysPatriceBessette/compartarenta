import 'dart:convert';

import 'package:compartarenta/housing/proposals/housing_activation_notification_service.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

void main() {
  test('maybeNotifyAgreementActivated dedupes by revisionId', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final db = _DbForTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final svc = HousingActivationNotificationService(db);

    expect(await svc.alreadyNotified('rev:1'), isFalse);
    await svc.markNotified('rev:1');
    expect(await svc.alreadyNotified('rev:1'), isTrue);
    expect(await svc.alreadyNotified('rev:2'), isFalse);
  });

  test('maybeNotifyAgreementActivated skips in-force amendments', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final db = _DbForTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:plan-a';
    const packageId = 'pkg:$planId';
    const revisionId = 'rev:amend-1';
    final now = DateTime.utc(2026, 7, 17);
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: packageId,
            planId: planId,
            createdAt: now,
          ),
        );
    await db.into(db.proposalRevisions).insert(
          ProposalRevisionsCompanion.insert(
            id: revisionId,
            packageId: packageId,
            contentHash: 'hash',
            proposerParticipantId: '$planId:self',
            payloadJson: jsonEncode({
              'amendmentType': 'line_add',
              'lifecycleState': 'open',
            }),
            createdAt: now,
          ),
        );

    // Amendment detection runs before process-scope / OS notify gates.
    final svc = HousingActivationNotificationService(db);
    await svc.maybeNotifyAgreementActivated(
      planId: planId,
      revisionId: revisionId,
      packageId: packageId,
    );
    expect(await svc.alreadyNotified(revisionId), isFalse);
  });
}
