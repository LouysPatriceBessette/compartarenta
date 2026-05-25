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
import 'housing_realized_expense_form_screen.dart';

class _ReviewContext {
  const _ReviewContext({
    required this.expense,
    required this.lineTitle,
    required this.payerName,
    required this.beneficiaryName,
    required this.visibility,
    required this.prefs,
    required this.rejections,
  });

  final RealizedExpense expense;
  final String lineTitle;
  final String payerName;
  final String? beneficiaryName;
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

    return _ReviewContext(
      expense: expense,
      lineTitle: lineTitle,
      payerName: payerName,
      beneficiaryName: beneficiaryName,
      visibility: visibility,
      prefs: prefs,
      rejections: rejections,
    );
  }

  Future<void> _accept(_ReviewContext ctx) async {
    final selfId = selfParticipantIdForPlan(widget.planId);
    await _repo.recordLocalAccept(
      expenseId: widget.expenseId,
      participantId: selfId,
    );
    final orch = HandshakeOrchestrator.maybeInstance;
    await orch?.sendRealizedExpenseAccept(
      expenseId: widget.expenseId,
      participantId: selfId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).housingRealizedExpenseAccepted),
      ),
    );
    _reload();
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
          final canReview = ctx.visibility ==
                  RealizedExpenseReviewVisibility.waitingForYou &&
              expense.payerParticipantId != selfId;
          final canResubmit = ctx.visibility ==
                  RealizedExpenseReviewVisibility.rejected &&
              expense.payerParticipantId == selfId;

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
              if (ctx.lineTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(ctx.lineTitle),
              ],
              const SizedBox(height: 4),
              Text(
                formatPreferenceDate(expense.paymentDate, dateFmt),
              ),
              const SizedBox(height: 4),
              Text(l10n.housingRealizedExpenseReviewPayer(ctx.payerName)),
              const SizedBox(height: 4),
              Text(_kindLabel(l10n, expense.kind)),
              if (ctx.beneficiaryName != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.housingRealizedExpenseTransferRecipientSummary(
                    ctx.beneficiaryName!,
                  ),
                ),
              ],
              if ((expense.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(expense.description!.trim()),
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
