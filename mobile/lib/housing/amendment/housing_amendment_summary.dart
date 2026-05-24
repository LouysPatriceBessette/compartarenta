import 'dart:convert';

import '../../db/app_database.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_amendment_type.dart';

/// Loaded comparison between the in-force revision and a pending amendment.
class HousingAmendmentSummary {
  const HousingAmendmentSummary({
    required this.revisionId,
    required this.type,
    required this.proposerParticipantId,
    required this.proposerDisplayName,
    required this.targetLineId,
    required this.targetLineTitle,
    required this.currentText,
    required this.proposedText,
    this.responseExpiresAtUtc,
  });

  final String revisionId;
  final HousingAmendmentType type;
  final String proposerParticipantId;
  final String proposerDisplayName;
  final String? targetLineId;
  final String? targetLineTitle;
  final String currentText;
  final String proposedText;
  final DateTime? responseExpiresAtUtc;

  String subjectLabel(AppLocalizations l10n) => switch (type) {
        HousingAmendmentType.lineAmount => l10n.housingAmendmentSubjectLineAmount(
            targetLineTitle ?? targetLineId ?? '',
          ),
        HousingAmendmentType.lineRecurrence =>
          l10n.housingAmendmentSubjectLineRecurrence(
            targetLineTitle ?? targetLineId ?? '',
          ),
        HousingAmendmentType.linePayer => l10n.housingAmendmentSubjectLinePayer(
            targetLineTitle ?? targetLineId ?? '',
          ),
        HousingAmendmentType.lineAdd => l10n.housingAmendmentSubjectLineAdd,
        HousingAmendmentType.lineRemove =>
          l10n.housingAmendmentSubjectLineRemove(
            targetLineTitle ?? targetLineId ?? '',
          ),
        HousingAmendmentType.agreementEnd =>
          l10n.housingAmendmentSubjectAgreementEnd,
        HousingAmendmentType.ruleChange => l10n.housingAmendmentSubjectRuleChange,
      };
}

/// Returns null when [revisionId] is not an amendment revision.
Future<HousingAmendmentSummary?> loadHousingAmendmentSummary({
  required AppDatabase db,
  required String planId,
  String? revisionId,
  required AppLocalizations l10n,
  required String dateFormat,
}) async {
  await HousingProposalTransportService(db).reconcileStalePackagePending(planId);

  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final pendingId = revisionId ?? pkg?.pendingRevisionId;
  if (pendingId == null) return null;

  final pendingRev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(pendingId)))
      .getSingleOrNull();
  if (pendingRev == null) return null;

  Map<String, dynamic> pendingPayload;
  try {
    pendingPayload = jsonDecode(pendingRev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
  final amendmentType = resolveAmendmentType(
    pendingPayload: pendingPayload,
    activeRevisionId: pkg?.activeRevisionId,
    pendingRevisionId: pendingId,
  );
  if (amendmentType == null) return null;

  final baselineId = pkg?.activeRevisionId;
  Map<String, dynamic> baselinePayload = pendingPayload;
  if (baselineId != null && baselineId != pendingId) {
    final baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(baselineId)))
        .getSingleOrNull();
    if (baselineRev != null) {
      baselinePayload =
          jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
    }
  }

  final roster = await participantsForPlan(db, planId);
  String nameFor(String participantId) =>
      displayNameForParticipant(participantId, roster);

  DateTime? parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic>? agreementMap(Map<String, dynamic> payload) {
    final agr = payload['agreement'];
    if (agr is Map) return agr.cast<String, dynamic>();
    return null;
  }

  List<Map<String, dynamic>> linesList(Map<String, dynamic> payload) {
    final plan = payload['plan'];
    if (plan is! Map) return const [];
    final lines = plan['lines'];
    if (lines is! List) return const [];
    return [
      for (final e in lines)
        if (e is Map) e.cast<String, dynamic>(),
    ];
  }

  Map<String, dynamic>? lineById(
    List<Map<String, dynamic>> lines,
    String? lineId,
  ) {
    if (lineId == null || lineId.isEmpty) return null;
    for (final line in lines) {
      final id = line['id']?.toString() ?? '';
      if (id == lineId || id.endsWith(':$lineId') || lineId.endsWith(':$id')) {
        return line;
      }
    }
    return null;
  }

  String lineTitle(Map<String, dynamic>? line, String? fallbackId) {
    if (line == null) return fallbackId ?? l10n.housingAmendmentUnknownLine;
    final title = line['title']?.toString().trim() ?? '';
    if (title.isNotEmpty) return title;
    final id = line['id']?.toString() ?? '';
    return id.isEmpty ? (fallbackId ?? l10n.housingAmendmentUnknownLine) : id;
  }

  String formatAmount(Map<String, dynamic>? line) {
    if (line == null) return l10n.housingAmendmentValueNotSet;
    final minor = line['amountMinor'];
    if (minor is! num) return l10n.housingAmendmentValueNotSet;
    final currency = line['currency']?.toString().trim();
    final code = currency == null || currency.isEmpty ? '' : currency;
    final major = minor / 100;
    return code.isEmpty ? major.toStringAsFixed(2) : '$major $code';
  }

  String formatRecurrence(Map<String, dynamic>? line) {
    if (line == null) return l10n.housingAmendmentValueNotSet;
    final cadence = line['cadence']?.toString() ?? '';
    final spec = line['recurrenceSpecJson']?.toString().trim() ?? '';
    if (spec.isNotEmpty) return '$cadence · $spec';
    return cadence.isEmpty ? l10n.housingAmendmentValueNotSet : cadence;
  }

  String formatPayer(Map<String, dynamic>? line) {
    if (line == null) return l10n.housingAmendmentValueNotSet;
    final raw = line['paymentResponsibleParticipantId']?.toString() ?? '';
    if (raw.isEmpty) return l10n.housingAmendmentValueNotSet;
    final local = raw.contains(':') ? raw : '$planId:$raw';
    return nameFor(local);
  }

  final targetLineId = pendingPayload['amendmentTargetLineId'] as String?;
  final baselineLines = linesList(baselinePayload);
  final pendingLines = linesList(pendingPayload);
  final baselineLine = lineById(baselineLines, targetLineId);
  final pendingLine = lineById(pendingLines, targetLineId);
  final lineTitleLabel = lineTitle(baselineLine ?? pendingLine, targetLineId);

  late final String currentText;
  late final String proposedText;
  switch (amendmentType) {
    case HousingAmendmentType.agreementEnd:
      final baseEnd = parseDate(agreementMap(baselinePayload)?['periodEnd']);
      final propEnd = parseDate(agreementMap(pendingPayload)?['periodEnd']);
      currentText = baseEnd == null
          ? l10n.housingAmendmentValueNotSet
          : formatPreferenceDate(baseEnd, dateFormat);
      proposedText = propEnd == null
          ? l10n.housingAmendmentValueNotSet
          : formatPreferenceDate(propEnd, dateFormat);
    case HousingAmendmentType.lineAmount:
      currentText = formatAmount(baselineLine);
      proposedText = formatAmount(pendingLine);
    case HousingAmendmentType.lineRecurrence:
      currentText = formatRecurrence(baselineLine);
      proposedText = formatRecurrence(pendingLine);
    case HousingAmendmentType.linePayer:
      currentText = formatPayer(baselineLine);
      proposedText = formatPayer(pendingLine);
    case HousingAmendmentType.lineAdd:
      currentText = l10n.housingAmendmentValueNone;
      proposedText = pendingLine == null
          ? l10n.housingAmendmentValueNotSet
          : '${lineTitle(pendingLine, targetLineId)} · ${formatAmount(pendingLine)}';
    case HousingAmendmentType.lineRemove:
      currentText = baselineLine == null
          ? l10n.housingAmendmentValueNotSet
          : '${lineTitle(baselineLine, targetLineId)} · ${formatAmount(baselineLine)}';
      proposedText = l10n.housingAmendmentValueRemoved;
    case HousingAmendmentType.ruleChange:
      currentText = l10n.housingAmendmentRulesCurrentPlaceholder;
      proposedText = l10n.housingAmendmentRulesProposedPlaceholder;
  }

  DateTime? expires;
  final rawExpires = pendingPayload['responseExpiresAt'];
  if (rawExpires is String && rawExpires.isNotEmpty) {
    expires = DateTime.tryParse(rawExpires)?.toUtc();
  }

  return HousingAmendmentSummary(
    revisionId: pendingId,
    type: amendmentType,
    proposerParticipantId: pendingRev.proposerParticipantId,
    proposerDisplayName: nameFor(pendingRev.proposerParticipantId),
    targetLineId: targetLineId,
    targetLineTitle: lineTitleLabel,
    currentText: currentText,
    proposedText: proposedText,
    responseExpiresAtUtc: expires,
  );
}

/// Removes a plan line from a revision payload only (live tables unchanged).
void removeLineFromRevisionPayload(
  Map<String, dynamic> payload,
  String lineId,
  String planId,
) {
  final plan = payload['plan'];
  if (plan is! Map) return;
  final planMap = plan.cast<String, dynamic>();
  final lines = planMap['lines'];
  if (lines is List) {
    planMap['lines'] = [
      for (final entry in lines)
        if (entry is Map) ...[
          if (!_lineIdMatches(lineId, planId, entry['id']?.toString() ?? ''))
            entry,
        ],
    ];
  }
  final ratios = planMap['ratios'];
  if (ratios is List) {
    planMap['ratios'] = [
      for (final entry in ratios)
        if (entry is Map) ...[
          if (!_lineIdMatches(
            lineId,
            planId,
            entry['lineId']?.toString() ?? '',
          ))
            entry,
        ],
    ];
  }
}

bool _lineIdMatches(String targetLineId, String planId, String payloadLineId) {
  if (payloadLineId.isEmpty) return false;
  if (payloadLineId == targetLineId) return true;
  if (payloadLineId.endsWith(':$targetLineId')) return true;
  if (targetLineId.endsWith(':$payloadLineId')) return true;
  final resolved = payloadLineId.contains(':')
      ? payloadLineId
      : '$planId:$payloadLineId';
  return resolved == targetLineId;
}

Future<bool> pendingRevisionIsAmendment(
  AppDatabase db,
  String planId, {
  String? revisionId,
}) async {
  await HousingProposalTransportService(db).reconcileStalePackagePending(planId);
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final pendingId = revisionId ?? pkg?.pendingRevisionId;
  if (pendingId == null) return false;
  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(pendingId)))
      .getSingleOrNull();
  if (rev == null) return false;
  Map<String, dynamic> payload;
  try {
    payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return false;
  }
  return resolveAmendmentType(
        pendingPayload: payload,
        activeRevisionId: pkg?.activeRevisionId,
        pendingRevisionId: pendingId,
      ) !=
      null;
}
