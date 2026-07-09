import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import '../housing/contacts/housing_contact_disconnect_policy.dart';

/// Wire value on a rejected ack when the inviter blocks a device-binding
/// duplicate because the pre-existing contact anchors module work.
abstract final class AckRejectionReason {
  static const duplicateModuleAnchor = 'duplicate_module_anchor';
}

/// Which module anchor blocked merging the duplicate contact.
abstract final class DuplicateModuleAnchorKind {
  static const housing = 'housing';
  static const vehicle = 'vehicle';
  static const housingAndVehicle = 'housing_and_vehicle';
}

/// Returns the anchor kind blocking a duplicate merge, or null when merge is allowed.
Future<String?> detectContactDuplicateModuleAnchorKind(
  AppDatabase db,
  String existingContactId, {
  DateTime? now,
}) async {
  var hasHousing = false;
  var hasVehicle = false;

  final plans = await db.listPlansContainingContact(existingContactId);
  for (final plan in plans) {
    if (await housingInForceAgreementBlocksContactDisconnect(
      db: db,
      planId: plan.id,
      contactId: existingContactId,
      now: now,
    )) {
      hasHousing = true;
      break;
    }
  }

  final vehicleLinks = await VehiclesRepository(
    db,
  ).listActiveLinksAsBorrower(existingContactId);
  if (vehicleLinks.isNotEmpty) {
    hasVehicle = true;
  }

  if (hasHousing && hasVehicle) return DuplicateModuleAnchorKind.housingAndVehicle;
  if (hasHousing) return DuplicateModuleAnchorKind.housing;
  if (hasVehicle) return DuplicateModuleAnchorKind.vehicle;
  return null;
}
