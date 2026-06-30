/// Persisted when a session start records a known, unchanged meter without a photo.
const String kVehicleMeterPhotoKnownUnchangedSentinel =
    'sentinel:meter_known_unchanged';

bool isKnownUnchangedMeterPhotoPath(String path) =>
    path == kVehicleMeterPhotoKnownUnchangedSentinel;

bool meterReadingHasDisplayablePhoto(String photoPath) =>
    photoPath.isNotEmpty && !isKnownUnchangedMeterPhotoPath(photoPath);
