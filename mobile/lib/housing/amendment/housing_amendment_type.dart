/// Single-change amendment kinds for an in-force housing agreement.
enum HousingAmendmentType {
  lineEdit,
  lineAmount,
  lineRecurrence,
  linePayer,
  lineAdd,
  lineRemove,
  agreementEnd,
  ruleChange,
}

extension HousingAmendmentTypeWire on HousingAmendmentType {
  String get wireValue => switch (this) {
        HousingAmendmentType.lineEdit => 'line_edit',
        HousingAmendmentType.lineAmount => 'line_amount',
        HousingAmendmentType.lineRecurrence => 'line_recurrence',
        HousingAmendmentType.linePayer => 'line_payer',
        HousingAmendmentType.lineAdd => 'line_add',
        HousingAmendmentType.lineRemove => 'line_remove',
        HousingAmendmentType.agreementEnd => 'agreement_end',
        HousingAmendmentType.ruleChange => 'rule_change',
      };

  static HousingAmendmentType? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final t in HousingAmendmentType.values) {
      if (t.wireValue == raw) return t;
    }
    return null;
  }

  bool get editsPlanLine =>
      this == HousingAmendmentType.lineEdit ||
      this == HousingAmendmentType.lineAmount ||
      this == HousingAmendmentType.lineRecurrence ||
      this == HousingAmendmentType.linePayer ||
      this == HousingAmendmentType.lineRemove;

  bool get requiresLinePicker => editsPlanLine;

  bool get createsNewLine => this == HousingAmendmentType.lineAdd;
}

/// Parses [amendmentType] or infers an in-force fork when the wire field is missing.
HousingAmendmentType? resolveAmendmentType({
  required Map<String, dynamic> pendingPayload,
  required String? activeRevisionId,
  required String pendingRevisionId,
}) {
  final explicit = HousingAmendmentTypeWire.parse(
    pendingPayload['amendmentType'] as String?,
  );
  if (explicit != null) return explicit;

  final fork = pendingPayload['forkedFromRevisionId'] as String?;
  if (fork != null && fork.isNotEmpty) {
    return _inferAmendmentTypeFromForkPayload(pendingPayload);
  }

  if (activeRevisionId == null || activeRevisionId == pendingRevisionId) {
    return null;
  }
  return null;
}

HousingAmendmentType _inferAmendmentTypeFromForkPayload(
  Map<String, dynamic> payload,
) {
  if (payload['amendmentTargetLineId'] != null) {
    return HousingAmendmentType.lineAmount;
  }
  final agr = payload['agreement'];
  if (agr is Map && agr['periodEnd'] != null) {
    return HousingAmendmentType.agreementEnd;
  }
  return HousingAmendmentType.ruleChange;
}
