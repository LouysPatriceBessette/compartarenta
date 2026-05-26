import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/realized_expense/realized_expense_repository.dart';
import '../../housing/realized_expense/realized_expense_status.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
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
  });

  final RealizedExpense expense;
  final String lineTitle;
  final String payerName;
  final String? beneficiaryName;
  final RealizedExpenseAttachment? proofAttachment;
  final RealizedExpenseReviewVisibility visibility;
  final AppPreferences prefs;
  final List<RealizedExpenseAcceptance> rejections;
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

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  void _reload() => setState(() => _loadFuture = _load());

  Future<_ReviewContext?> _load() async {
    final db = AppDatabase.processScope;
    final expense = await _repo.getById(widget.expenseId);
    if (expense == null) return null;

    var lineTitle = '';
    if (RealizedExpenseKind.usesPlanLine(expense.kind)) {
      final lines = await db.listPlanLines(widget.planId);
      lineTitle = expense.planLineId;
      for (final line in lines) {
        if (line.id == expense.planLineId) {
          final t = line.title.trim();
          if (t.isNotEmpty) lineTitle = t;
          break;
        }
      }
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
    final attachments = await _repo.attachmentsFor(expense.id);

    return _ReviewContext(
      expense: expense,
      lineTitle: lineTitle,
      payerName: payerName,
      beneficiaryName: beneficiaryName,
      proofAttachment: attachments.isEmpty ? null : attachments.first,
      visibility: visibility,
      prefs: prefs,
      rejections: rejections,
    );
  }

  Future<void> _accept(_ReviewContext ctx) async {
    if (_decisionSending) return;
    setState(() => _decisionSending = true);
    final selfId = selfParticipantIdForPlan(widget.planId);
    try {
      await _repo.recordLocalAccept(
        expenseId: widget.expenseId,
        participantId: selfId,
      );
      if (mounted) _reload();
      final orch = HandshakeOrchestrator.maybeInstance;
      await orch?.sendRealizedExpenseAccept(
        expenseId: widget.expenseId,
        participantId: selfId,
      );
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
    final justification = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.housingRealizedExpenseRejectTitle),
          content: TextField(
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
    final draft = await _repo.createResubmitDraftFromRejected(
      widget.expenseId,
    );
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

  Widget _buildProofPlaceholder(BuildContext context, {double size = 148}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Icon(
        Icons.no_photography_outlined,
        size: 36,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildProofPreview(BuildContext context, _ReviewContext ctx) {
    const previewSize = 148.0;
    final attachment = ctx.proofAttachment;
    final provider = _isPreviewableImage(attachment) && attachment != null
        ? localFileImageProvider(attachment.filePath)
        : null;
    if (provider == null) {
      return _buildProofPlaceholder(context, size: previewSize);
    }
    return ClipRRect(
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
          final canReview = !_decisionSending &&
              ctx.visibility ==
                  RealizedExpenseReviewVisibility.waitingForYou &&
              expense.payerParticipantId != selfId;
          final canResubmit = ctx.visibility ==
                  RealizedExpenseReviewVisibility.rejected &&
              expense.payerParticipantId == selfId;
          final descriptionText = (expense.description ?? '').trim();
          final transferSummary =
              expense.kind == RealizedExpenseKind.transfer &&
                  ctx.beneficiaryName != null
              ? (selfId == expense.beneficiaryParticipantId
                    ? l10n.housingRealizedExpenseTransferToYouBy(
                        ctx.payerName,
                      )
                    : l10n.housingRealizedExpenseTransferToParticipant(
                        ctx.beneficiaryName!,
                      ))
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
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
                              label: l10n.housingRealizedExpenseReviewPlanLineLabel,
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
                      l10n.housingRealizedExpenseTransferDescription,
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
              const SizedBox(height: 48),
              if (expense.kind == RealizedExpenseKind.transfer) ...[
                Text(
                  l10n.housingRealizedExpenseTransferReviewHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              if (ctx.rejections.isNotEmpty) ...[
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
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _resubmit(ctx),
                  child: Text(l10n.housingRealizedExpenseResubmit),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
