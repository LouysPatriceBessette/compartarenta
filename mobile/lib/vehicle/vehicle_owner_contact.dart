/// Stable contact id for the local user as vehicle Propriétaire.
const String kVehicleOwnerSelfContactId = 'vehicle:owner:self';

bool vehicleContactIsOwnerSelf(String contactId) =>
    contactId == kVehicleOwnerSelfContactId;
