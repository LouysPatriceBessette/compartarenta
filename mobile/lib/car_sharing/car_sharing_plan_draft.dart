import 'dart:convert';

import '../housing/agreement_rules_json.dart';
import '../housing/quiet_hours_week_grid.dart';

/// Local draft for the car-sharing setup wizard (not yet synced to a domain DB).
class CarSharingPlanDraft {
  CarSharingPlanDraft({
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.vehicleColor = '',
    this.vehicleYear = '',
    this.ownerDisplayName = '',
    this.ownerIsRental = false,
    this.rentalSharePermissionFromLessor = false,
    this.rentalContractCopyOnAcceptance = false,
    this.insuranceNotifyOnAcceptance = false,
    this.insuranceAssumePremiumIncrease = false,
    this.insuranceProvideDocsOnAcceptance = false,
    this.estimatedValueMinor = 0,
    this.photoFrontPath = '',
    this.photoLeftPath = '',
    this.photoRightPath = '',
    this.photoRearPath = '',
    this.photoSeatsFrontPath = '',
    this.photoSeatsRearPath = '',
    this.photoDashboardPath = '',
    this.photoOdometerPath = '',
    List<CarSharingCoParticipantDraft>? coParticipants,
    List<CarSharingMaintenanceLineDraft>? maintenanceLines,
    List<List<int>>? availabilityHalfHours,
    this.useAppFuelTracking = true,
    this.customFuelPolicyText = '',
    AgreementRulesDraft? rulesDraft,
  })  : coParticipants = List<CarSharingCoParticipantDraft>.from(
          (coParticipants != null && coParticipants.isNotEmpty)
              ? coParticipants
              : [CarSharingCoParticipantDraft()],
        ),
        maintenanceLines = List<CarSharingMaintenanceLineDraft>.from(maintenanceLines ?? const []),
        availabilityHalfHours = availabilityHalfHours == null
            ? quietHoursEmptyGrid()
            : _normalizeAvailability(availabilityHalfHours),
        clauseRules = rulesDraft ??
            AgreementRulesDraft(
              curfewEnabled: false,
              earlyWithdrawalEnabled: false,
              buildingRulesEnabled: false,
            );

  String vehicleMake;
  String vehicleModel;
  String vehicleColor;
  String vehicleYear;
  String ownerDisplayName;
  bool ownerIsRental;
  bool rentalSharePermissionFromLessor;
  bool rentalContractCopyOnAcceptance;
  bool insuranceNotifyOnAcceptance;
  bool insuranceAssumePremiumIncrease;
  bool insuranceProvideDocsOnAcceptance;
  int estimatedValueMinor;
  String photoFrontPath;
  String photoLeftPath;
  String photoRightPath;
  String photoRearPath;
  String photoSeatsFrontPath;
  String photoSeatsRearPath;
  String photoDashboardPath;
  String photoOdometerPath;
  /// Placeholder co-sharers (excluding the owner profile); persisted in the draft JSON.
  final List<CarSharingCoParticipantDraft> coParticipants;
  final List<CarSharingMaintenanceLineDraft> maintenanceLines;
  /// Same shape as quiet-hours grid: 0 = owner-only, 1 = offered to co-sharers.
  List<List<int>> availabilityHalfHours;
  bool useAppFuelTracking;
  String customFuelPolicyText;
  AgreementRulesDraft clauseRules;

  static List<List<int>> _normalizeAvailability(List<List<int>> raw) {
    final g = quietHoursEmptyGrid();
    for (var d = 0; d < kQuietHoursDays && d < raw.length; d++) {
      final row = raw[d];
      for (var s = 0; s < kQuietHoursSlotsPerDay && s < row.length; s++) {
        g[d][s] = row[s] == 1 ? 1 : 0;
      }
    }
    return g;
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleColor': vehicleColor,
        'vehicleYear': vehicleYear,
        'ownerDisplayName': ownerDisplayName,
        'ownerIsRental': ownerIsRental,
        'rentalSharePermissionFromLessor': rentalSharePermissionFromLessor,
        'rentalContractCopyOnAcceptance': rentalContractCopyOnAcceptance,
        'insuranceNotifyOnAcceptance': insuranceNotifyOnAcceptance,
        'insuranceAssumePremiumIncrease': insuranceAssumePremiumIncrease,
        'insuranceProvideDocsOnAcceptance': insuranceProvideDocsOnAcceptance,
        'estimatedValueMinor': estimatedValueMinor,
        'photoFrontPath': photoFrontPath,
        'photoLeftPath': photoLeftPath,
        'photoRightPath': photoRightPath,
        'photoRearPath': photoRearPath,
        'photoSeatsFrontPath': photoSeatsFrontPath,
        'photoSeatsRearPath': photoSeatsRearPath,
        'photoDashboardPath': photoDashboardPath,
        'photoOdometerPath': photoOdometerPath,
        'coParticipants': coParticipants.map((e) => e.toJson()).toList(),
        'maintenanceLines': maintenanceLines.map((e) => e.toJson()).toList(),
        'availabilityHalfHours': availabilityHalfHours.map((e) => List<int>.from(e)).toList(),
        'useAppFuelTracking': useAppFuelTracking,
        'customFuelPolicyText': customFuelPolicyText,
        'clauseRules': clauseRules.toJson(),
      };

  String encode() => jsonEncode(toJson());

  factory CarSharingPlanDraft.fromJson(Map<String, dynamic> m) {
    final coParts = <CarSharingCoParticipantDraft>[];
    final rawCo = m['coParticipants'] as List<dynamic>?;
    if (rawCo != null) {
      for (final e in rawCo) {
        if (e is Map<String, dynamic>) coParts.add(CarSharingCoParticipantDraft.fromJson(e));
      }
    }
    if (coParts.isEmpty) coParts.add(CarSharingCoParticipantDraft());

    final maint = <CarSharingMaintenanceLineDraft>[];
    final rawM = m['maintenanceLines'] as List<dynamic>?;
    if (rawM != null) {
      for (final e in rawM) {
        if (e is Map<String, dynamic>) maint.add(CarSharingMaintenanceLineDraft.fromJson(e));
      }
    }
    final rawA = m['availabilityHalfHours'] as List<dynamic>?;
    List<List<int>>? av;
    if (rawA != null) {
      final parsed = quietHoursParseFromJson(rawA) ?? quietHoursEmptyGrid();
      for (var d = 0; d < kQuietHoursDays; d++) {
        for (var s = 0; s < kQuietHoursSlotsPerDay; s++) {
          parsed[d][s] = parsed[d][s] == 0 ? 0 : 1;
        }
      }
      av = parsed;
    }
    AgreementRulesDraft clauses;
    final rawC = m['clauseRules'];
    if (rawC is Map<String, dynamic>) {
      clauses = AgreementRulesDraft.fromJson(rawC);
    } else {
      clauses = AgreementRulesDraft(
        curfewEnabled: false,
        earlyWithdrawalEnabled: false,
        buildingRulesEnabled: false,
      );
    }
    return CarSharingPlanDraft(
      vehicleMake: m['vehicleMake'] as String? ?? '',
      vehicleModel: m['vehicleModel'] as String? ?? '',
      vehicleColor: m['vehicleColor'] as String? ?? '',
      vehicleYear: m['vehicleYear'] as String? ?? '',
      ownerDisplayName: m['ownerDisplayName'] as String? ?? '',
      ownerIsRental: m['ownerIsRental'] as bool? ?? false,
      rentalSharePermissionFromLessor: m['rentalSharePermissionFromLessor'] as bool? ?? false,
      rentalContractCopyOnAcceptance: m['rentalContractCopyOnAcceptance'] as bool? ?? false,
      insuranceNotifyOnAcceptance: m['insuranceNotifyOnAcceptance'] as bool? ?? false,
      insuranceAssumePremiumIncrease: m['insuranceAssumePremiumIncrease'] as bool? ?? false,
      insuranceProvideDocsOnAcceptance: m['insuranceProvideDocsOnAcceptance'] as bool? ?? false,
      estimatedValueMinor: (m['estimatedValueMinor'] as num?)?.round() ?? 0,
      photoFrontPath: m['photoFrontPath'] as String? ?? '',
      photoLeftPath: m['photoLeftPath'] as String? ?? '',
      photoRightPath: m['photoRightPath'] as String? ?? '',
      photoRearPath: m['photoRearPath'] as String? ?? '',
      photoSeatsFrontPath: m['photoSeatsFrontPath'] as String? ?? '',
      photoSeatsRearPath: m['photoSeatsRearPath'] as String? ?? '',
      photoDashboardPath: m['photoDashboardPath'] as String? ?? '',
      photoOdometerPath: m['photoOdometerPath'] as String? ?? '',
      coParticipants: coParts,
      maintenanceLines: maint,
      availabilityHalfHours: av,
      useAppFuelTracking: m['useAppFuelTracking'] as bool? ?? true,
      customFuelPolicyText: m['customFuelPolicyText'] as String? ?? '',
      rulesDraft: clauses,
    );
  }

  static CarSharingPlanDraft decode(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return CarSharingPlanDraft();
    try {
      final m = jsonDecode(t) as Map<String, dynamic>?;
      if (m == null) return CarSharingPlanDraft();
      return CarSharingPlanDraft.fromJson(m);
    } catch (_) {
      return CarSharingPlanDraft();
    }
  }
}

class CarSharingCoParticipantDraft {
  CarSharingCoParticipantDraft({this.displayName = '', this.avatarId = 'mdi:0'});

  String displayName;
  String avatarId;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'avatarId': avatarId,
      };

  factory CarSharingCoParticipantDraft.fromJson(Map<String, dynamic> m) {
    final aid = (m['avatarId'] as String?)?.trim() ?? '';
    return CarSharingCoParticipantDraft(
      displayName: m['displayName'] as String? ?? '',
      avatarId: aid.isNotEmpty ? aid : 'mdi:0',
    );
  }
}

class CarSharingMaintenanceLineDraft {
  CarSharingMaintenanceLineDraft({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.isRecurring,
    this.recurrenceDayOfMonth = 1,
  });

  final String id;
  String title;
  int amountMinor;
  bool isRecurring;
  /// Used when [isRecurring] is true; clamped to 1–31.
  int recurrenceDayOfMonth;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amountMinor': amountMinor,
        'isRecurring': isRecurring,
        'recurrenceDayOfMonth': recurrenceDayOfMonth,
      };

  factory CarSharingMaintenanceLineDraft.fromJson(Map<String, dynamic> m) {
    final rawDay = (m['recurrenceDayOfMonth'] as num?)?.round() ?? 1;
    final day = rawDay < 1 ? 1 : (rawDay > 31 ? 31 : rawDay);
    return CarSharingMaintenanceLineDraft(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      amountMinor: (m['amountMinor'] as num?)?.round() ?? 0,
      isRecurring: m['isRecurring'] as bool? ?? true,
      recurrenceDayOfMonth: day,
    );
  }
}
