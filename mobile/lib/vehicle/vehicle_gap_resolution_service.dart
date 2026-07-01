import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';
import '../vehicle/vehicle_consumption_estimation_mode.dart';
import '../vehicle/vehicle_gap_correction.dart';
import '../vehicle/vehicle_meter_reading_effective.dart';
import '../vehicle/vehicle_meter_photo_path.dart';
import '../vehicle/vehicle_owner_contact.dart';

/// One retroactive use session to insert when resolving a gap.
class GapMissingSessionSegment {
  const GapMissingSessionSegment({
    required this.attributedContactId,
    required this.startMeterTenths,
    required this.endMeterTenths,
    required this.startDate,
    required this.endDate,
  });

  final String attributedContactId;
  final int startMeterTenths;
  final int endMeterTenths;
  final DateTime startDate;
  final DateTime endDate;
}

class VehicleGapResolutionService {
  VehicleGapResolutionService(this._repo);

  final VehiclesRepository _repo;

  Future<VehicleOdometerGap?> gapForVerificationReading(String readingId) =>
      _repo.getOdometerGapByCorrectionReadingId(readingId);

  Future<void> correctMeterReading({
    required VehicleOdometerGap gap,
    required VehicleMeterReading verificationReading,
    required VehicleMeterReading readingToCorrect,
    required String previousReadingId,
    required String triggerReadingId,
    required int newMeterTenths,
    bool? isFullTank,
    int? tankFillFraction,
    required GapResolutionKind kind,
  }) async {
    await _assertMonotonicCorrection(
      vehicleId: gap.vehicleId,
      readingId: readingToCorrect.id,
      newMeterTenths: newMeterTenths,
    );
    final oldValue = readingToCorrect.value;
    await _repo.replaceMeterReading(
      superseded: readingToCorrect,
      newValue: newMeterTenths,
      isFullTank: isFullTank,
      tankFillFraction: tankFillFraction,
      kind: kind,
    );
    final kmApplied = (newMeterTenths - oldValue).abs();
    final attributedId = _participantForReading(readingToCorrect);
    await _finalizeResolution(
      gap: gap,
      verificationReading: verificationReading,
      kmAppliedTenths: kmApplied,
      attributedContactId: attributedId,
      kind: kind,
      previousReadingId: previousReadingId,
      triggerReadingId: triggerReadingId,
    );
  }

  Future<void> addMissingUseSessions({
    required Vehicle vehicle,
    required VehicleOdometerGap gap,
    required VehicleMeterReading verificationReading,
    required VehicleMeterReading previousReading,
    required VehicleMeterReading triggerReading,
    required List<GapMissingSessionSegment> segments,
  }) async {
    if (segments.isEmpty) {
      throw ArgumentError.value(segments, 'segments', 'must not be empty');
    }
    _assertSegmentsValid(gap: gap, segments: segments);

    final prevTank = _tankState(previousReading);
    final triggerTank = _tankState(triggerReading);
    final consumptionSegmentIndex = _consumptionSegmentIndex(segments);

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final consumesTank = i == consumptionSegmentIndex;
      final startTank = prevTank;
      final endTank = consumesTank ? triggerTank : startTank;

      final startReading = await _repo.saveMeterReading(
        vehicleId: vehicle.id,
        value: segment.startMeterTenths,
        unit: _repo.meterUnitForVehicle(vehicle),
        photoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
        recordedByContactId: segment.attributedContactId,
        role: MeterReadingRole.sessionStart,
        isFullTank: startTank.isFullTank,
        tankFillFraction: startTank.tankFillFraction,
        recordedAt: _dateToUtc(segment.startDate),
      );
      final endReading = await _repo.saveMeterReading(
        vehicleId: vehicle.id,
        value: segment.endMeterTenths,
        unit: _repo.meterUnitForVehicle(vehicle),
        photoPath: kVehicleMeterPhotoKnownUnchangedSentinel,
        recordedByContactId: segment.attributedContactId,
        role: MeterReadingRole.sessionEnd,
        isFullTank: endTank.isFullTank,
        tankFillFraction: endTank.tankFillFraction,
        recordedAt: _dateToUtc(segment.endDate),
      );
      final mix = await _repo.averageDetailedDrivingMixForContact(
        vehicleId: vehicle.id,
        contactId: segment.attributedContactId,
      );
      await _repo.insertRetroactiveClosedUseSession(
        vehicleId: vehicle.id,
        attributedContactId: segment.attributedContactId,
        startReadingId: startReading.id,
        endReadingId: endReading.id,
        startedAt: _dateToUtc(segment.startDate),
        endedAt: _dateToUtc(segment.endDate),
        drivingRoutePercent: mix?.route,
        drivingCityPercent: mix?.city,
        drivingTrafficPercent: mix?.traffic,
        sessionConsumptionMode: mix == null
            ? VehicleConsumptionEstimationMode.simple
            : VehicleConsumptionEstimationMode.detailed,
      );
    }

    final totalKm = gap.gapAmount.abs();
    final attributedId = segments.length == 1
        ? segments.first.attributedContactId
        : kVehicleOwnerSelfContactId;
    await _finalizeResolution(
      gap: gap,
      verificationReading: verificationReading,
      kmAppliedTenths: totalKm,
      attributedContactId: attributedId,
      kind: GapResolutionKind.addSessions,
      previousReadingId: previousReading.id,
      triggerReadingId: triggerReading.id,
      splitResolution: segments.length > 1,
    );
  }

  Future<void> _finalizeResolution({
    required VehicleOdometerGap gap,
    required VehicleMeterReading verificationReading,
    required int kmAppliedTenths,
    required String attributedContactId,
    required GapResolutionKind kind,
    required String previousReadingId,
    required String triggerReadingId,
    bool splitResolution = false,
  }) async {
    final vehicle = await _repo.getVehicle(gap.vehicleId);
    if (vehicle == null) {
      throw StateError('vehicle missing for gap resolution');
    }
    await _repo.markGapVerificationResolved(verificationReading.id);
    await _repo.deleteOdometerGap(gap.id);
    await _repo.saveAppliedGapCorrectionReading(
      vehicle: vehicle,
      kmAppliedTenths: kmAppliedTenths,
      attributedContactId: attributedContactId,
      previousReadingId: previousReadingId,
      triggerReadingId: triggerReadingId,
      kind: kind,
      splitResolution: splitResolution,
      recordedByContactId: kVehicleOwnerSelfContactId,
    );
    // TODO(vehicle-sharing §5.2): relay sync superseding correction to remote devices.
    // TODO(vehicle notifications): owner notification when borrower confirms gap.
  }

  Future<void> _assertMonotonicCorrection({
    required String vehicleId,
    required String readingId,
    required int newMeterTenths,
  }) async {
    final readings = await _repo.listMeterReadings(vehicleId);
    final ordered = effectiveMeterReadingsChronological(readings);
    final index = ordered.indexWhere((r) => r.id == readingId);
    if (index < 0) {
      // Superseded original: check against replacement chain position.
      final superseded = await _repo.getMeterReading(readingId);
      if (superseded == null) {
        throw StateError('reading not found for monotonicity check');
      }
      final replacement = readings.firstWhere(
        (r) => r.supersedesReadingId == readingId,
        orElse: () => superseded,
      );
      if (replacement.id == readingId) {
        throw StateError('reading not found for monotonicity check');
      }
      return _assertMonotonicCorrection(
        vehicleId: vehicleId,
        readingId: replacement.id,
        newMeterTenths: newMeterTenths,
      );
    }
    if (index > 0 && newMeterTenths < ordered[index - 1].value) {
      throw GapResolutionValidationException.monotonicity();
    }
    if (index < ordered.length - 1 &&
        newMeterTenths > ordered[index + 1].value) {
      throw GapResolutionValidationException.monotonicity();
    }
  }

  void _assertSegmentsValid({
    required VehicleOdometerGap gap,
    required List<GapMissingSessionSegment> segments,
  }) {
    final target = gap.gapAmount.abs();
    var sum = 0;
    for (final s in segments) {
      final delta = s.endMeterTenths - s.startMeterTenths;
      if (delta <= 0) {
        throw GapResolutionValidationException.segmentOdometer();
      }
      sum += delta;
    }
    if (sum != target) {
      throw GapResolutionValidationException.segmentSum();
    }
    for (var i = 0; i < segments.length; i++) {
      for (var j = i + 1; j < segments.length; j++) {
        if (_dateRangesOverlap(
          segments[i].startDate,
          segments[i].endDate,
          segments[j].startDate,
          segments[j].endDate,
        )) {
          throw GapResolutionValidationException.dateOverlap();
        }
      }
    }
    var cursor = segments.first.startMeterTenths;
    for (final s in segments) {
      if (s.startMeterTenths != cursor) {
        throw GapResolutionValidationException.segmentOdometer();
      }
      cursor = s.endMeterTenths;
    }
    if (cursor != segments.last.endMeterTenths) {
      throw GapResolutionValidationException.segmentOdometer();
    }
    final first = segments.first.startMeterTenths;
    final last = segments.last.endMeterTenths;
    if (first != gap.latestReadingBeforeGap ||
        last != gap.startReadingAfterGap) {
      throw GapResolutionValidationException.segmentOdometer();
    }
  }

  bool _dateRangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final aS = _dateOnly(aStart);
    final aE = _dateOnly(aEnd);
    final bS = _dateOnly(bStart);
    final bE = _dateOnly(bEnd);
    if (aE.isBefore(bS) || bE.isBefore(aS)) return false;
    if (aE == bS || bE == aS) return false;
    return true;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dateToUtc(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day, 12);

  int _consumptionSegmentIndex(List<GapMissingSessionSegment> segments) {
    if (segments.length == 1) return 0;
    var best = 0;
    var bestEnd = segments.first.endDate;
    for (var i = 1; i < segments.length; i++) {
      if (segments[i].endDate.isAfter(bestEnd)) {
        best = i;
        bestEnd = segments[i].endDate;
      }
    }
    return best;
  }

  ({bool? isFullTank, int? tankFillFraction}) _tankState(
    VehicleMeterReading reading,
  ) =>
      (isFullTank: reading.isFullTank, tankFillFraction: reading.tankFillFraction);

  String _participantForReading(VehicleMeterReading reading) {
    return reading.recordedByContactId;
  }
}

class GapResolutionValidationException implements Exception {
  GapResolutionValidationException(this.code);

  final GapResolutionValidationCode code;

  factory GapResolutionValidationException.monotonicity() =>
      GapResolutionValidationException(GapResolutionValidationCode.monotonicity);

  factory GapResolutionValidationException.segmentSum() =>
      GapResolutionValidationException(GapResolutionValidationCode.segmentSum);

  factory GapResolutionValidationException.segmentOdometer() =>
      GapResolutionValidationException(
        GapResolutionValidationCode.segmentOdometer,
      );

  factory GapResolutionValidationException.dateOverlap() =>
      GapResolutionValidationException(GapResolutionValidationCode.dateOverlap);
}

enum GapResolutionValidationCode {
  monotonicity,
  segmentSum,
  segmentOdometer,
  dateOverlap,
}
