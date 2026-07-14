/// Versioned sale/transfer bundle (`vehicle-data-portability`).
abstract final class VehicleSaleBundle {
  static const formatVersion = 1;
  static const bundleKind = 'vehicle_sale';
  static const moduleId = 'vehicle';
}

enum VehicleSaleImportFailureKind {
  invalidBundle,
  corruptArchive,
  other,
}

class VehicleSaleImportException implements Exception {
  const VehicleSaleImportException(this.kind, [this.cause]);

  final VehicleSaleImportFailureKind kind;
  final Object? cause;

  @override
  String toString() => 'VehicleSaleImportException($kind, $cause)';
}

class VehicleSaleExportException implements Exception {
  const VehicleSaleExportException(this.message);

  final String message;

  @override
  String toString() => 'VehicleSaleExportException($message)';
}
