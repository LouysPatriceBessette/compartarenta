import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';

import '../../db/app_database.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/realized_expense/proof_attachment_export.dart';
import '../../housing/realized_expense/realized_expense_description_display.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_line_snapshot.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/realized_expense/realized_expense_repository.dart';
import '../../housing/realized_expense/realized_expense_status.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/fullscreen_image_viewer_screen.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/local_file_image_provider.dart';
import 'housing_realized_expense_form_screen.dart';

class _ReviewContext {
  const _ReviewContext({
    required this.expense,
    required this.lineTitle,
    required this.payerName,
    required this.beneficiaryName,
    required this.proofAttachment,
    required this.visibility,
    required this.prefs,
    required this.rejections,
    required this.finalDecisionStatus,
    required this.participantReviewStatuses,
  });

  final RealizedExpense expense;
  final String lineTitle;
  final String payerName;
  final String? beneficiaryName;
  final RealizedExpenseAttachment? proofAttachment;
  final RealizedExpenseReviewVisibility visibility;
  final AppPreferences prefs;
  final List<RealizedExpenseAcceptance> rejections;
  final _FinalDecisionStatus? finalDecisionStatus;
  final List<_ParticipantReviewStatus> participantReviewStatuses;
}

class _ParticipantReviewStatus {
  const _ParticipantReviewStatus({
    required this.participantName,
    required this.decision,
  });

  final String participantName;
  final String decision;
}

class _FinalDecisionStatus {
  const _FinalDecisionStatus({
    required this.accepted,
    required this.participantName,
    required this.decidedAt,
  });

  final bool accepted;
  final String participantName;
  final DateTime decidedAt;
}

class HousingRealizedExpenseReviewScreen extends StatefulWidget {
  const HousingRealizedExpenseReviewScreen({
    super.key,
    required this.expenseId,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String expenseId;
  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  @override
  State<HousingRealizedExpenseReviewScreen> createState() =>
      _HousingRealizedExpenseReviewScreenState();
}

class _HousingRealizedExpenseReviewScreenState
    extends State<HousingRealizedExpenseReviewScreen> {
  final _repo = RealizedExpenseRepository(AppDatabase.processScope);
  Future<_ReviewContext?>? _loadFuture;
  bool _decisionSending = false;
  bool _openingPendingReview = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    HousingNavigationIntent.reviewRequestTick.addListener(
      _onPendingReviewIntent,
    );
  }

  @override
  void dispose() {
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    HousingNavigationIntent.reviewRequestTick.removeListener(
      _onPendingReviewIntent,
    );
    super.dispose();
  }

  void _reload() {
    setState(() {
      _loadFuture = _load();
    });
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _onPendingReviewIntent() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openPendingReviewIfAny();
    });
  }

  void _openPendingReviewIfAny() {
    if (_openingPendingReview) return;
    final expenseId = HousingNavigationIntent.takePendingReview();
    if (expenseId == null || !mounted) return;
    if (expenseId == widget.expenseId) {
      _reload();
      return;
    }
    _openingPendingReview = true;
    unawaited(
      Navigator.of(context)
          .pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (_) => HousingRealizedExpenseReviewScreen(
                expenseId: expenseId,
                planId: widget.planId,
                packageId: widget.packageId,
                prefs: widget.prefs,
              ),
            ),
          )
          .catchError((_) {
            _openingPendingReview = false;
          }),
    );
  }

  Future<_ReviewContext?> _load() async {
    final db = AppDatabase.processScope;
    final expense = await _repo.getById(widget.expenseId);
    if (expense == null) return null;

    var lineTitle = '';
    if (RealizedExpenseKind.usesPlanLine(expense.kind)) {
      lineTitle =
          (await resolvePlanLineTitleForExpense(db: db, expense: expense)) ??
          expense.planLineId;
    }

    final roster = await participantsForPlan(db, widget.planId);
    final payerName = displayNameForParticipant(
      expense.payerParticipantId,
      roster,
    );
    final beneficiaryName = expense.beneficiaryParticipantId == null
        ? null
        : displayNameForParticipant(expense.beneficiaryParticipantId!, roster);
    final prefs = widget.prefs ?? await AppPreferences.load();
    final ledger = RealizedExpenseLedgerService(db);
    final visibility = await ledger.visibilityFor(
      expense: expense,
      selfParticipantId: selfParticipantIdForPlan(widget.planId),
    );
    final acceptances = await _repo.acceptancesFor(expense.id);
    final rejections = acceptances
        .where((a) => a.decision == RealizedExpenseDecision.rejected)
        .toList(growable: false);
    final finalDecisionStatus = _resolveFinalDecisionStatus(
      expense: expense,
      acceptances: acceptances,
      roster: roster,
    );
    final attachments = await _repo.attachmentsFor(expense.id);

    final participantReviewStatuses = _participantReviewStatuses(
      expense: expense,
      acceptances: acceptances,
      roster: roster,
    );

    return _ReviewContext(
      expense: expense,
      lineTitle: lineTitle,
      payerName: payerName,
      beneficiaryName: beneficiaryName,
      proofAttachment: attachments.isEmpty ? null : attachments.first,
      visibility: visibility,
      prefs: prefs,
      rejections: rejections,
      finalDecisionStatus: finalDecisionStatus,
      participantReviewStatuses: participantReviewStatuses,
    );
  }

  List<_ParticipantReviewStatus> _participantReviewStatuses({
    required RealizedExpense expense,
    required List<RealizedExpenseAcceptance> acceptances,
    required List<Participant> roster,
  }) {
    if (expense.status != RealizedExpenseStatus.proposed) {
      return const [];
    }
    final out = <_ParticipantReviewStatus>[];
    for (final p in roster) {
      if (!_repo.isTransferReviewParticipant(expense, p.id)) continue;
      RealizedExpenseAcceptance? row;
      for (final a in acceptances) {
        if (a.participantId == p.id) {
          row = a;
          break;
        }
      }
      out.add(
        _ParticipantReviewStatus(
          participantName: p.displayName,
          decision: row?.decision ?? RealizedExpenseDecision.pending,
        ),
      );
    }
    return out;
  }

  String _participantReviewLine(AppLocalizations l10n, _ParticipantReviewStatus row) {
    return switch (row.decision) {
      RealizedExpenseDecision.accepted =>
        l10n.housingRealizedExpenseReviewDecisionAccepted(row.participantName),
      RealizedExpenseDecision.rejected =>
        l10n.housingRealizedExpenseReviewDecisionRejected(row.participantName),
      _ => l10n.housingRealizedExpenseReviewDecisionPending(row.participantName),
    };
  }

  _FinalDecisionStatus? _resolveFinalDecisionStatus({
    required RealizedExpense expense,
    required List<RealizedExpenseAcceptance> acceptances,
    required List<Participant> roster,
  }) {
    Iterable<RealizedExpenseAcceptance> matches;
    var accepted = false;

    if (expense.status == RealizedExpenseStatus.published) {
      accepted = true;
      matches = acceptances.where(
        (a) =>
            a.decision == RealizedExpenseDecision.accepted &&
            a.decidedAt != null,
      );
    } else if (expense.status == RealizedExpenseStatus.rejected) {
      matches = acceptances.where(
        (a) =>
            a.decision == RealizedExpenseDecision.rejected &&
            a.decidedAt != null,
      );
    } else {
      return null;
    }

    final candidateRows = matches.toList(growable: false);
    if (candidateRows.isEmpty) return null;
    final peerRows = candidateRows
        .where((a) => a.participantId != expense.payerParticipantId)
        .toList(growable: false);
    final source = peerRows.isNotEmpty ? peerRows : candidateRows;
    source.sort((a, b) => b.decidedAt!.compareTo(a.decidedAt!));
    final row = source.first;
    return _FinalDecisionStatus(
      accepted: accepted,
      participantName: displayNameForParticipant(row.participantId, roster),
      decidedAt: row.decidedAt!,
    );
  }

  Future<void> _accept(_ReviewContext ctx) async {
    if (_decisionSending) return;
    setState(() => _decisionSending = true);
    final selfId = selfParticipantIdForPlan(widget.planId);
    try {
      debugPrint(
        'housing_realized_expense accept tapped for ${widget.expenseId} '
        '(selfId=$selfId)',
      );
      await _repo.recordLocalAccept(
        expenseId: widget.expenseId,
        participantId: selfId,
      );
      debugPrint(
        'housing_realized_expense local accept recorded for ${widget.expenseId}',
      );
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch == null) {
        debugPrint(
          'housing_realized_expense accept send skipped: orchestrator missing',
        );
      } else {
        try {
          debugPrint(
            'housing_realized_expense accept send starting for ${widget.expenseId}',
          );
          await orch.sendRealizedExpenseAccept(
            expenseId: widget.expenseId,
            participantId: selfId,
          );
          debugPrint(
            'housing_realized_expense accept send completed for ${widget.expenseId}',
          );
        } on Object catch (e, st) {
          debugPrint(
            'housing_realized_expense accept send failed for '
            '${widget.expenseId}: $e\n$st',
          );
          rethrow;
        }
      }
      if (mounted) {
        debugPrint(
          'housing_realized_expense reloading review after send for '
          '${widget.expenseId}',
        );
        _reload();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).housingRealizedExpenseAccepted,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _decisionSending = false);
      }
    }
  }

  Future<void> _reject(_ReviewContext ctx) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final justification = await showAppDialog<String>(
      context: context,
      guardKey: 'realizedExpenseReview.rejectJustification',
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.housingRealizedExpenseRejectTitle),
          content: AppTextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.housingRealizedExpenseRejectJustification,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogContext, text);
              },
              child: Text(l10n.housingRealizedExpenseRejectConfirm),
            ),
          ],
        );
      },
    );
    if (justification == null || justification.isEmpty) return;

    final selfId = selfParticipantIdForPlan(widget.planId);
    await _repo.recordLocalReject(
      expenseId: widget.expenseId,
      participantId: selfId,
      justification: justification,
    );
    final orch = HandshakeOrchestrator.maybeInstance;
    await orch?.sendRealizedExpenseReject(
      expenseId: widget.expenseId,
      participantId: selfId,
      justification: justification,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.housingRealizedExpenseRejected)),
    );
    _reload();
  }

  Future<void> _resubmit(_ReviewContext ctx) async {
    final draft = await _repo.createResubmitDraftFromRejected(widget.expenseId);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HousingRealizedExpenseFormScreen(
          planId: widget.planId,
          packageId: widget.packageId,
          prefs: widget.prefs,
          existingExpenseId: draft.id,
        ),
      ),
    );
    if (mounted) _reload();
  }

  String _kindLabel(AppLocalizations l10n, String kind) {
    return switch (kind) {
      RealizedExpenseKind.transfer => l10n.housingRealizedExpenseKindTransfer,
      RealizedExpenseKind.reimbursement =>
        l10n.housingRealizedExpenseKindReimbursement,
      RealizedExpenseKind.advance => l10n.housingRealizedExpenseKindAdvance,
      _ => l10n.housingRealizedExpenseKindNormal,
    };
  }

  Widget _detailLine(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  bool _isPreviewableImage(RealizedExpenseAttachment? attachment) {
    if (attachment == null) return false;
    final name = attachment.displayFileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic');
  }

  Widget _buildProofPlaceholder(
    BuildContext context, {
    double size = 148,
    IconData icon = Icons.no_photography_outlined,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Icon(icon, size: 36, color: colors.onSurfaceVariant),
    );
  }

  Widget _buildProofPreview(BuildContext context, _ReviewContext ctx) {
    const previewSize = 148.0;
    final attachment = ctx.proofAttachment;
    final previewAttachment = _isPreviewableImage(attachment) ? attachment : null;
    final provider = previewAttachment == null
        ? null
        : localFileImageProvider(previewAttachment.filePath);
    if (provider == null) {
      return _buildProofPlaceholder(
        context,
        size: previewSize,
        icon: attachment == null
            ? Icons.no_photography_outlined
            : Icons.insert_drive_file_outlined,
      );
    }
    final imageAttachment = previewAttachment!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FullscreenImageViewerScreen(
                image: provider,
                title: imageAttachment.displayFileName,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: previewSize,
            height: previewSize,
            child: Image(
              image: provider,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return _buildProofPlaceholder(context, size: previewSize);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportAttachment(RealizedExpenseAttachment attachment) async {
    final ok = await exportStoredProofCopy(
      displayFileName: attachment.displayFileName,
      filePath: attachment.filePath,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          ).housingRealizedExpenseProofSaveCopyFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingRealizedExpenseReviewTitle)),
      body: FutureBuilder<_ReviewContext?>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ctx = snap.data;
          if (ctx == null) {
            return Center(child: Text(l10n.housingRealizedExpenseLoadFailed));
          }
          final expense = ctx.expense;
          final dateFmt = effectiveDateFormat(ctx.prefs);
          final selfId = selfParticipantIdForPlan(widget.planId);
          final canReview =
              !_decisionSending &&
              ctx.visibility == RealizedExpenseReviewVisibility.waitingForYou &&
              expense.payerParticipantId != selfId;
          final canResubmit =
              ctx.visibility == RealizedExpenseReviewVisibility.rejected &&
              expense.payerParticipantId == selfId;
          final descriptionText = realizedExpenseDescriptionForDetail(
            l10n,
            expense,
            beneficiaryDisplayName: ctx.beneficiaryName ?? '',
          );
          final finalDecisionStatus = ctx.finalDecisionStatus;
          final transferSummary =
              expense.kind == RealizedExpenseKind.transfer &&
                  ctx.beneficiaryName != null
              ? (selfId == expense.beneficiaryParticipantId
                    ? l10n.housingRealizedExpenseTransferToYouBy(ctx.payerName)
                    : l10n.housingRealizedExpenseTransferToParticipant(
                        ctx.beneficiaryName!,
                      ))
              : null;

          return ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              Text(
                formatMinorAsMoney(
                  context,
                  expense.amountMinor,
                  expense.currency,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailLine(
                            context,
                            label: l10n.housingRealizedExpenseReviewTypeLabel,
                            value: _kindLabel(l10n, expense.kind),
                          ),
                          if (ctx.lineTitle.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _detailLine(
                              context,
                              label: l10n
                                  .housingRealizedExpenseReviewPlanLineLabel,
                              value: ctx.lineTitle,
                            ),
                          ],
                          if (transferSummary != null) ...[
                            const SizedBox(height: 8),
                            Text(transferSummary),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            formatPreferenceDate(expense.paymentDate, dateFmt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildProofPreview(context, ctx),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.housingRealizedExpenseReviewDescriptionLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        descriptionText.isEmpty
                            ? l10n.housingRealizedExpenseReviewDescriptionNone
                            : descriptionText,
                      ),
                    ),
                  ],
                ),
              ),
              if (ctx.proofAttachment != null &&
                  !_isPreviewableImage(ctx.proofAttachment)) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.housingRealizedExpenseProofSection,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _exportAttachment(ctx.proofAttachment!),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ctx.proofAttachment!.displayFileName,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.housingRealizedExpenseProofTapToSaveCopy,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ctx.participantReviewStatuses.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.housingRealizedExpenseReviewDecisionsTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final row in ctx.participantReviewStatuses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(_participantReviewLine(l10n, row)),
                        ),
                    ],
                  ),
                ),
              ],
              if (ctx.rejections.isNotEmpty) ...[
                const SizedBox(height: 48),
                Text(
                  l10n.housingRealizedExpenseReviewRejections,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final r in ctx.rejections)
                  if ((r.rejectionJustification ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(r.rejectionJustification!.trim()),
                    ),
                const SizedBox(height: 16),
              ],
              if (canReview) ...[
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: () => _accept(ctx),
                  child: Text(l10n.housingRealizedExpenseAccept),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _reject(ctx),
                  child: Text(l10n.housingRealizedExpenseReject),
                ),
              ],
              if (canResubmit) ...[
                SizedBox(height: ctx.rejections.isNotEmpty ? 8 : 48),
                FilledButton.tonal(
                  onPressed: () => _resubmit(ctx),
                  child: Text(l10n.housingRealizedExpenseResubmit),
                ),
              ],
              if (finalDecisionStatus != null) ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Text(
                        finalDecisionStatus.accepted
                            ? l10n.housingRealizedExpenseReviewAcceptedWord
                            : l10n.housingRealizedExpenseReviewRejectedWord,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.fontSize ??
                                  16) *
                              1.8,
                          fontWeight: FontWeight.w700,
                          color: finalDecisionStatus.accepted
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.housingRealizedExpenseReviewByName(
                          finalDecisionStatus.participantName,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: finalDecisionStatus.accepted
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      Text(
                        formatPreferenceDateTime(
                          finalDecisionStatus.decidedAt,
                          dateFmt,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: finalDecisionStatus.accepted
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
