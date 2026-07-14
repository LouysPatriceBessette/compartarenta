## ADDED Requirements

### Requirement: All user-captured images live under public Documents
Any image captured or chosen by the user through the app (camera or gallery) and **persisted** as product data MUST be written under the user-visible tree:

```
Documents/Compartarenta/
```

On Android this MUST use the existing public-documents channel (`writePublicDocumentBytes` / MediaStore `RELATIVE_PATH`), not the app-private `getApplicationDocumentsDirectory()` tree.

Implementation MUST NOT leave durable user media only in app-private storage.

#### Scenario: Odometer photo is user-visible after save
- **WHEN** a meter reading photo is saved for vehicle `V123`
- **THEN** the file is stored under `Documents/Compartarenta/Car/V123/Odometer/`
- **THEN** the user can browse and delete that file with the device file manager

#### Scenario: Vehicle gallery photo is user-visible after save
- **WHEN** a gallery photo is saved for vehicle `V123` in gallery index `2`
- **THEN** the file is stored under `Documents/Compartarenta/Car/V123/Gallery_002/`

#### Scenario: Housing expense proof is user-visible after save
- **WHEN** a realized expense proof image is persisted for an agreement period
- **THEN** the file is stored under `Documents/Compartarenta/Housing/<period>/ExpenseProofs/`

### Requirement: Canonical folder layout
Module roots under `Documents/Compartarenta/` MUST follow `CompartarentaDocumentsLayout`:

| Module | Relative path pattern | Content |
| --- | --- | --- |
| Backups | `Compartarenta/Backups/` | JSON export files (not images) |
| Housing | `Compartarenta/Housing/<start>_<end>/ExpenseProofs/` | Expense proof images |
| Vehicle | `Compartarenta/Car/<vehicleId>/Odometer/` | Odometer / horometer photos |
| Vehicle | `Compartarenta/Car/<vehicleId>/Gallery_<nnn>/` | Vehicle condition gallery photos |

Future modules (e.g. `Car_sharing`) MUST add a named subfolder under `Compartarenta/` before writing user media.

#### Scenario: New module adds a folder before first write
- **WHEN** a new feature persists a user-captured image
- **THEN** it declares a `Compartarenta/<Module>/…` path in `CompartarentaDocumentsLayout` (or successor)
- **THEN** it writes through the public-documents API

### Requirement: Timestamp file names for vehicle media
Vehicle odometer and gallery image file names MUST use local timestamp format:

```
YYYY-MM-DD_HH-MM-SS.<extension>
```

Collision handling MUST append a numeric suffix or wait one second; silent overwrite of an existing file name is forbidden.

#### Scenario: Two photos in the same second
- **WHEN** two photos are saved in the same second under the same folder
- **THEN** the second file name differs (suffix or next second) so both files remain

### Requirement: No durable private copies of user media
The app MUST NOT copy user media to app-private paths such as `app_flutter/vehicle_meter_photos/` for long-term storage.

Pre-save staging (image picker cache, in-memory crop buffers) is allowed only until the public write completes or the user cancels.

Legacy private paths MAY remain readable as a defensive fallback, but **no migration job is required**: the app is still early pre-release and has never shipped user data that would need rewriting from `vehicle_meter_photos/` into public storage. New writes MUST NOT target private paths after this spec is implemented.

#### Scenario: Legacy private odometer folder is not written on new save
- **WHEN** a user saves a new odometer photo on a build that implements this spec
- **THEN** no new file appears under app-private `vehicle_meter_photos/`
- **THEN** the file appears under `Documents/Compartarenta/Car/<vehicleId>/Odometer/`

### Requirement: Database stores public storage keys
Persisted photo references in the local database MUST store the public `storageKey` returned by `writePublicDocumentBytes` (e.g. Android `content://…` URI), not a relative app-private path.

#### Scenario: Reading a saved vehicle photo
- **WHEN** the app displays a meter reading photo saved after this spec
- **THEN** it loads bytes via `readPublicDocumentBytes(storageKey)`
