import 'package:compartarenta/contacts/contact_duplicate_module_anchor.dart';
import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/db/repositories/vehicles_repository.dart';
import 'package:compartarenta/vehicle/vehicle_kind.dart';
import 'package:compartarenta/vehicle/vehicle_owner_contact.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _dbWithConnectedContact(String contactId) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.upsertContact(
    ContactsCompanion.insert(
      id: contactId,
      kind: 'connected',
      displayName: 'Peer',
      avatarId: 'a01',
      peerPublicMaterial: const drift.Value('peer-key'),
      relayRoutingId: const drift.Value('route'),
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
  return db;
}

void main() {
  test('detects active housing plan anchor', () async {
    const contactId = 'contact:peer';
    final db = await _dbWithConnectedContact(contactId);
    addTearDown(db.close);

    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'plan:h',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'plan:h:self',
        displayName: 'Self',
        avatarId: 'a01',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'plan:h:p1',
        displayName: 'Peer',
        avatarId: 'a01',
        contactId: const drift.Value(contactId),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agr:plan:h',
        planId: 'plan:h',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: 'pkg:plan:h',
        planId: 'plan:h',
        activeRevisionId: const drift.Value('rev:active'),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.proposalRevisions).insert(
      ProposalRevisionsCompanion.insert(
        id: 'rev:active',
        packageId: 'pkg:plan:h',
        contentHash: 'hash',
        proposerParticipantId: 'plan:h:self',
        payloadJson: '{"lifecycleState":"active"}',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(
      await detectContactDuplicateModuleAnchorKind(
        db,
        contactId,
        now: DateTime.utc(2026, 6, 1),
      ),
      DuplicateModuleAnchorKind.housing,
    );
  });

  test('detects active vehicle sharing as borrower', () async {
    const contactId = 'contact:borrower';
    final db = await _dbWithConnectedContact(contactId);
    addTearDown(db.close);

    const vehicleId = 'vehicle:test';
    await db.into(db.vehicles).insert(
      VehiclesCompanion.insert(
        id: vehicleId,
        ownerContactId: kVehicleOwnerSelfContactId,
        vehicleKind: VehicleKind.car.wire,
        displayLabel: 'Car',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.vehicleSharingLinks).insert(
      VehicleSharingLinksCompanion.insert(
        id: 'vshare:test',
        vehicleId: vehicleId,
        ownerContactId: kVehicleOwnerSelfContactId,
        borrowerContactId: contactId,
        status: VehicleSharingLinkStatus.active.wire,
        createdAt: DateTime.utc(2026, 1, 1),
        acceptedAt: drift.Value(DateTime.utc(2026, 1, 2)),
      ),
    );

    expect(
      await detectContactDuplicateModuleAnchorKind(db, contactId),
      DuplicateModuleAnchorKind.vehicle,
    );
  });
}
