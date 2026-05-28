import 'dart:convert';

import '../../db/app_database.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_amendment_settlement.dart';
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
        HousingAmendmentType.lineEdit => l10n.housingAmendmentSubjectLineEdit(
            targetLineTitle ?? targetLineId ?? '',
          ),
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

  final isArchived =
      (pendingPayload['lifecycleState'] as String?) == 'archived';
  final isArchivedDecision = isArchived;
  final baselineId = amendmentBaselineRevisionId(
    revisionPayload: pendingPayload,
    revisionId: pendingId,
    packageActiveRevisionId: pkg?.activeRevisionId,
    isArchived: isArchived,
  );
  Map<String, dynamic> baselinePayload = pendingPayload;
  var resolvedBaselineId = baselineId;
  if (resolvedBaselineId != null) {
    var baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(resolvedBaselineId!)))
        .getSingleOrNull();
    if (baselineRev == null &&
        pkg?.activeRevisionId != null &&
        pkg!.activeRevisionId != pendingId) {
      resolvedBaselineId = pkg.activeRevisionId;
      baselineRev = await (db.select(db.proposalRevisions)
            ..where((t) => t.id.equals(resolvedBaselineId!)))
          .getSingleOrNull();
    }
    if (baselineRev != null) {
      baselinePayload =
          jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
    }
  } else if (pkg?.activeRevisionId != null &&
      pkg!.activeRevisionId != pendingId &&
      !isArchivedDecision) {
    final baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(pkg.activeRevisionId!)))
        .getSingleOrNull();
    if (baselineRev != null) {
      baselinePayload =
          jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
    }
  }

  final targetLineId = pendingPayload['amendmentTargetLineId'] as String?;
  final texts = await _amendmentComparisonTexts(
    planId: planId,
    amendmentType: amendmentType,
    targetLineId: targetLineId,
    baselinePayload: baselinePayload,
    proposedPayload: pendingPayload,
    l10n: l10n,
    dateFormat: dateFormat,
    db: db,
    proposerParticipantId: pendingRev.proposerParticipantId,
    packageActiveRevisionId: pkg?.activeRevisionId,
    pendingRevisionId: pendingId,
    comparisonHistoricalOnly: isArchivedDecision,
  );

  DateTime? expires;
  final rawExpires = pendingPayload['responseExpiresAt'];
  if (rawExpires is String && rawExpires.isNotEmpty) {
    expires = DateTime.tryParse(rawExpires)?.toUtc();
  }

  return HousingAmendmentSummary(
    revisionId: pendingId,
    type: amendmentType,
    proposerParticipantId: pendingRev.proposerParticipantId,
    proposerDisplayName: texts.proposerDisplayName,
    targetLineId: targetLineId,
    targetLineTitle: texts.lineTitleLabel,
    currentText: texts.currentText,
    proposedText: texts.proposedText,
    responseExpiresAtUtc: expires,
  );
}

/// Preview diff before a revision is created (current DB vs in-force revision).
Future<HousingAmendmentSummary?> buildAmendmentPreviewSummary({
  required AppDatabase db,
  required String planId,
  required HousingAmendmentType type,
  String? targetLineId,
  DateTime? proposedPeriodEnd,
  required AppLocalizations l10n,
  required String dateFormat,
}) async {
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  final baselineId = pkg?.activeRevisionId;
  if (baselineId == null) return null;

  final baselineRev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(baselineId)))
      .getSingleOrNull();
  if (baselineRev == null) return null;

  Map<String, dynamic> baselinePayload;
  try {
    baselinePayload = jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }

  final proposedPayload = await _proposedPayloadFromCurrentPlan(
    db: db,
    planId: planId,
    baselinePayload: baselinePayload,
    proposedPeriodEnd: proposedPeriodEnd,
    removeLineId: type == HousingAmendmentType.lineRemove ? targetLineId : null,
  );

  final texts = await _amendmentComparisonTexts(
    planId: planId,
    amendmentType: type,
    targetLineId: targetLineId,
    baselinePayload: baselinePayload,
    proposedPayload: proposedPayload,
    l10n: l10n,
    dateFormat: dateFormat,
    db: db,
    proposerParticipantId: '$planId:self',
  );

  return HousingAmendmentSummary(
    revisionId: 'preview',
    type: type,
    proposerParticipantId: '$planId:self',
    proposerDisplayName: texts.proposerDisplayName,
    targetLineId: targetLineId,
    targetLineTitle: texts.lineTitleLabel,
    currentText: texts.currentText,
    proposedText: texts.proposedText,
  );
}

bool amendmentSummaryHasMeaningfulChange(HousingAmendmentSummary summary) {
  if (summary.type == HousingAmendmentType.lineAdd ||
      summary.type == HousingAmendmentType.lineRemove) {
    return true;
  }
  if (summary.type == HousingAmendmentType.ruleChange) {
    return summary.currentText != summary.proposedText;
  }
  return summary.currentText.trim() != summary.proposedText.trim();
}

class _AmendmentComparisonTexts {
  const _AmendmentComparisonTexts({
    required this.proposerDisplayName,
    required this.lineTitleLabel,
    required this.currentText,
    required this.proposedText,
  });

  final String proposerDisplayName;
  final String lineTitleLabel;
  final String currentText;
  final String proposedText;
}

Future<_AmendmentComparisonTexts> _amendmentComparisonTexts({
  required String planId,
  required HousingAmendmentType amendmentType,
  required String? targetLineId,
  required Map<String, dynamic> baselinePayload,
  required Map<String, dynamic> proposedPayload,
  required AppLocalizations l10n,
  required String dateFormat,
  required AppDatabase db,
  required String proposerParticipantId,
  String? packageActiveRevisionId,
  String? pendingRevisionId,
  bool comparisonHistoricalOnly = false,
}) async {
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

  String formatLineEditSummary(Map<String, dynamic>? line) {
    if (line == null) return l10n.housingAmendmentValueNotSet;
    final title = lineTitle(line, null);
    return '$title · ${formatAmount(line)} · ${formatPayer(line)}';
  }

  final baselineLines = linesList(baselinePayload);
  final pendingLines = linesList(proposedPayload);
  final baselineLine = lineById(baselineLines, targetLineId);
  final pendingLine = lineById(pendingLines, targetLineId);
  final lineTitleLabel = lineTitle(baselineLine ?? pendingLine, targetLineId);

  late final String currentText;
  late final String proposedText;
  switch (amendmentType) {
    case HousingAmendmentType.agreementEnd:
      DateTime? forkEnd;
      final forkId = proposedPayload['forkedFromRevisionId'] as String?;
      if (forkId != null && forkId.isNotEmpty) {
        forkEnd = await _agreementPeriodEndForRevision(db, forkId);
      }
      final baseEnd = parseDate(agreementMap(baselinePayload)?['periodEnd']);
      final propEnd = parseDate(agreementMap(proposedPayload)?['periodEnd']);
      final DateTime? currentEnd;
      if (comparisonHistoricalOnly) {
        // After acceptance the live agreement and active revision already carry
        // the proposed end date; show the fork / baseline snapshot only.
        currentEnd = forkEnd ?? baseEnd;
      } else {
        final liveEnd = (await db.getAgreementForPlan(planId))?.periodEnd;
        DateTime? inForceEnd;
        if (packageActiveRevisionId != null &&
            pendingRevisionId != null &&
            packageActiveRevisionId != pendingRevisionId) {
          inForceEnd = await _agreementPeriodEndForRevision(
            db,
            packageActiveRevisionId,
          );
        }
        currentEnd = liveEnd ?? inForceEnd ?? forkEnd ?? baseEnd;
      }
      currentText = currentEnd == null
          ? l10n.housingAmendmentValueNotSet
          : formatPreferenceDate(currentEnd, dateFormat);
      proposedText = propEnd == null
          ? l10n.housingAmendmentValueNotSet
          : formatPreferenceDate(propEnd, dateFormat);
    case HousingAmendmentType.lineEdit:
      currentText = formatLineEditSummary(baselineLine);
      proposedText = formatLineEditSummary(pendingLine);
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
      final baseRules =
          agreementMap(baselinePayload)?['agreementRulesJson']?.toString() ??
              '';
      final propRules =
          agreementMap(proposedPayload)?['agreementRulesJson']?.toString() ?? '';
      if (baseRules == propRules) {
        currentText = l10n.housingAmendmentRulesCurrentPlaceholder;
        proposedText = l10n.housingAmendmentRulesProposedPlaceholder;
      } else {
        currentText = l10n.housingAmendmentRulesCurrentPlaceholder;
        proposedText = l10n.housingAmendmentRulesSummaryShort;
      }
  }

  return _AmendmentComparisonTexts(
    proposerDisplayName: nameFor(proposerParticipantId),
    lineTitleLabel: lineTitleLabel,
    currentText: currentText,
    proposedText: proposedText,
  );
}

Future<Map<String, dynamic>> _proposedPayloadFromCurrentPlan({
  required AppDatabase db,
  required String planId,
  required Map<String, dynamic> baselinePayload,
  DateTime? proposedPeriodEnd,
  String? removeLineId,
}) async {
  final proposed =
      jsonDecode(jsonEncode(baselinePayload)) as Map<String, dynamic>;
  final plan = proposed['plan'];
  if (plan is! Map) return proposed;
  final planMap = plan.cast<String, dynamic>();

  final lines = await db.listPlanLines(planId);
  planMap['lines'] = [
    for (final l in lines)
      if (removeLineId == null || l.id != removeLineId)
        {
          'id': l.id,
          'title': l.title,
          'description': l.description,
          'currency': l.currency,
          'isRecurring': l.isRecurring,
          'amountUsesRange': l.amountUsesRange,
          'amountIsBudgetCap': l.amountIsBudgetCap,
          'amountMinor': l.amountMinor,
          'minAmountMinor': l.minAmountMinor,
          'maxAmountMinor': l.maxAmountMinor,
          'cadence': l.cadence,
          'recurrenceDayOfMonth': l.recurrenceDayOfMonth,
          if (l.recurrenceSpecJson.isNotEmpty)
            'recurrenceSpecJson': l.recurrenceSpecJson,
          if (l.paymentResponsibleParticipantId != null)
            'paymentResponsibleParticipantId': l.paymentResponsibleParticipantId,
          if (l.ratioTemplateId != null) 'ratioTemplateId': l.ratioTemplateId,
          if (l.groupId != null) 'groupId': l.groupId,
        },
  ];

  final agreement = await db.getAgreementForPlan(planId);
  if (agreement != null) {
    final agr = proposed['agreement'];
    if (agr is Map) {
      final agrMap = agr.cast<String, dynamic>();
      agrMap['periodEnd'] = (proposedPeriodEnd ?? agreement.periodEnd)
          .toIso8601String();
      agrMap['agreementRulesJson'] = agreement.agreementRulesJson;
      agrMap['clauses'] = agreement.clauses;
      agrMap['withdrawalSameForAll'] = agreement.withdrawalSameForAll;
      agrMap['withdrawalPerParticipantJson'] =
          agreement.withdrawalPerParticipantJson;
    }
  }

  return proposed;
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

Future<DateTime?> _agreementPeriodEndForRevision(
  AppDatabase db,
  String revisionId,
) async {
  final rev = await (db.select(db.proposalRevisions)
        ..where((t) => t.id.equals(revisionId)))
      .getSingleOrNull();
  if (rev == null) return null;
  Map<String, dynamic> payload;
  try {
    payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
  final agr = payload['agreement'];
  if (agr is! Map) return null;
  final raw = agr['periodEnd'];
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
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
  bool reconcileFirst = true,
}) async {
  if (reconcileFirst) {
    await HousingProposalTransportService(db).reconcileStalePackagePending(
      planId,
    );
  }
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
  if (pkg?.activeRevisionId != null &&
      HousingAmendmentTypeWire.parse(payload['amendmentType'] as String?) !=
          null) {
    return true;
  }
  return resolveAmendmentType(
        pendingPayload: payload,
        activeRevisionId: pkg?.activeRevisionId,
        pendingRevisionId: pendingId,
      ) !=
      null;
}
