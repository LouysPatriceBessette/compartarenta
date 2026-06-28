import 'package:drift/drift.dart';

class Vehicles extends Table {
  TextColumn get id => text()();
  TextColumn get ownerContactId => text()();
  TextColumn get vehicleKind => text()();
  TextColumn get displayLabel => text()();
  TextColumn get make => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class VehicleMeterReadings extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  IntColumn get value => integer()();
  TextColumn get unit => text()();
  TextColumn get photoPath => text()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get recordedByContactId => text()();
  TextColumn get vehicleUseId => text().nullable()();
  TextColumn get readingRole => text()();
  BoolColumn get isCorrection =>
      boolean().withDefault(const Constant(false))();
  TextColumn get correctionNote =>
      text().withDefault(const Constant(''))();
  BoolColumn get negativeGapAcknowledged =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class VehicleUses extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get attributedContactId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get startReadingId => text()();
  TextColumn get endReadingId => text().nullable()();
  IntColumn get usageAmount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class VehicleOdometerGaps extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  IntColumn get latestReadingBeforeGap => integer()();
  IntColumn get startReadingAfterGap => integer()();
  IntColumn get gapAmount => integer()();
  TextColumn get attributedContactId => text()();
  TextColumn get recordedByContactId => text()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get vehicleUseId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class FuelPurchases extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  DateTimeColumn get purchasedAt => dateTime()();
  IntColumn get costMinor => integer()();
  TextColumn get currency => text()();
  RealColumn get volumeLiters => real().nullable()();
  IntColumn get meterReadingValue => integer().nullable()();
  TextColumn get meterPhotoPath => text().nullable()();
  BoolColumn get isFullTank => boolean()();
  TextColumn get recordedByContactId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class MaintenanceEvents extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  DateTimeColumn get servicedAt => dateTime()();
  TextColumn get category => text()();
  IntColumn get costMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get attachmentPath => text().nullable()();
  IntColumn get meterAtService => integer().nullable()();
  TextColumn get recordedByContactId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class VehicleMaintenanceRules extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get category => text()();
  IntColumn get intervalAmount => integer()();
  IntColumn get previewWindowAmount =>
      integer().withDefault(const Constant(500))();

  @override
  Set<Column> get primaryKey => {id};
}

class TrafficViolations extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  DateTimeColumn get violatedAt => dateTime()();
  TextColumn get violationType => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get responsibilityContactId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get recordedByContactId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class VehicleSharingLinks extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get ownerContactId => text()();
  TextColumn get borrowerContactId => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
