import 'dart:convert';

import '../../db/app_database.dart';
import '../proposals/housing_proposal_transport_service.dart';
import '../proposals/plan_agreement_proposal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
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

  /// Short list label for the change journal (type-specific title formats).
  String journalListSubject(AppLocalizations l10n) {
    switch (type) {
      case HousingAmendmentType.agreementEnd:
        return l10n.housingAmendmentJournalSubjectAgreementEnd;
      case HousingAmendmentType.lineAdd:
        return _journalLineExpenseSubject(
          l10n,
          formatTitleAmount: l10n.housingAmendmentJournalLineAdd,
          sourceText: proposedText,
          fallbackTitle: targetLineTitle,
        );
      case HousingAmendmentType.lineEdit:
        return _journalLineExpenseSubject(
          l10n,
          formatTitleAmount: l10n.housingAmendmentJournalLineEdit,
          sourceText: currentText,
          fallbackTitle: targetLineTitle,
        );
      case HousingAmendmentType.lineRemove:
        return _journalLineExpenseSubject(
          l10n,
          formatTitleAmount: l10n.housingAmendmentJournalLineRemove,
          sourceText: currentText,
          fallbackTitle: targetLineTitle,
        );
      default:
        return subjectLabel(l10n);
    }
  }

  String _journalLineExpenseSubject(
    AppLocalizations l10n, {
    required String Function(String title, String amount) formatTitleAmount,
    required String sourceText,
    required String? fallbackTitle,
  }) {
    final parsed = _parseTitleAmountFromComparisonText(
      sourceText,
      localeName: l10n.localeName,
    );
    final title = (parsed?.title ?? fallbackTitle ?? '').trim();
    if (title.isEmpty) {
      return sourceText.trim().isEmpty ? subjectLabel(l10n) : sourceText;
    }
    final amount = parsed?.formattedAmount ?? l10n.housingAmendmentValueNotSet;
    return formatTitleAmount(title, amount);
  }

  ({String title, String formattedAmount})? _parseTitleAmountFromComparisonText(
    String text, {
    required String localeName,
  }) {
    const sep = ' · ';
    final trimmed = text.trim();
    if (!trimmed.contains(sep)) return null;
    final parts = trimmed.split(sep);
    if (parts.length < 2) return null;
    final title = parts.first.trim();
    final amountPart = parts[1].trim();
    if (title.isEmpty || amountPart.isEmpty) return null;

    final amountMatch = RegExp(r'^([\d.,]+)\s*([A-Za-z]{3})?$').firstMatch(amountPart);
    if (amountMatch == null) {
      return (title: title, formattedAmount: amountPart);
    }
    final majorRaw = amountMatch.group(1)!.replaceAll(',', '.');
    final major = double.tryParse(majorRaw);
    final currencyCode = amountMatch.group(2) ?? '';
    if (major == null) {
      return (title: title, formattedAmount: amountPart);
    }
    final formatted = formatMinorAsMoneyForLocale(
      localeName,
      (major * 100).round(),
      currencyCode,
    );
    return (title: title, formattedAmount: formatted);
  }
}

/// Returns null when [revisionId] is not an amendment revision.
Future<HousingAmendmentSummary?> loadHousingAmendmentSummary({
  required AppDatabase db,
  required String planId,
  String? revisionId,
  required AppLocalizations l10n,
  required String dateFormat,
}) async {
  final transport = HousingProposalTransportService(db);
  try {
    await transport.reconcileStalePackagePending(planId);
  } catch (_) {
    // Best-effort only; duplicate legacy package rows can cause getSingleOrNull
    // to throw — the summary loader below handles duplicates explicitly.
  }

  final packages = await transport.proposalPackagesForPlan(planId);
  final pendingId =
      revisionId ?? packages.map((p) => p.pendingRevisionId).whereType<String>().firstOrNull;
  if (pendingId == null) return null;
  final activeRevisionId = await transport.resolveActiveRevisionIdForPlan(planId);

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
    activeRevisionId: activeRevisionId,
    pendingRevisionId: pendingId,
  );
  if (amendmentType == null) return null;

  final isArchived =
      (pendingPayload['lifecycleState'] as String?) == 'archived';
  final isArchivedDecision = isArchived;
  final baselineId = amendmentBaselineRevisionId(
    revisionPayload: pendingPayload,
    revisionId: pendingId,
    packageActiveRevisionId: activeRevisionId,
    isArchived: isArchived,
  );
  Map<String, dynamic> baselinePayload = pendingPayload;
  var resolvedBaselineId = baselineId;
  if (resolvedBaselineId != null) {
    var baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(resolvedBaselineId!)))
        .getSingleOrNull();
    if (baselineRev == null &&
        activeRevisionId != null &&
        activeRevisionId != pendingId) {
      resolvedBaselineId = activeRevisionId;
      baselineRev = await (db.select(db.proposalRevisions)
            ..where((t) => t.id.equals(resolvedBaselineId!)))
          .getSingleOrNull();
    }
    if (baselineRev != null) {
      baselinePayload =
          jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
    }
  } else if (activeRevisionId != null &&
      activeRevisionId != pendingId &&
      !isArchivedDecision) {
    final baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(activeRevisionId)))
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
    packageActiveRevisionId: activeRevisionId,
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
  final transport = HousingProposalTransportService(db);
  final baselineId = await transport.resolveActiveRevisionIdForPlan(planId);

  Map<String, dynamic> baselinePayload;
  if (baselineId != null) {
    final baselineRev = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(baselineId)))
        .getSingleOrNull();
    if (baselineRev == null) return null;
    try {
      baselinePayload =
          jsonDecode(baselineRev.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  } else {
    try {
      final snapshot = await PlanAgreementProposalService(db)
          .buildSnapshotPayloadForPlan(planId);
      baselinePayload = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
    packageActiveRevisionId: baselineId,
    pendingRevisionId: 'preview',
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
      final propEnd = parseDate(agreementMap(proposedPayload)?['periodEnd']);
      final currentEnd = await _inForceAgreementPeriodEnd(
        db: db,
        proposedPayload: proposedPayload,
        baselinePayload: baselinePayload,
        propEnd: propEnd,
        packageActiveRevisionId: packageActiveRevisionId,
        pendingRevisionId: pendingRevisionId,
        historicalOnly: comparisonHistoricalOnly,
      );
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

Map<String, dynamic>? _agreementMapFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  final agr = payload['agreement'];
  if (agr is Map) return agr.cast<String, dynamic>();
  return null;
}

/// In-force agreement end for comparison while a change is still open.
///
/// Never uses live plan tables or the pending revision payload — those may
/// already reflect the proposed date before unanimous acceptance.
Future<DateTime?> _inForceAgreementPeriodEnd({
  required AppDatabase db,
  required Map<String, dynamic> proposedPayload,
  required Map<String, dynamic> baselinePayload,
  required DateTime? propEnd,
  required String? packageActiveRevisionId,
  required String? pendingRevisionId,
  required bool historicalOnly,
}) async {
  DateTime? parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  if (!historicalOnly &&
      packageActiveRevisionId != null &&
      pendingRevisionId != null &&
      packageActiveRevisionId != pendingRevisionId) {
    final inForceEnd = await _agreementPeriodEndForRevision(
      db,
      packageActiveRevisionId,
    );
    if (inForceEnd != null) return inForceEnd;
  }

  final forkId = proposedPayload['forkedFromRevisionId'] as String?;
  if (forkId != null && forkId.isNotEmpty) {
    final forkEnd = await _agreementPeriodEndForRevision(db, forkId);
    if (forkEnd != null) return forkEnd;
  }

  final baseEnd =
      parseDate(_agreementMapFromPayload(baselinePayload)?['periodEnd']);
  // If baseline equals proposed (e.g. baselinePayload accidentally points at the
  // pending revision), still return baseline rather than showing "Not set".
  return baseEnd;
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
